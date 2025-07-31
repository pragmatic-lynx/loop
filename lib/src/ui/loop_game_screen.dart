// lib/src/ui/loop_game_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine/core/game.dart';
import '../engine/core/stage.dart';
import '../engine/hero/hero.dart';
import '../engine/hero/hero_save.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/smart_combat.dart';
import '../engine/action/action_mapping.dart';
import 'game_screen_interface.dart';
import 'input.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'panel/item_panel.dart';
import 'storage.dart';

// Color constants
const Color darkerCoolGray = Color(0xFF333333);
const Color darkWarmGray = Color(0xFF444444);
const Color ash = Color(0xFF888888);

/// Simplified game screen for roguelite loop mode
/// Focuses on fast, ADHD-friendly gameplay with minimal complexity
class LoopGameScreen extends Screen<Input> implements GameScreenInterface {
  @override
  late final StagePanel stagePanel;
  final LogPanel _logPanel;
  final SidebarPanel _sidebarPanel;
  final SmartCombat _smartCombat;
  final ActionMapping _actionMapping;
  final LoopManager _loopManager;
  final Game _game;
  bool _dirty = true;
  
  @override
  Screen<Input>? get screen => this;
  
  @override
  LoopManager? get loopManager => _loopManager;
  
  @override
  Game get game => _game;
  @override
  final Game game;
  @override
  final Storage storage;
  final LoopManager loopManager;
  final SmartCombat smartCombat;
  final ActionMapping actionMapping;
  final _inputController = StreamController<Input>();
  final ItemPanel itemPanel;
  late final SidebarPanel _sidebarPanel;
  final SmartCombat _smartCombat;

  /// Current action button mappings
  late final ActionMapping _actionMapping;

  bool _dirty = true;
  bool _showActionHelp = false;
  int _pause = 0;

  @override
  Rect get cameraBounds => Rect(0, 0, 80, 50);

  @override
  Color get heroColor => Color.red;

  @override
  Actor? get currentTargetActor => null; // No target selection in loop mode

  @override
  Stream<Input> get input => _inputController.stream;

  @override
  void dirty() => _dirty = true;

  @override
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph) {
    stagePanel.drawStageGlyph(terminal, x, y, glyph);
  }

  LoopGameScreen(Game game, {required HeroSave heroSave})
      : _game = game,
        _loopManager = LoopManager(heroSave),
        _smartCombat = SmartCombat(),
        _actionMapping = ActionMapping(
          action1Label: 'Attack',
          action2Label: 'Cast',
          action3Label: 'Heal',
          action4Label: 'Escape',
        ),
        _logPanel = LogPanel(),
        _sidebarPanel = SidebarPanel() {
    stagePanel = StagePanel(GameScreen(game));
    // Initialize other panels and state

    // Initialize panels
    _sidebarPanel = SidebarPanel(this);

    // Create a minimal GameScreen for the stage panel
    // We need to cast this to GameScreenInterface since StagePanel expects a GameScreen
    // but we can't extend GameScreen due to the constructor requirements
    stagePanel = StagePanel(this as GameScreen);
  }

  /// Factory constructor creates a game for the current loop
  factory LoopGameScreen.create(Storage storage, Content content, HeroSave save, LoopManager loopManager) {
    var depth = loopManager.getCurrentDepth();
    print("LoopGameScreen.create: Creating game at depth $depth");

    var game = Game(content, depth, save, width: 60, height: 34);

    // Generate the dungeon
    for (var _ in game.generate()) {}

    return LoopGameScreen(game, storage, loopManager: loopManager);
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
        loopManager.recordMove();

        // Check if time for reward selection
        if (loopManager.isRewardSelection) {
          print("Loop complete! Going to reward selection.");
          storage.save();
          ui.goTo(LoopRewardScreen(game.content, storage, loopManager, game.hero.save));
          return;
        }
      }
    }

    // Check if hero died
    if (!game.hero.isAlive) {
      print("Hero died! Restarting loop.");
      loopManager.reset();
      ui.goTo(GameOverScreen(storage, game.hero.save, game.hero.save));
      return;
    }

    // Update panels
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

    // Hide item panel in loop mode to reduce clutter
    itemPanel.hide();

    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));

    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 8); // Smaller log for more focus

    logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    // Draw the stage
    stagePanel.render(terminal);

    // Draw UI elements
    final rightSide = terminal.width - 24;
    final bottom = terminal.height - 2;

    // Draw health bar
    terminal.writeAt(
        rightSide,
        0,
        'Health: ${game.hero.health.current}/${game.hero.maxHealth}'.padLeft(20),
        Color.red);

    // Draw gold
    terminal.writeAt(rightSide, 1, 'Gold: ${game.hero.gold}'.padLeft(20), Color.green);

    // Draw current floor
    terminal.writeAt(
        rightSide, 2, 'Floor: ${game.stage.depth}'.padLeft(20), Color.lightBlue);

    // Draw loop count
    terminal.writeAt(
        rightSide, 3, 'Loop: ${loopManager.loopCount}'.padLeft(20), Color.pink);

    // Draw action buttons
    terminal.writeAt(rightSide, 5, 'Actions:', Color.gray);
    terminal.writeAt(rightSide, 6, '1. ${_actionMapping.action1Label}');
    terminal.writeAt(rightSide, 7, '2. ${_actionMapping.action2Label}');
    terminal.writeAt(rightSide, 8, '3. ${_actionMapping.action3Label}');
    terminal.writeAt(rightSide, 9, '4. ${_actionMapping.action4Label}');

    // Draw log messages - using a fixed rectangle for now
    _logPanel.render(terminal.getBounds().inflate(-24, -11, 0, -20));

    // Always show prominent move counter
    _renderMoveCounter(terminal);

    // Show loop progress indicator
    _renderLoopProgress(terminal);

    // Show action help if toggled
    if (_showActionHelp) {
      _renderActionHelp(terminal);
    }

    // Mark as clean after rendering
    _dirty = false;
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
    terminal.writeAt(x + 2, y + 4, "1: ${actionMapping.action1Label}", lightBlue, darkWarmGray);
    terminal.writeAt(x + 2, y + 5, "2: ${actionMapping.action2Label}", lima, darkWarmGray);
    terminal.writeAt(x + 2, y + 6, "3: ${actionMapping.action3Label}", pink, darkWarmGray);
    terminal.writeAt(x + 2, y + 7, "4: ${actionMapping.action4Label}", yellow, darkWarmGray);

    terminal.writeAt(x + 2, y + 9, "TAB: Toggle this help", lightWarmGray, darkWarmGray);
    terminal.writeAt(x + 2, y + 10, "ESC: Pause", lightWarmGray, darkWarmGray);

    // Current loop info in help
    var movesRemaining = LoopManager.movesPerLoop - loopManager.moveCount;
    terminal.writeAt(x + 2, y + height - 2, "Loop ${loopManager.currentLoop}: $movesRemaining moves left", carrot, darkWarmGray);
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
