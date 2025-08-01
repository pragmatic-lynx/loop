// lib/src/ui/loop_game_screen.dart

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine/action/action.dart';
import '../engine/action/action_mapping.dart';
import '../engine/action/walk.dart';
import '../engine/core/actor.dart';
import '../engine/core/content.dart';
import '../engine/core/game.dart';
import '../engine/hero/hero_save.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/smart_combat.dart';
import '../hues.dart';
import 'game_over_screen.dart';
import 'game_screen_interface.dart';
import 'input.dart';
import 'input_converter.dart';
import 'loop_input.dart';
import 'loop_reward_screen.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'panel/item_panel.dart';
import 'storage.dart';

// Color constants for help overlay
final Color darkerCoolGray = Color(0x33, 0x33, 0x33);
final Color darkWarmGray = Color(0x44, 0x44, 0x44);

/// Simplified game screen for roguelite loop mode
/// Focuses on fast, ADHD-friendly gameplay with minimal complexity
class LoopGameScreen extends Screen<Input> implements GameScreenInterface {
  @override
  final Game game;
  final Storage _storage;
  final LogPanel _logPanel;
  final ItemPanel itemPanel;
  late final SidebarPanel _sidebarPanel;
  late final StagePanel _stagePanel;
  final SmartCombat _smartCombat;
  late ActionMapping _actionMapping;
  final LoopManager _loopManager;
  
  bool _showActionHelp = false;
  int _pause = 0;
  
  @override
  LoopManager? get loopManager => _loopManager;
  @override
  StagePanel get stagePanel => _stagePanel;
  @override
  Storage get storage => _storage;
  @override
  Screen<Input>? get screen => this;
  
  @override
  Rect get cameraBounds => _stagePanel.cameraBounds;
  
  @override
  Color get heroColor {
    var hero = game.hero;
    if (hero.health < hero.maxHealth / 4) return red;
    if (hero.poison.isActive) return peaGreen;
    if (hero.cold.isActive) return lightBlue;
    if (hero.health < hero.maxHealth / 2) return pink;
    return ash;
  }
  
  /// Draws [Glyph] at [x], [y] in [Stage] coordinates onto the stage panel.
  @override
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    _stagePanel.drawStageGlyph(terminal, x, y, glyph);
  }

  @override
  Actor? get currentTargetActor => null; // No target selection in loop mode

  LoopGameScreen(this._storage, this.game, this._loopManager)
      : _smartCombat = SmartCombat(game),
        _logPanel = LogPanel(game.log),
        itemPanel = ItemPanel(game) {
    
    // Initialize panels
    _sidebarPanel = SidebarPanel(this);
    _stagePanel = StagePanel(this);
    
    // Initialize dynamic action mapping
    _updateActionMapping();
  }
  
  /// Update action mapping with current game state
  void _updateActionMapping() {
    _actionMapping = ActionMapping.fromSmartCombat(_smartCombat);
    dirty();
  }

  /// Factory constructor creates a game for the current loop
  factory LoopGameScreen.create(Storage storage, Content content, HeroSave save, LoopManager loopManager) {
    var depth = loopManager.getCurrentDepth();
    print("LoopGameScreen.create: Creating game at depth $depth");

    // Set up content for item management
    loopManager.setContent(content);
    
    // Apply loop-based items to hero before creating game
    loopManager.applyLoopItems(save);
    loopManager.applyActiveRewards(save);

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
    }

    if (action != null) {
      game.hero.setNextAction(action);
      
      // Mark screen as dirty to trigger redraw
      dirty();
      
      // Update action mapping after each action (abilities may change)
      _updateActionMapping();
    }

    return true;
  }

  @override
  void activate(Screen popped, Object? result) {
    if (!game.hero.needsInput(game)) {
      _pause = 5; // Brief pause for visual feedback
    }

    // Update action mapping when returning to screen
    _updateActionMapping();
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

    // Update panels - exactly like the regular GameScreen
    if (_stagePanel.update(result.events)) dirty();
    if (result.needsRefresh) dirty();
  }

  @override
  void resize(Vec size) {
    var leftWidth = 21;

    if (size.x > 160) {
      leftWidth = 29;
    } else if (size.x > 150) {
      leftWidth = 25;
    }

    var centerWidth = size.x - leftWidth;

    // Hide item panel in loop mode for simplicity
    itemPanel.hide();
    
    // Set up panel bounds exactly like the working GameScreen
    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));

    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 8); // Smaller log for more focus

    _logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    _stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    // Clear the terminal first
    terminal.clear();
    
    // Render panels in the same order as working GameScreen
    _stagePanel.render(terminal);
    _logPanel.render(terminal);
    // Note: render sidebar after stage panel so visible monsters are calculated first
    _sidebarPanel.render(terminal);
    itemPanel.render(terminal);

    // Show action help overlay if toggled
    if (_showActionHelp) {
      _renderActionHelp(terminal);
    }
  }

  /// Render the action button help overlay
  void _renderActionHelp(Terminal terminal) {
    var width = 30;
    var height = 12;
    var x = (terminal.width - width) ~/ 2;
    var y = (terminal.height - height) ~/ 2;

    // Draw background
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        terminal.writeAt(x + dx, y + dy, " ", darkerCoolGray, darkWarmGray);
      }
    }

    // Border
    terminal.writeAt(x, y, "╔", ash, darkWarmGray);
    terminal.writeAt(x + width - 1, y, "╗", ash, darkWarmGray);
    terminal.writeAt(x, y + height - 1, "╚", ash, darkWarmGray);
    terminal.writeAt(x + width - 1, y + height - 1, "╝", ash, darkWarmGray);

    for (var dx = 1; dx < width - 1; dx++) {
      terminal.writeAt(x + dx, y, "═", ash, darkWarmGray);
      terminal.writeAt(x + dx, y + height - 1, "═", ash, darkWarmGray);
    }

    for (var dy = 1; dy < height - 1; dy++) {
      terminal.writeAt(x, y + dy, "║", ash, darkWarmGray);
      terminal.writeAt(x + width - 1, y + dy, "║", ash, darkWarmGray);
    }

    // Title
    terminal.writeAt(x + 2, y + 1, "LOOP MODE CONTROLS", gold, darkWarmGray);

    // Controls
    terminal.writeAt(x + 2, y + 3, "Arrow Keys/WASD: Move", ash, darkWarmGray);
    terminal.writeAt(x + 2, y + 4, "1: 🗡️ ${_actionMapping.action1Label}", lightBlue, darkWarmGray);
    terminal.writeAt(x + 2, y + 5, "2: ⚡ ${_actionMapping.action2Label}", lima, darkWarmGray);
    terminal.writeAt(x + 2, y + 6, "3: ❤️ ${_actionMapping.action3Label}", pink, darkWarmGray);

    terminal.writeAt(x + 2, y + 9, "TAB: Toggle this help", lightWarmGray, darkWarmGray);
    terminal.writeAt(x + 2, y + 10, "ESC: Pause", lightWarmGray, darkWarmGray);

    // Current loop info in help
    var movesRemaining = LoopManager.movesPerLoop - _loopManager.moveCount;
    terminal.writeAt(x + 2, y + height - 2, "Loop ${_loopManager.currentLoop}: $movesRemaining moves left", carrot, darkWarmGray);
  }
}
