// lib/src/ui/loop_game_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine/core/game.dart';
import '../engine/core/content.dart';
import '../engine/core/actor.dart';
import '../engine/stage/stage.dart';
import '../engine/hero/hero.dart';
import '../engine/hero/hero_save.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/smart_combat.dart';
import '../engine/action/action_mapping.dart';
import '../engine/action/action.dart';
import '../engine/action/walk.dart';
import '../debug.dart';
// Direction is available from piecemeal package
import 'game_screen_interface.dart';
import 'input.dart';
import 'loop_input.dart';
import 'input_converter.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'panel/item_panel.dart';
import 'storage.dart';
import 'game_screen.dart';
import 'game_over_screen.dart';
import 'loop_reward_screen.dart';
import '../hues.dart';

// Color constants - using RGB format (r, g, b)
final Color darkerCoolGray = Color(0x33, 0x33, 0x33);
final Color darkWarmGray = Color(0x44, 0x44, 0x44);
final Color ash = Color(0x88, 0x88, 0x88);

/// Simplified game screen for roguelite loop mode
/// Focuses on fast, ADHD-friendly gameplay with minimal complexity
class LoopGameScreen extends Screen<Input> implements GameScreenInterface {
  @override
  late final StagePanel stagePanel;
  final LogPanel _logPanel;
  late final SidebarPanel _sidebarPanel;
  final SmartCombat _smartCombat;
  late ActionMapping _actionMapping;
  final LoopManager _loopManager;
  final Game game;
  final Storage storage;
  
  bool _dirty = true;
  bool _showActionHelp = false;
  int _pause = 0;
  
  @override
  Screen<Input>? get screen => this;
  
  @override
  LoopManager? get loopManager => _loopManager;

  @override
  Rect get cameraBounds => Rect(0, 0, 80, 50);

  @override
  Color get heroColor => red;

  @override
  Actor? get currentTargetActor => null; // No target selection in loop mode

  @override
  Stream<Input> get input => _inputController.stream;

  final _inputController = StreamController<Input>();

  @override
  void dirty() => _dirty = true;

  @override
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    stagePanel.drawStageGlyph(terminal, x, y, glyph);
  }

  LoopGameScreen(this.game, this.storage, {required HeroSave heroSave})
      : _loopManager = LoopManager(),
        _smartCombat = SmartCombat(game),
        _logPanel = LogPanel(game.log) {
    
    // Initialize dynamic action mapping
    _updateActionMapping();
    
    // Initialize sidebar panel after constructor
    _sidebarPanel = SidebarPanel(this);
    
    // Initialize stage panel with a minimal GameScreen instance
    stagePanel = StagePanel(GameScreen(storage, game));
    
    // Bind debug screen (important for UI framework)
    Debug.bindGameScreen(this);
    
    // Initialize game state
    _dirty = true;
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

    var game = Game(content, depth, save, width: 60, height: 34);

    // Generate the dungeon
    for (var _ in game.generate()) {}

    return LoopGameScreen(game, storage, heroSave: save);
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
    print("LoopGameScreen.update() called");
    
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
          storage.save();
          ui.goTo(LoopRewardScreen(game.content, storage, _loopManager, game.hero.save));
          return;
        }
      }
    }

    // Check if hero died
    if (!game.hero.isAlive) {
      print("Hero died! Restarting loop.");
      _loopManager.reset();
      ui.goTo(GameOverScreen(storage, game.hero.save, game.hero.save));
      return;
    }

    // Update panels - exactly like the regular GameScreen
    if (stagePanel.update(result.events)) dirty();
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

    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));

    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 8); // Smaller log for more focus

    _logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    print("LoopGameScreen.render() called");
    
    // Clear the terminal first
    terminal.clear();
    
    // Draw the stage
    stagePanel.render(terminal);

    // Draw UI elements
    final rightSide = terminal.width - 24;
    final bottom = terminal.height - 2;

    // Draw health bar
    terminal.writeAt(
        rightSide,
        0,
        'Health: ${game.hero.health}/${game.hero.maxHealth}'.padLeft(20),
        red);

    // Draw gold
    terminal.writeAt(rightSide, 1, 'Gold: ${game.hero.gold}'.padLeft(20), peaGreen);

    // Draw current floor
    terminal.writeAt(
        rightSide, 2, 'Floor: ${game.depth}'.padLeft(20), lightBlue);

    // Draw loop count
    terminal.writeAt(
        rightSide, 3, 'Loop: ${_loopManager.currentLoop}'.padLeft(20), pink);

    // Draw action buttons with emojis for clarity
    terminal.writeAt(rightSide, 5, 'Actions:', ash);
    terminal.writeAt(rightSide, 6, '1. 🗡️ ${_actionMapping.action1Label}');
    terminal.writeAt(rightSide, 7, '2. ⚡ ${_actionMapping.action2Label}');
    terminal.writeAt(rightSide, 8, '3. ❤️ ${_actionMapping.action3Label}');

    // Draw log messages - using a fixed rectangle for now
    _logPanel.render(terminal);

    // Always show prominent move counter
    _renderMoveCounter(terminal);

    // Show loop progress indicator
    _renderLoopProgress(terminal);

    // Show action help if toggled
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
  
  /// Render prominent move counter in top-right corner
  void _renderMoveCounter(Terminal terminal) {
    var movesRemaining = LoopManager.movesPerLoop - _loopManager.moveCount;
    var text = "$movesRemaining";
    var x = terminal.width - text.length - 2;
    var y = 1;
    
    // Color based on urgency
    var color = ash;
    if (movesRemaining <= 10) {
      color = red;
    } else if (movesRemaining <= 20) {
      color = carrot;
    } else if (movesRemaining <= 30) {
      color = yellow;
    }
    
    // Background for visibility
    terminal.writeAt(x - 1, y, "[", lightWarmGray, darkerCoolGray);
    terminal.writeAt(x, y, text, color, darkerCoolGray);
    terminal.writeAt(x + text.length, y, "]", lightWarmGray, darkerCoolGray);
  }
  
  /// Render loop progress bar
  void _renderLoopProgress(Terminal terminal) {
    var progress = _loopManager.moveCount / LoopManager.movesPerLoop;
    var barWidth = 20;
    var x = terminal.width - barWidth - 5;
    var y = 2;
    
    // Progress bar background
    for (var i = 0; i < barWidth; i++) {
      terminal.writeAt(x + i, y, "▒", darkWarmGray, darkerCoolGray);
    }
    
    // Progress bar fill
    var fillWidth = (progress * barWidth).round();
    for (var i = 0; i < fillWidth; i++) {
      var color = lightBlue;
      if (progress > 0.8) color = carrot;
      if (progress > 0.9) color = red;
      
      terminal.writeAt(x + i, y, "█", color, darkerCoolGray);
    }
    
    // Loop number label
    var loopText = "L${_loopManager.currentLoop}";
    terminal.writeAt(x - loopText.length - 1, y, loopText, ash, darkerCoolGray);
  }
}
