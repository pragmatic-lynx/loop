// lib/src/ui/loop_game_screen.dart

import 'dart:math' as math;

import 'dart:async';
import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../engine/action/action_mapping.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/smart_combat.dart';
import '../hues.dart';
import 'game_over_screen.dart';
import 'game_screen_interface.dart';
import 'input.dart';
import 'input_converter.dart';
import 'loop_input.dart';
import 'loop_reward_screen.dart';
import 'panel/item_panel.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'storage.dart';

/// Simplified game screen for roguelite loop mode
/// Focuses on fast, ADHD-friendly gameplay with minimal complexity
class LoopGameScreen extends Screen<Input> implements GameScreenInterface {
  @override
  final Game game;
  final Storage _storage;
  final LoopManager _loopManager;
  final StagePanel stagePanel;
  final LogPanel _logPanel;
  final ItemPanel itemPanel;
  late final SidebarPanel _sidebarPanel;
  final SmartCombat _smartCombat;
  
  /// Current action button mappings
  late final ActionMapping _actionMapping;
  
  bool _dirty = true;
  bool _showActionHelp = false;
  int _pause = 0;
  
  @override
  Storage get storage => _storage;
  
  @override
  Actor? get currentTargetActor => null; // Not used in loop mode
  
  @override
  Screen<Input>? get screen => this;
  
  @override
  void dirty() => _dirty = true;
  
  @override
  Object? get loopManager => _loopManager;
  
  @override
  Rect get cameraBounds => stagePanel.cameraBounds;
  
  @override
  Color get heroColor {
    final hero = game.hero;
    if (hero.health < hero.maxHealth / 4) return red;
    if (hero.poison.isActive) return peaGreen;
    if (hero.cold.isActive) return lightBlue;
    if (hero.health < hero.maxHealth / 2) return pink;
    return ash;
  }
  
  @override
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    stagePanel.drawGlyph(terminal, x, y, glyph);
  }
  
  /// UI display for showing current action mappings
  bool _showActionHelp = false;
  
  /// Pause counter for UI feedback
  int _pause = 0;

  LoopGameScreen(this.game, this._storage, this._loopManager)
      : _smartCombat = SmartCombat(game),
        _logPanel = LogPanel(game.log),
        itemPanel = ItemPanel(game),
        stagePanel = StagePanel(game) {
    // Initialize game screen
    game.hero.onGainHear.listen((_) => dirty());
    game.hero.onGainMaxHear.listen((_) => dirty());
    game.hero.onGainExperience.listen((_) => dirty());
    game.hero.onGainLevel.listen((_) => dirty());
    game.hero.onGainGold.listen((_) => dirty());
    game.hero.onGainItems.listen((_) => dirty());
    game.hero.onLoseItems.listen((_) => dirty());
    game.hero.onEquip.listen((_) => dirty());
    game.hero.onUnequip.listen((_) => dirty());
  }

  /// Factory constructor creates a game for the current loop
  factory LoopGameScreen.create(Storage storage, Content content, 
      HeroSave save, LoopManager loopManager) {
    var depth = loopManager.getCurrentDepth();
    print("LoopGameScreen.create: Creating game at depth $depth");
    
    var game = Game(content, depth, save, width: 60, height: 34);
    
    // Generate the dungeon
    for (var _ in game.generate()) {}
    
    return LoopGameScreen(game, storage, loopManager);
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
    if (stagePanel.update(result.events)) dirty();
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
    stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    // Clear the terminal
    terminal.clear();
    
    // Render the stage and UI panels
    stagePanel.render(terminal);
    _logPanel.render(terminal);
    _sidebarPanel.render(terminal);
    
    // Mark as clean after rendering
    _dirty = false;
  }
  
  @override
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    // Delegate to stage panel's draw method
    stagePanel.drawGlyph(terminal, x, y, glyph);
  }

  /// Render the action button help overlay
  void _renderActionHelp(Terminal terminal) {
    // Draw a semi-transparent overlay
    terminal.withColor(black.withAlpha(192), () {
      for (var y = 0; y < terminal.height; y++) {
        for (var x = 0; x < terminal.width; x++) {
          terminal.writeAt(x, y, ' ');
        }
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
