// lib/src/ui/loop_game_screen.dart

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/smart_combat.dart';
import '../hues.dart';
import 'loop_input.dart';
import 'input.dart';
import 'input_converter.dart';
import 'game_over_screen.dart';
import 'panel/item_panel.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'storage.dart';
import 'loop_reward_screen.dart';

/// Simplified game screen for roguelite loop mode
/// Focuses on fast, ADHD-friendly gameplay with minimal complexity
class LoopGameScreen extends Screen<Input> {
  final Game game;
  final Storage _storage;
  final LoopManager _loopManager;
  final SmartCombat _smartCombat;
  
  final LogPanel _logPanel;
  final ItemPanel itemPanel;
  late final SidebarPanel _sidebarPanel;
  late final StagePanel _stagePanel;

  /// Current action button mappings
  ActionMapping _actionMapping;
  
  /// UI display for showing current action mappings
  bool _showActionHelp = false;
  
  /// Pause counter for UI feedback
  int _pause = 0;

  StagePanel get stagePanel => _stagePanel;
  
  Rect get cameraBounds => _stagePanel.cameraBounds;

  Color get heroColor {
    var hero = game.hero;
    if (hero.health < hero.maxHealth / 4) return red;
    if (hero.poison.isActive) return peaGreen;
    if (hero.cold.isActive) return lightBlue;
    if (hero.health < hero.maxHealth / 2) return pink;
    return ash;
  }

  LoopGameScreen(this._storage, this.game, this._loopManager)
      : _smartCombat = SmartCombat(game),
        _logPanel = LogPanel(game.log),
        itemPanel = ItemPanel(game),
        _actionMapping = ActionMapping.fromHero(game.hero, game) {
    _sidebarPanel = SidebarPanel(this);
    _stagePanel = StagePanel(this);
  }

  /// Factory constructor creates a game for the current loop
  factory LoopGameScreen.create(Storage storage, Content content, 
      HeroSave save, LoopManager loopManager) {
    var depth = loopManager.getCurrentDepth();
    print("LoopGameScreen.create: Creating game at depth $depth");
    
    var game = Game(content, depth, save, width: 60, height: 34);
    
    // Generate the dungeon
    for (var _ in game.generate()) {}
    
    return LoopGameScreen(storage, game, loopManager);
  }

  @override
  bool handleInput(Input input) {
    // Convert standard input to loop input for simplified controls
    var loopInput = InputConverter.convertToLoopInput(input);
    if (loopInput == null) {
      // Ignore inputs that don't map to our simplified scheme
      return true;
    }
    
    return _handleLoopInput(loopInput);
  }
  
  /// Handle the simplified loop input
  bool _handleLoopInput(LoopInput input) {
    Action? action;
    
    switch (input) {
      case LoopInput.cancel:
        // Pause menu or forfeit
        _showActionHelp = !_showActionHelp;
        dirty();
        return true;
        
      case LoopInput.info:
        // Show/hide action mapping help
        _showActionHelp = !_showActionHelp;
        dirty();
        return true;
        
      // Movement inputs
      case LoopInput.n:
        action = WalkAction(Direction.n);
      case LoopInput.ne:
        action = WalkAction(Direction.ne);
      case LoopInput.e:
        action = WalkAction(Direction.e);
      case LoopInput.se:
        action = WalkAction(Direction.se);
      case LoopInput.s:
        action = WalkAction(Direction.s);
      case LoopInput.sw:
        action = WalkAction(Direction.sw);
      case LoopInput.w:
        action = WalkAction(Direction.w);
      case LoopInput.nw:
        action = WalkAction(Direction.nw);
      case LoopInput.wait:
        action = WalkAction(Direction.none);
        
      // Smart action buttons
      case LoopInput.action1:
        action = _smartCombat.handlePrimaryAction();
        if (action == null) {
          game.log.message("No primary action available.");
          dirty();
        }
        
      case LoopInput.action2:
        action = _smartCombat.handleSecondaryAction();
        if (action == null) {
          game.log.message("No secondary action available.");
          dirty();
        }
        
      case LoopInput.action3:
        action = _smartCombat.handleHealAction();
        if (action == null) {
          game.log.message("No healing available.");
          dirty();
        }
        
      case LoopInput.action4:
        action = _smartCombat.handleEscapeAction();
        if (action == null) {
          game.log.message("No escape action available.");
          dirty();
        }
    }

    if (action != null) {
      game.hero.setNextAction(action);
      
      // Update action mapping after each action (abilities may change)
      _actionMapping = ActionMapping.fromHero(game.hero, game);
    }

    return true;
  }
  
  /// Handle regular input when not in loop mode (for compatibility)
  bool handleRegularInput(Input input) {
    // This allows the screen to work with regular game controls if needed
    return handleInput(input);
  }

