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
import '../engine/stage/tile.dart';
import '../content/tiles.dart';
import '../hues.dart';
import 'exit_popup.dart';
import 'game_over_screen.dart';
import 'game_screen_interface.dart';
import 'hero_equipment_dialog.dart';
import 'item/equip_dialog.dart';
import 'input.dart';
import 'input_converter.dart';
import 'loop_input.dart';
import 'loop_reward_screen.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'panel/item_panel.dart';
import 'panel/panel.dart';
import 'panel/equipment_status_panel.dart';
import 'draw.dart';
import 'storage.dart';

/// Panel for displaying loop mode controls
class ControlsPanel extends Panel {
  ActionMapping actionMapping;
  final LoopManager loopManager;
  final Game game;
  
  ControlsPanel(this.actionMapping, this.loopManager, this.game);
  
  void updateActionMapping(ActionMapping newMapping) {
    actionMapping = newMapping;
  }
  
  @override
  void renderPanel(Terminal terminal) {
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height, label: "CONTROLS");
    terminal.writeAt(1, 1, "Movement:", ash);
    terminal.writeAt(1, 2, "Arrow Keys", lightWarmGray);
    // add a space 
    terminal.writeAt(1, 3, " ", ash);
    terminal.writeAt(1, 4, "Actions:", ash);
    terminal.writeAt(1, 5, "1: 🗡️ ${actionMapping.action1Label}", lightBlue);
    terminal.writeAt(1, 6, "2: ⚡ ${actionMapping.action2Label}", lima);
    terminal.writeAt(1, 7, "3: ❤️ ${actionMapping.action3Label}", pink);
  }
}

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
  late final EquipmentStatusPanel _equipmentPanel;
  final SmartCombat _smartCombat;
  late ActionMapping _actionMapping;
  final LoopManager _loopManager;
  ControlsPanel? _controlsPanel;
  int _pause = 0;
  HeroSave _previousSave;
  
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
        _previousSave = game.hero.save.clone(),
        _logPanel = LogPanel(game.log),
        itemPanel = ItemPanel(game) {
    
    // Initialize panels
    _sidebarPanel = SidebarPanel(this);
    _stagePanel = StagePanel(this);
    _equipmentPanel = EquipmentStatusPanel(game);
    _controlsPanel = ControlsPanel(ActionMapping.fromSmartCombat(_smartCombat), _loopManager, game);
    
    // Initialize dynamic action mapping
    _updateActionMapping();
    
    // Ensure screen is marked for initial rendering
    dirty();
  }
  
  /// Update action mapping with current game state
  void _updateActionMapping() {
    _actionMapping = ActionMapping.fromSmartCombat(_smartCombat);
    _controlsPanel?.updateActionMapping(_actionMapping);
    dirty();
  }

  /// Factory constructor creates a game for the current loop
  factory LoopGameScreen.create(Storage storage, Content content, HeroSave save, LoopManager loopManager) {
    var depth = loopManager.getCurrentDepth();
    print("LoopGameScreen.create: Creating game at depth $depth");

    // TODO: Re-enable loop item system once build issues are resolved
    // loopManager.setContent(content);
    // loopManager.applyLoopItems(save);
    loopManager.applyActiveRewards(save);

    // Get archetype metadata from loop manager
    var archetypeMetadata = loopManager.getArchetypeMetadata();
    
    var game = Game(content, depth, save, width: 60, height: 34, archetypeMetadata: archetypeMetadata);

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
        // TODO: Implement pause menu
        return true;

      case LoopInput.info:
        // Show/hide action mapping help - no longer needed since always visible
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
        // First try to interact with staircase if standing on one
        var portal = game.stage[game.hero.pos].portal;
        if (portal == TilePortals.exit) {
          // Trigger staircase interaction
          if (_loopManager != null) {
            _handleLoopExit();
          } else {
            ui.push(ExitPopup(_previousSave, game));
          }
          return true;
        }
        
        // Otherwise try primary action
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

      case LoopInput.equip:
        // First try to interact with staircase if standing on one
        var portal = game.stage[game.hero.pos].portal;
        if (portal == TilePortals.exit) {
          // Trigger staircase interaction
          if (_loopManager != null) {
            _handleLoopExit();
          } else {
            ui.push(ExitPopup(_previousSave, game));
          }
          return true;
        }
        
        // For now, just show a message that equipment is not available in loop mode
        game.log.message("Equipment management not available in loop mode.");
        dirty();
        return true;
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
      dirty(); // Ensure screen refreshes during pause countdown
      return;
    }

    var result = game.update();

    // Track moves for loop system
    if (result.madeProgress) {
      // Mark screen as dirty when game makes progress
      dirty();
      
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
    var rightWidth = 25;
    if (size.x > 160) {
      leftWidth = 29;
      rightWidth = 30;
    } else if (size.x > 150) {
      leftWidth = 25;
      rightWidth = 28;
    }
    var centerWidth = size.x - leftWidth - rightWidth;
    itemPanel.hide();
    
    // Left sidebar
    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));
    
    // Equipment panel at top right
    var equipmentHeight = 12;
    _equipmentPanel.show(Rect(size.x - rightWidth, 0, rightWidth, equipmentHeight));
    
    // Controls panel at bottom right
    var controlsHeight = 8;
    _controlsPanel?.show(Rect(size.x - rightWidth, size.y - controlsHeight, rightWidth, controlsHeight));
    
    // Log panel at top center
    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 8);
    _logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    
    // Stage panel in center, leaving space for controls
    _stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    terminal.clear();
    _stagePanel.render(terminal);
    _logPanel.render(terminal);
    _sidebarPanel.render(terminal);
    _equipmentPanel.render(terminal);
    itemPanel.render(terminal);
    _controlsPanel?.render(terminal);
    _renderMoveCounter(terminal);
    _renderLoopProgress(terminal);
  }
  void _renderMoveCounter(Terminal terminal) {
    var movesRemaining = LoopManager.movesPerLoop - _loopManager.moveCount;
    var text = "$movesRemaining";
    var leftWidth = 21;
    var rightWidth = 25;
    if (terminal.width > 160) {
      leftWidth = 29;
      rightWidth = 30;
    } else if (terminal.width > 150) {
      leftWidth = 25;
      rightWidth = 28;
    }
    var centerWidth = terminal.width - leftWidth - rightWidth;
    var x = leftWidth + (centerWidth - text.length) ~/ 2;
    var y = terminal.height - 2; // Move to bottom
    var color = ash;
    if (movesRemaining <= 10) {
      color = red;
    } else if (movesRemaining <= 20) {
      color = carrot;
    } else if (movesRemaining <= 30) {
      color = yellow;
    }
    terminal.writeAt(x - 1, y, "[", lightWarmGray, darkerCoolGray);
    terminal.writeAt(x, y, text, color, darkerCoolGray);
    terminal.writeAt(x + text.length, y, "]", lightWarmGray, darkerCoolGray);
  }
  void _renderLoopProgress(Terminal terminal) {
    var progress = _loopManager.moveCount / LoopManager.movesPerLoop;
    var barWidth = 20;
    var leftWidth = 21;
    var rightWidth = 25;
    if (terminal.width > 160) {
      leftWidth = 29;
      rightWidth = 30;
    } else if (terminal.width > 150) {
      leftWidth = 25;
      rightWidth = 28;
    }
    var centerWidth = terminal.width - leftWidth - rightWidth;
    var x = leftWidth + (centerWidth - barWidth) ~/ 2;
    var y = terminal.height - 1; // Move to bottom
    for (var i = 0; i < barWidth; i++) {
      terminal.writeAt(x + i, y, "▒", darkWarmGray, darkerCoolGray);
    }
    var fillWidth = (progress * barWidth).round();
    for (var i = 0; i < fillWidth; i++) {
      var color = lightBlue;
      if (progress > 0.8) color = carrot;
      if (progress > 0.9) color = red;
      terminal.writeAt(x + i, y, "█", color, darkerCoolGray);
    }
    var loopText = "L${_loopManager.currentLoop}";
    terminal.writeAt(x - loopText.length - 1, y, loopText, ash, darkerCoolGray);
  }

  void _handleLoopExit() {
    _previousSave = game.hero.save;
    _loopManager.reset();
    ui.goTo(GameOverScreen(_storage, _previousSave!, _previousSave!));
  }
}