  @override
  void activate(Screen popped, Object? result) {
    if (!game.hero.needsInput(game)) {
      _pause = 5; // Brief pause for visual feedback
    }
    
    // Update action mapping when returning to screen
    _actionMapping = ActionMapping.fromHero(game.hero, game);
  }

  @override
  void update() {
    if (_pause > 0) {
      _pause--;
      return;
    }

    var result = game.update();

    // Track moves for loop system
    if (result.madeProgress) {
      // Check if hero took a turn
      if (game.hero.energy.canTakeTurn == false) {
        _loopManager.recordMove();
        
        // Check if time for reward selection
        if (_loopManager.isRewardSelection) {
          print("Loop complete! Going to reward selection.");
          _storage.save();
          ui.goTo(LoopRewardScreen(game.content, _storage, _loopManager, game.hero.save));
          return;
        }
      }
    }

    // Check if hero died
    if (!game.hero.isAlive) {
      print("Hero died! Restarting loop.");
      _loopManager.reset();
      ui.goTo(GameOverScreen(_storage, game.hero.save, game.hero.save));
      return;
    }

    // Update panels
    if (_stagePanel.update(result.events)) dirty();
    if (result.needsRefresh) dirty();
  }

  @override
  void resize(Vec size) {
    var leftWidth = 21;

    if (size > 160) {
      leftWidth = 29;
    } else if (size > 150) {
      leftWidth = 25;
    }

    var centerWidth = size.x - leftWidth;

    // Hide item panel in loop mode to reduce clutter
    itemPanel.hide();

    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));

    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 8); // Smaller log for more focus

    _logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    _stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();

    _stagePanel.render(terminal);
    _logPanel.render(terminal);
    _sidebarPanel.render(terminal);
    
    // Render action help overlay if active
    if (_showActionHelp) {
      _renderActionHelp(terminal);
    }
  }

  /// Render the action button help overlay
  void _renderActionHelp(Terminal terminal) {
    var width = 50;
    var height = 12;
    var x = (terminal.width - width) ~/ 2;
    var y = (terminal.height - height) ~/ 2;
    
    // Background
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        terminal.writeAt(x + dx, y + dy, " ", Color.black, Color.darkGray);
      }
    }
    
    // Border
    terminal.writeAt(x, y, "╔", Color.white, Color.darkGray);
    terminal.writeAt(x + width - 1, y, "╗", Color.white, Color.darkGray);
    terminal.writeAt(x, y + height - 1, "╚", Color.white, Color.darkGray);
    terminal.writeAt(x + width - 1, y + height - 1, "╝", Color.white, Color.darkGray);
    
    for (var dx = 1; dx < width - 1; dx++) {
      terminal.writeAt(x + dx, y, "═", Color.white, Color.darkGray);
      terminal.writeAt(x + dx, y + height - 1, "═", Color.white, Color.darkGray);
    }
    
    for (var dy = 1; dy < height - 1; dy++) {
      terminal.writeAt(x, y + dy, "║", Color.white, Color.darkGray);
      terminal.writeAt(x + width - 1, y + dy, "║", Color.white, Color.darkGray);
    }
    
    // Title
    terminal.writeAt(x + 2, y + 1, "LOOP MODE CONTROLS", Color.yellow, Color.darkGray);
    
    // Controls
    terminal.writeAt(x + 2, y + 3, "Arrow Keys/WASD: Move", Color.white, Color.darkGray);
    terminal.writeAt(x + 2, y + 4, "1: ${_actionMapping.action1Label}", Color.lightBlue, Color.darkGray);
    terminal.writeAt(x + 2, y + 5, "2: ${_actionMapping.action2Label}", Color.lightGreen, Color.darkGray);
    terminal.writeAt(x + 2, y + 6, "3: ${_actionMapping.action3Label}", Color.lightRed, Color.darkGray);
    terminal.writeAt(x + 2, y + 7, "4: ${_actionMapping.action4Label}", Color.lightYellow, Color.darkGray);
    
    terminal.writeAt(x + 2, y + 9, "TAB: Toggle this help", Color.gray, Color.darkGray);
    terminal.writeAt(x + 2, y + 10, "ESC: Pause", Color.gray, Color.darkGray);
    
    // Move count
    var movesRemaining = LoopManager.movesPerLoop - _loopManager.moveCount;
    terminal.writeAt(x + 2, y + height - 2, 
      "Moves Remaining: $movesRemaining", Color.orange, Color.darkGray);
  }

  /// Draws [Glyph] at [x], [y] in [Stage] coordinates onto the stage panel.
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    _stagePanel.drawStageGlyph(terminal, x, y, glyph);
  }
  
  /// Getter for loop manager (needed by sidebar panel)
  LoopManager? get loopManager => _loopManager;
}
