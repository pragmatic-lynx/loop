// lib/src/ui/loop_game_screen.dart

import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';
import 'diagonal_input_handler.dart';

import '../engine/action/action.dart';
import '../engine/action/action_mapping.dart';
import '../engine/action/attack.dart';
import '../engine/action/item.dart';
import '../engine/action/toss.dart';
import '../engine/action/walk.dart';
import '../engine/core/combat.dart';
import '../engine/core/element.dart';
import '../engine/items/inventory.dart';
import '../engine/core/actor.dart';
import '../engine/core/constants.dart';
import '../engine/core/content.dart';
import '../engine/core/game.dart';
import '../engine/hero/hero.dart';
import '../engine/hero/hero_save.dart';
import '../engine/loop/level_archetype.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/action_queues.dart';
import '../engine/loop/debug_helper.dart';
import '../engine/loop/loop_reward.dart';
import '../engine/loop/loop_meter.dart';
import '../engine/loop/smart_combat.dart';
import '../engine/stage/tile.dart';
import '../content/tiles.dart';
import '../content/skill/skills.dart';
import '../hues.dart';
import '../debug.dart';
import 'exit_popup.dart';
import 'game_over_screen.dart';
import 'game_screen.dart';
import 'game_screen_interface.dart';
import 'hero_equipment_dialog.dart';
import 'item/equip_dialog.dart';
import 'input.dart';
import 'input_converter.dart';
import 'level_up_screen.dart';
import 'loop_input.dart';
import 'loop_reward_screen.dart';
import 'supply_case_screen.dart';
import '../engine/hero/stat.dart';
import 'panel/log_panel.dart';
import 'panel/sidebar_panel.dart';
import 'panel/stage_panel.dart';
import 'panel/item_panel.dart';
import 'panel/panel.dart';
import 'panel/equipment_status_panel.dart';
import 'draw.dart';
import 'storage.dart';
import 'tuning_overlay.dart';
import 'inventory_dialog.dart';
// import '../debug/manager/debug_overlay.dart';
// import '../debug/manager/debug_manager.dart';

/// Panel for displaying loop mode controls
class ControlsPanel extends Panel {
  ActionMapping actionMapping;
  final LoopGameScreen _gameScreen;
  
  ControlsPanel(this.actionMapping, this._gameScreen);
  
  void updateActionMapping(ActionMapping newMapping) {
    actionMapping = newMapping;
  }
  
  @override
  void renderPanel(Terminal terminal) {
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height, label: "CONTROLS");
    
    // Add more padding from edges - start at 3 instead of 1
    var x = 3;
    
    terminal.writeAt(x, 1, "Movement:", ash);
    terminal.writeAt(x, 2, "Arrow Keys", lightWarmGray);
    
    terminal.writeAt(x, 3, "Actions:", ash);
    terminal.writeAt(x, 4, "1: ${actionMapping.action1Label}", lightBlue);
    terminal.writeAt(x, 5, "2: ${actionMapping.action2Label}", lima);
    terminal.writeAt(x, 6, "3: ${actionMapping.action3Label}", pink);
    
    // Spell/Queue Management
    terminal.writeAt(x, 7, "Q: Cycle Spells", lightAqua);
    terminal.writeAt(x, 8, "TAB: Cycle Action 2/3", lightAqua);
    
    // Context-aware E action
    var eAction = _getEActionDescription();
    if (eAction.description.isNotEmpty) {
      terminal.writeAt(x, 9, "E: ${eAction.icon} ${eAction.description}", eAction.color);
    } else {
      terminal.writeAt(x, 9, "E: ${eAction.icon} Interact", eAction.color);
    }
    
    // Extra keys
    terminal.writeAt(x, 10, "ESC/I: Inventory", ash);
    
    // Extra blank line for spacing
    terminal.writeAt(x, 11, "", ash);
  }
  
  ({String icon, String description, Color color}) _getEActionDescription() {
    var game = _gameScreen.game;
    
    // Check if standing on exit stairs
    var portal = game.stage[game.hero.pos].portal;
    if (portal == TilePortals.exit) {
      if (_gameScreen._loopManager != null) {
        return (icon: "🚪", description: "Exit Floor", color: gold);
      } else {
        return (icon: "🚪", description: "Exit Dungeon", color: gold);
      }
    }
    
    // Check for items to pick up
    var items = game.stage.itemsAt(game.hero.pos);
    if (items.isNotEmpty) {
      var item = items.first;
      if (item.canEquip && (item.equipSlot == 'hand')) {
        return (icon: "⚔️", description: "Equip ${item.type.name}", color: lightBlue);
      } else {
        return (icon: "📦", description: "Pick up ${item.type.name}", color: tan);
      }
    }
    
    // Check if there are multiple items
    if (items.length > 1) {
      return (icon: "📦", description: "Pick up items (${items.length})", color: tan);
    }
    
    // Default action when nothing special is available
    return (icon: "🔧", description: "Interact", color: ash);
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
  final ActionQueues _actionQueues;
  late final SmartCombat _smartCombat;
  final DebugHelper _debugHelper;
  late ActionMapping _actionMapping;
  final LoopManager _loopManager;
  ControlsPanel? _controlsPanel;
  TuningOverlay? _tuningOverlay;
  bool _showTuningOverlay = false;
  // DebugOverlay? _debugOverlay;
  // bool _showDebugOverlay = false;
  int _pause = 0;
  HeroSave _previousSave;
  int _previousEnemyCount = 0;
  final DiagonalInputHandler _diagonalInput = DiagonalInputHandler();
  
  // Debouncing for E command to prevent double execution
  // Uses time-based debouncing (200ms) instead of boolean flag for more reliable prevention
  DateTime? _lastECommandTime;
  
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
      : _actionQueues = ActionQueues(game),
        _smartCombat = SmartCombat(game),
        _debugHelper = DebugHelper(game),
        _previousSave = game.hero.save.clone(),
        _logPanel = LogPanel(game.log),
        itemPanel = ItemPanel(game) {
    
    // Initialize panels
    _sidebarPanel = SidebarPanel(this);
    _stagePanel = StagePanel(this);
    _equipmentPanel = EquipmentStatusPanel(game);
    _controlsPanel = ControlsPanel(ActionMapping.fromQueues(_actionQueues), this);
    _tuningOverlay = TuningOverlay(_loopManager.scheduler);
    // _debugOverlay = DebugOverlay();
    
    // Initialize debug manager
    // DebugManager.initialize(game, game.content);
    
    // Initialize dynamic action mapping
    _updateActionMapping();
    
    // Initialize mage spells if hero is a mage
    if (game.hero.save.heroClass.name == "Mage") {
      _initializeMageSpells();
    }
    
    // Initialize enemy count for kill tracking
    _previousEnemyCount = game.stage.actors.where((actor) => actor != game.hero && actor.isAlive).length;
    
    // Ensure screen is marked for initial rendering
    dirty();
  }
  
  /// Update action mapping with current game state
  void _updateActionMapping() {
    _actionMapping = ActionMapping.fromQueues(_actionQueues);
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
    // First handle direction inputs that might be combined with Shift
    Vec? direction;
    bool isShiftInput = false;
    
    switch (input) {
      case Input.n: 
        direction = Vec(0, -1); 
        _diagonalInput.updateShift(false); // Reset shift for normal keys
        break;
      case Input.ne: 
        direction = Vec(1, -1); 
        _diagonalInput.updateShift(false);
        break;
      case Input.e: 
        direction = Vec(1, 0); 
        _diagonalInput.updateShift(false);
        break;
      case Input.se: 
        direction = Vec(1, 1); 
        _diagonalInput.updateShift(false);
        break;
      case Input.s: 
        direction = Vec(0, 1); 
        _diagonalInput.updateShift(false);
        break;
      case Input.sw: 
        direction = Vec(-1, 1); 
        _diagonalInput.updateShift(false);
        break;
      case Input.w: 
        direction = Vec(-1, 0); 
        _diagonalInput.updateShift(false);
        break;
      case Input.nw: 
        direction = Vec(-1, -1); 
        _diagonalInput.updateShift(false);
        break;
      case Input.runN: 
        _diagonalInput.updateShift(true);
        direction = Vec(0, -1);
        isShiftInput = true;
        break;
      case Input.runS: 
        _diagonalInput.updateShift(true);
        direction = Vec(0, 1);
        isShiftInput = true;
        break;
      case Input.runE: 
        _diagonalInput.updateShift(true);
        direction = Vec(1, 0);
        isShiftInput = true;
        break;
      case Input.runW: 
        _diagonalInput.updateShift(true);
        direction = Vec(-1, 0);
        isShiftInput = true;
        break;
      case Input.runNE:
        _diagonalInput.updateShift(true);
        direction = Vec(1, -1);
        isShiftInput = true;
        break;
      case Input.runNW:
        _diagonalInput.updateShift(true);
        direction = Vec(-1, -1);
        isShiftInput = true;
        break;
      case Input.runSE:
        _diagonalInput.updateShift(true);
        direction = Vec(1, 1);
        isShiftInput = true;
        break;
      case Input.runSW:
        _diagonalInput.updateShift(true);
        direction = Vec(-1, 1);
        isShiftInput = true;
        break;
      case Input.cancel:
        _diagonalInput.updateShift(false);
        break;
      default:
        break;
    }

    // Handle inventory dialog
    if (input == Input.inventory) {
      ui.push(InventoryDialog(game));
      return true;
    }
    
    // Handle F5 metrics capture
    if (input == Input.metricsCapture) {
      _captureMetrics();
      return true;
    }

    // Handle tuning overlay toggle (tilde key maps to cancel)
    if (input == Input.cancel) {
      _showTuningOverlay = !_showTuningOverlay;
      if (_showTuningOverlay) {
        _tuningOverlay?.show(Rect(0, 0, 0, 0)); // Will be properly sized in render
      } else {
        _tuningOverlay?.hide();
      }
      dirty();
      return true;
    }
    
    // Handle debug overlay toggle (Z key)
    // if (input == Input.debug) {
    //   _showDebugOverlay = !_showDebugOverlay;
    //   dirty();
    //   return true;
    // }

    // Handle debug overlay input when active
    // if (_showDebugOverlay && _debugOverlay != null) {
    //   var handled = false;
    //   
    //   // Arrow key handling for debug navigation
    //   if (input == Input.n) {
    //     handled = _debugOverlay!.handleInputString('ArrowUp');
    //   } else if (input == Input.s) {
    //     handled = _debugOverlay!.handleInputString('ArrowDown');
    //   } else if (input == Input.w) {
    //     handled = _debugOverlay!.handleInputString('ArrowLeft');
    //   } else if (input == Input.e) {
    //     handled = _debugOverlay!.handleInputString('ArrowRight');
    //   } else if (input == Input.ok) {
    //     handled = _debugOverlay!.handleInputString('Enter');
    //   }
    //   
    //   if (handled) {
    //     dirty();
    //     return true;
    //   }
    // }
    
    // Handle tuning overlay input when active
    if (_showTuningOverlay && _tuningOverlay != null) {
      var handled = false;
      
      // Arrow key handling for scalar adjustments
      if (input == Input.n) {
        handled = _tuningOverlay!.handleArrowKey('up');
      } else if (input == Input.s) {
        handled = _tuningOverlay!.handleArrowKey('down');
      } else if (input == Input.w) {
        handled = _tuningOverlay!.handleArrowKey('left');
      } else if (input == Input.e) {
        handled = _tuningOverlay!.handleArrowKey('right');
      } else if (input == Input.tab) {
        handled = _tuningOverlay!.handleTab();
      }
      
      if (handled) {
        dirty();
        return true;
      }
    }

    // Handle debug-only auto-level-up (Shift+Alt+L)
    if (input == Input.levelUp) {
      if (Debug.enabled) {
        _quickLevelUp();
      } else {
        game.log.message("Debug features are disabled.");
        dirty();
      }
      return true;
    }

    // Handle depth increment (L key)
    if (input == Input.incrementLoop) {
      _loopManager.threatLevel++;
      var newDepth = _loopManager.getCurrentDepth();
      game.log.message("Depth increased to $newDepth (Threat Level: ${_loopManager.threatLevel}).");
      dirty();
      return true;
    }

    if (direction != null) {
      developer.log('Processing direction input: $input -> $direction (isShiftInput: $isShiftInput)', 
          name: 'LoopGameScreen');
      
      // Use diagonal input handler only for Shift+direction inputs
      if (isShiftInput) {
        // Use diagonal input handler
        final moveDirection = _diagonalInput.handleDirection(direction);
        if (moveDirection != null) {
          // Convert direction back to input
          if (moveDirection.x > 0 && moveDirection.y < 0) {
            input = Input.ne;
            developer.log('Diagonal movement: Northeast', name: 'LoopGameScreen');
          } else if (moveDirection.x > 0 && moveDirection.y > 0) {
            input = Input.se;
            developer.log('Diagonal movement: Southeast', name: 'LoopGameScreen');
          } else if (moveDirection.x < 0 && moveDirection.y > 0) {
            input = Input.sw;
            developer.log('Diagonal movement: Southwest', name: 'LoopGameScreen');
          } else if (moveDirection.x < 0 && moveDirection.y < 0) {
            input = Input.nw;
            developer.log('Diagonal movement: Northwest', name: 'LoopGameScreen');
          } else if (moveDirection.x > 0) {
            input = Input.e;
            developer.log('Cardinal movement: East', name: 'LoopGameScreen');
          } else if (moveDirection.x < 0) {
            input = Input.w;
            developer.log('Cardinal movement: West', name: 'LoopGameScreen');
          } else if (moveDirection.y > 0) {
            input = Input.s;
            developer.log('Cardinal movement: South', name: 'LoopGameScreen');
          } else if (moveDirection.y < 0) {
            input = Input.n;
            developer.log('Cardinal movement: North', name: 'LoopGameScreen');
          }
        } else {
          // Wait for second direction
          developer.log('Waiting for second direction', name: 'LoopGameScreen');
          return true;
        }
      } else {
        // Normal movement - just proceed with the original input
      }
    }

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
        
        // Class-specific action: Rangers use bow, Mages use spells
        var heroClassName = game.hero.save.heroClass.name;
        if (heroClassName == "Ranger") {
          // Ranged attack - set queue context and handle
          _actionQueues.setCurrentQueue(1);
          action = _handleRangedAction();
          if (action == null) {
            game.log.message("No ranged weapon available.");
            dirty();
          }
        } else if (heroClassName == "Mage") {
          // Cast mage spell
          _actionQueues.setCurrentQueue(4);
          if (_actionQueues.castCurrentStealthSpell()) {
            // Spell was cast successfully, no action needed
            _updateActionMapping();
            return true;
          } else {
            game.log.message("No spell available.");
            dirty();
          }
        }

      case LoopInput.action2:
        // Magic - set queue context and handle
        _actionQueues.setCurrentQueue(2);
        action = _handleMagicAction();
        if (action == null) {
          game.log.message("No magic available.");
          dirty();
        }

      case LoopInput.action3:
        // Heal - set queue context and handle
        _actionQueues.setCurrentQueue(3);
        action = _handleHealAction();
        if (action == null) {
          game.log.message("No healing available.");
          dirty();
        }
        break;
        
      case LoopInput.cycleSpell:
        // Q cycles spells - works for all classes that have spells
        if (game.hero.save.heroClass.name == "Mage") {
          // For mages, cycle through mage spells
          _actionQueues.setCurrentQueue(4);
          _actionQueues.cycleCurrentQueue();
          _updateActionMapping();
          var currentSpell = _actionQueues.getResistanceQueueItem();
          game.log.message("Active spell: ${currentSpell.name}");
        } else {
          // For other classes, cycle active spell
          _cycleActiveSpell();
          _updateActionMapping();
        }
        return true;
        
      case LoopInput.cycleQueue:
        // Tab cycles between action2 and action3 specifically (silently)
        var currentQueue = _actionQueues.currentQueue;
        if (currentQueue == 2) {
          _actionQueues.setCurrentQueue(3);
        } else if (currentQueue == 3) {
          _actionQueues.setCurrentQueue(2);
        } else {
          // If we're on queue 1 or 4, default to queue 2 (Magic)
          _actionQueues.setCurrentQueue(2);
        }
        _updateActionMapping();
        return true;
        
      case LoopInput.giveConsumables:
        _debugHelper.giveAllConsumables();
        game.log.message("Debug: Gave one-time set of consumables");
        return true;
        
      case LoopInput.incrementMeter:
        if (_loopManager != null) {
          var newProgress = _loopManager!.loopMeter.addDebugProgress();
          game.log.message("Debug: Loop meter increased by 20% (now ${newProgress.toStringAsFixed(1)}%)");
        } else {
          game.log.message("Debug: Loop meter not available");
        }
        return true;
        
      // No debug functionality - intentionally left blank

      case LoopInput.equip:
        // Prevent double execution of E command with time-based debouncing
        var now = DateTime.now();
        if (_lastECommandTime != null && 
            now.difference(_lastECommandTime!).inMilliseconds < 200) {
          return true;
        }
        _lastECommandTime = now;
        
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
        
        // Check for items to pick up at current position
        var items = game.stage.itemsAt(game.hero.pos);
        if (items.isNotEmpty) {
          var item = items.first;
          
          // Special handling for weapons - replace current weapon
          if (item.canEquip && (item.equipSlot == 'hand')) {
            // This is a weapon, so replace current weapon
            var unequippedItems = game.hero.equipment.equip(item);
            game.stage.removeItem(item, game.hero.pos);
            
            // Drop any unequipped weapons on the ground
            for (var unequippedItem in unequippedItems) {
              game.stage.addItem(unequippedItem, game.hero.pos);
              game.log.message('Dropped ${unequippedItem.type.name}.');
            }
            
            game.hero.pickUp(game, item);
            game.log.message('Equipped ${item.type.name}.');
            _loopManager.recordLootPickup(); // Track loot pickup for loop meter
            var meterProgress = _loopManager.loopMeter.progress.toStringAsFixed(1);
            game.log.message("Loot collected! Loop meter: ${meterProgress}%");
            _updateActionMapping(); // Refresh controls when equipment changes
            return true;
          } else {
            // Regular item pickup
            var result = game.hero.inventory.tryAdd(item);
            if (result.added > 0) {
              game.log.message('Picked up ${item.clone(result.added)}.');
              
              if (result.remaining == 0) {
                game.stage.removeItem(item, game.hero.pos);
              }
              _updateActionMapping(); // Refresh controls when inventory changes
            } else {
              game.log.message('Your inventory is full.');
              return true;
            }
          }
        }
        
        // For now, just show a message that equipment is not available in loop mode
        game.log.message("Nothing to pick up or interact with.");
        dirty();
        return true;
    }

    if (action != null) {
      // Store current enemy count before action
      _previousEnemyCount = game.stage.actors.where((actor) => actor != game.hero && actor.isAlive).length;
      
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
    // Check if we're returning from SupplyCaseScreen
    if (popped is SupplyCaseScreen) {
      // Continue to the next loop after rewards
      _continueToNextLoop();
      return;
    }
    
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

    // Store hero position before update to track actual movement
    var heroPosBefore = game.hero.pos;
    var heroEnergyBefore = game.hero.energy.canTakeTurn;
    
    var result = game.update();

    // Track moves for loop system - only count actual hero movement
    if (result.madeProgress) {
      // Mark screen as dirty when game makes progress
      dirty();
      
      // Only record a move if:
      // 1. Hero was able to act before the update
      // 2. Hero can't take a turn now (meaning hero just acted)
      // 3. Hero actually moved to a different position
      var heroActedThisTurn = heroEnergyBefore && !game.hero.energy.canTakeTurn;
      var heroMoved = game.hero.pos != heroPosBefore;
      
      if (heroActedThisTurn && heroMoved) {
        _loopManager.recordMove();

        // Check if time for reward selection
        if (_loopManager.isRewardSelection) {
          print("Loop complete! Going to loop meter rewards.");
          _storage.save();
          _handleLoopComplete(); // Use new loop meter based rewards
          return;
        }
      }
    }

    // Check if hero died
    if (!game.hero.isAlive) {
      print("Hero died! Returning to main menu.");
      _loopManager.recordDeath();
      _loopManager.reset();
      
      // Go to game over screen, which should then return to main menu
      ui.goTo(GameOverScreen(_storage, game.hero.save, _previousSave, game.content));
      return;
    }

    // Track game events for loop meter progress
    _trackGameEvents(result);
    
    // Update panels - exactly like the regular GameScreen
    if (_stagePanel.update(result.events)) dirty();
    if (result.needsRefresh) {
      dirty();
      // Also refresh action mapping when game state changes significantly
      _updateActionMapping();
    }
    
    // Update action mapping periodically to catch inventory changes
    if (result.madeProgress) {
      _updateActionMapping();
    }
    
    // Force animation updates when loop meter is full (for pulsing effect)
    if (_loopManager.loopMeter.isFull) {
      dirty();
    }
  }

  @override
  void resize(Vec size) {
    var leftWidth = 21;
    var rightWidth = 30; // Increased from 25 to give more space
    if (size.x > 160) {
      leftWidth = 29;
      rightWidth = 35; // Increased from 30
    } else if (size.x > 150) {
      leftWidth = 25;
      rightWidth = 32; // Increased from 28
    }
    var centerWidth = size.x - leftWidth - rightWidth;
    itemPanel.hide();
    
    // Left sidebar
    _sidebarPanel.show(Rect(0, 0, leftWidth, size.y));
    
    // Equipment panel at top right
    var equipmentHeight = 12;
    _equipmentPanel.show(Rect(size.x - rightWidth, 0, rightWidth, equipmentHeight));
    
    // Controls panel at bottom right - add 2 pixel margin from right edge
    var controlsHeight = 12; // Increased from 10 to give more space
    _controlsPanel?.show(Rect(size.x - rightWidth - 2, size.y - controlsHeight, rightWidth + 2, controlsHeight));
    
    // Log panel at top center
    var logHeight = 3 + (size.y - 30) ~/ 2;
    logHeight = math.min(logHeight, 8);
    _logPanel.show(Rect(leftWidth, 0, centerWidth, logHeight));
    
    // Stage panel in center, leaving space for controls
    _stagePanel.show(Rect(leftWidth, logHeight, centerWidth, size.y - logHeight));
  }

  @override
  void render(Terminal terminal) {
    // Update the action mapping every frame for dynamic labels.
    _updateActionMapping();

    terminal.clear();
    _stagePanel.render(terminal);
    _logPanel.render(terminal);
    _sidebarPanel.render(terminal);
    _equipmentPanel.render(terminal);
    itemPanel.render(terminal);
    _controlsPanel?.render(terminal);
    _renderMoveCounter(terminal);
    _renderLoopProgress(terminal);
    _renderLoopMeter(terminal);
    
    // Render debug overlay on top if active
    // if (_showDebugOverlay && _debugOverlay != null) {
    //   _debugOverlay!.renderPanel(terminal);
    // }
    
    // Render tuning overlay on top if active
    if (_showTuningOverlay && _tuningOverlay != null) {
      _tuningOverlay!.render(terminal);
    }
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
    // Calculate remaining progress (countdown from 1.0 to 0.0)
    var remainingProgress = 1.0 - (_loopManager.moveCount / LoopManager.movesPerLoop);
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
    
    // Draw empty background
    for (var i = 0; i < barWidth; i++) {
      terminal.writeAt(x + i, y, "▒", darkWarmGray, darkerCoolGray);
    }
    
    // Draw remaining time (starts full, empties out)
    var fillWidth = (remainingProgress * barWidth).round();
    for (var i = 0; i < fillWidth; i++) {
      var color = lightBlue;
      // Color changes based on how little time is left
      if (remainingProgress < 0.2) color = red;      // < 20% remaining = red
      else if (remainingProgress < 0.3) color = carrot; // < 30% remaining = orange
      else if (remainingProgress < 0.5) color = yellow; // < 50% remaining = yellow
      terminal.writeAt(x + i, y, "█", color, darkerCoolGray);
    }
    var loopText = "L${_loopManager.currentLoop}";
    terminal.writeAt(x - loopText.length - 1, y, loopText, ash, darkerCoolGray);
    
    // Add archetype display
    _renderArchetypeInfo(terminal);
  }
  
  void _renderArchetypeInfo(Terminal terminal) {
    var metadata = _loopManager.getArchetypeMetadata();
    if (metadata == null) return;
    
    var leftWidth = 21;
    if (terminal.width > 160) {
      leftWidth = 29;
    } else if (terminal.width > 150) {
      leftWidth = 25;
    }
    
    var archetype = metadata.archetype;
    var archetypeText = archetype.name.toUpperCase();
    var color = _getArchetypeColor(archetype);
    
    // TODO decide if this even show
    // Display archetype in top-left corner of the stage area
    //terminal.writeAt(leftWidth + 1, 4, archetypeText, color, darkerCoolGray);
    
    // Display scalars if tuning overlay is not active (to avoid clutter)
    if (!_showTuningOverlay) {
      var scalars = metadata.scalars;
      var enemyText = "E:${(scalars.enemyMultiplier * 100).round()}%";
      var itemText = "I:${(scalars.itemMultiplier * 100).round()}%";
      // terminal.writeAt(leftWidth + 1, 5, enemyText, lightWarmGray, darkerCoolGray);
      // terminal.writeAt(leftWidth + 8, 5, itemText, lightWarmGray, darkerCoolGray);
    }
  }
  
  void _renderLoopMeter(Terminal terminal) {
    var loopMeter = _loopManager.loopMeter;
    var progress = loopMeter.progressRatio;
    
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
    
    // Position higher up to avoid covering movement bar
    var centerX = leftWidth + centerWidth ~/ 2;
    var y = terminal.height - 8; // Moved up more to avoid movement bar
    
    // Draw circular progress using ASCII characters
    // Create a 7x7 circle representation for better visibility
    var chars = _getCircularProgressChars(progress);
    var colors = _getCircularProgressColors(loopMeter);
    
    // Draw the 7x7 circular meter for better visibility
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 7; col++) {
        var index = row * 7 + col;
        if (index < chars.length) {
          terminal.writeAt(centerX - 3 + col, y + row, chars[index], colors[index], darkerCoolGray);
        }
      }
    }
    
    // Add percentage text above the circle, no tier name
    if (loopMeter.progress >= 1.0) {
      var percentText = "${loopMeter.progress.toInt()}%";
      terminal.writeAt(centerX - percentText.length ~/ 2, y - 2, percentText, 
          loopMeter.progress >= 100.0 ? gold : 
          loopMeter.progress >= 75.0 ? gold :
          loopMeter.progress >= 50.0 ? yellow :
          loopMeter.progress >= 25.0 ? lightBlue : ash, darkerCoolGray);
    }
    
    // Add "RING COMPLETE!" label above when full
    if (loopMeter.progress >= 100.0) {
      terminal.writeAt(centerX - 6, y - 3, "RING COMPLETE!", gold, darkerCoolGray);
    }
  }
  
  List<String> _getCircularProgressChars(double progress) {
    // Create a much more visible circular meter using a 7x7 grid
    var emptyChar = '○';
    var filledChar = '●';
    var centerChar = progress >= 1.0 ? '!' : ' '; // Exclamation when full!
    
    // 7x7 grid layout for better visibility
    var positions = [
      ' ', ' ', emptyChar, emptyChar, emptyChar, ' ', ' ',     // row 0
      ' ', emptyChar, ' ', ' ', ' ', emptyChar, ' ',          // row 1
      emptyChar, ' ', ' ', ' ', ' ', ' ', emptyChar,          // row 2
      emptyChar, ' ', ' ', centerChar, ' ', ' ', emptyChar,   // row 3 (middle)
      emptyChar, ' ', ' ', ' ', ' ', ' ', emptyChar,          // row 4
      ' ', emptyChar, ' ', ' ', ' ', emptyChar, ' ',          // row 5
      ' ', ' ', emptyChar, emptyChar, emptyChar, ' ', ' ',    // row 6
    ];
    
    // 20 positions around the circle for smoother progression
    var fillPositions = (progress * 20).round();
    
    // Proper clockwise order starting from 12 o'clock (top center)
    // Map to indices in the 7x7 grid (49 total positions)
    var clockOrder = [
      3,   // 12 o'clock (top center)
      4,   // 12:30
      5,   // 1:30
      12,  // 3 o'clock (right center)
      19,  // 4:30
      26,  // 6 o'clock (right bottom)
      33,  // 6 o'clock (bottom center)
      40,  // 7:30
      41,  // 7:30
      42,  // 9 o'clock (bottom center)
      43,  // 9:30
      44,  // 10:30
      37,  // continuing left
      30,  // left side
      23,  // left side
      16,  // left side
      9,   // left side upper
      8,   // 10:30
      7,   // 11 o'clock
      2,   // back toward 12 o'clock
    ];
    
    for (var i = 0; i < fillPositions && i < clockOrder.length; i++) {
      if (clockOrder[i] < positions.length) {
        positions[clockOrder[i]] = filledChar;
      }
    }
    
    return positions;
  }
  
  List<Color> _getCircularProgressColors(loopMeter) {
    var baseColor = ash; // Much lighter base color for better contrast
    var fillColor = lightBlue;
    var fullColor = gold;
    
    if (loopMeter.isEmpty) {
      fillColor = ash;
    } else if (loopMeter.progress >= 75.0) {
      fillColor = fullColor; // Gold for 75%+
    } else if (loopMeter.progress >= 50.0) {
      fillColor = yellow; // Yellow for 50%+
    } else if (loopMeter.progress >= 25.0) {
      fillColor = lightBlue; // Blue for 25%+
    } else {
      fillColor = lightWarmGray; // Light gray for low progress
    }
    
    // Pulsing effect when full
    if (loopMeter.isFull) {
      if ((DateTime.now().millisecondsSinceEpoch ~/ 300) % 2 == 0) {
        fillColor = boneWhite; // Bright white pulse when full
      }
    }
    
    var result = List<Color>.filled(49, baseColor); // 7x7 = 49 positions
    var progress = loopMeter.progressRatio;
    var fillPositions = (progress * 20).round(); // Match the 20 positions from chars method
    
    // Same clockwise order as chars method
    var clockOrder = [
      3,   // 12 o'clock (top center)
      4,   // 12:30
      5,   // 1:30
      12,  // 3 o'clock (right center)
      19,  // 4:30
      26,  // 6 o'clock (right bottom)
      33,  // 6 o'clock (bottom center)
      40,  // 7:30
      41,  // 7:30
      42,  // 9 o'clock (bottom center)
      43,  // 9:30
      44,  // 10:30
      37,  // continuing left
      30,  // left side
      23,  // left side
      16,  // left side
      9,   // left side upper
      8,   // 10:30
      7,   // 11 o'clock
      2,   // back toward 12 o'clock
    ];
    
    for (var i = 0; i < fillPositions && i < clockOrder.length; i++) {
      if (clockOrder[i] < result.length) {
        result[clockOrder[i]] = fillColor;
      }
    }
    
    // Special color for center when full
    if (loopMeter.isFull) {
      result[24] = gold; // Center position in 7x7 grid (3,3)
    }
    
    return result;
  }
  
  Color _getArchetypeColor(LevelArchetype archetype) {
    switch (archetype) {
      case LevelArchetype.combat:
        return red;
      case LevelArchetype.loot:
        return gold;
      case LevelArchetype.boss:
        return purple;
    }
  }

  /// Capture and log current metrics snapshot
  void _captureMetrics() {
    var snapshot = _loopManager.metricsCollector.createSnapshot(game, _loopManager.currentLoop);
    var jsonOutput = snapshot.toJson();
    
    // Log to game log for immediate visibility
    game.log.message("METRICS: $jsonOutput");
    
    // Also print to console for debugging
    print("Metrics Snapshot: $jsonOutput");
    
    // Mark screen as dirty to show the log message
    dirty();
  }

  void _handleLoopExit() {
    // Award XP bonus for descending stairs
    game.hero.gainExperience(GameConstants.stairXpBonus);
    
    // Check if we need to show level-up screen before proceeding
    if (game.hero.save.pendingLevels > 0) {
      // Show level-up screen, then continue to next level
      ui.push(LevelUpScreen(
        hero: game.hero.save,
        pendingLevels: game.hero.save.pendingLevels,
        storage: _storage,
      ));
      
      // Clear pending levels after showing screen
      game.hero.save.pendingLevels = 0;
    }
    
    // Continue to next level instead of ending the game
    _startNextLevel();
  }

  /// Start the next level after stairs or level completion
  void _startNextLevel() {
    // Increment the loop and continue
    _loopManager.selectReward(LoopReward.generateRewardOptions(1, _loopManager.currentLoop, game.content, game.hero.save.heroClass.name).first);
    
    // Create a new game for the next level
    var depth = _loopManager.getCurrentDepth();
    var newGame = GameScreen.loop(_storage, game.content, game.hero.save, _loopManager, depth);
    
    // Replace current screen with new game screen
    ui.goTo(LoopGameScreen.create(_storage, game.content, game.hero.save, _loopManager));
  }
  
  /// Handle ranged weapon action
  Action? _handleRangedAction() {
    var rangedItem = _actionQueues.getRangedQueueItem();
    
    // Debug: Show what we found
    // game.log.message("Debug: Ranged item: ${rangedItem.name}, available: ${rangedItem.isAvailable}");
    
    if (!rangedItem.isAvailable) {
      // Try to auto-equip a ranged weapon
      if (_actionQueues.autoEquipRangedWeapon()) {
        _updateActionMapping();
        rangedItem = _actionQueues.getRangedQueueItem();
        //game.log.message("Debug: After auto-equip: ${rangedItem.name}, available: ${rangedItem.isAvailable}");
      }
    }
    
    if (!rangedItem.isAvailable || rangedItem.item == null) {
      return null;
    }
    
    // Try to use the Archery skill if available
    var archerySkill = _findArcherySkill();
    if (archerySkill != null) {
      var target = _findRangedTarget();
      if (target == null) {
        game.log.message("No target in range.");
        return null;
      }
      
      // Use archery skill - even at level 0 for rangers with bows
      var level = game.hero.skills.level(archerySkill);
      var heroClassName = game.hero.save.heroClass.name;
      if (level > 0 || (heroClassName == "Ranger" && rangedItem.item!.type.name.toLowerCase().contains("bow"))) {
        // For rangers with bows, use archery skill even at level 0
        var effectiveLevel = level > 0 ? level : 1;
        // game.log.message("Debug: Using archery skill level $effectiveLevel");
        return archerySkill.onGetTargetAction(game, effectiveLevel, target.pos);
      }
    }
    
    // Fallback: try using the weapon as a tossable item
    var weapon = rangedItem.item!;
    if (weapon.canToss) {
      var target = _findRangedTarget();
      if (target == null) {
        game.log.message("No target in range.");
        return null;
      }
      
      // game.log.message("Debug: Tossing ${weapon.type.name} at target");
      // Create a hit for the toss action
      var hit = weapon.toss!.attack.createHit();
      return TossAction(ItemLocation.equipment, weapon, hit, target.pos);
    } else {
      // If we can't toss it, just do a regular attack (this might not work well)
      var target = _findRangedTarget();
      if (target == null) {
        game.log.message("No target in range.");
        return null;
      }
      
      //game.log.message("Debug: Melee attacking target with ${rangedItem.name}");
      return AttackAction(target);
    }
  }
  
  /// Handle magic item action
  Action? _handleMagicAction() {
    var magicItem = _actionQueues.getMagicQueueItem();
    if (!magicItem.isAvailable || magicItem.item == null) {
      return null;
    }
    
    var action = UseAction(ItemLocation.inventory, magicItem.item!);
    
    return action;
  }
  
  /// Handle spell casting action
  Action? _handleSpellCastAction() {
    var activeSpell = _smartCombat.activeSpell;
    if (activeSpell == null) {
      return null;
    }
    
    // Cast the spell
    var action = UseAction(ItemLocation.inventory, activeSpell);
    
    return action;
  }
  
  /// Cycle the active spell
  void _cycleActiveSpell() {
    _smartCombat.cycleActiveSpell();
    
    var newActiveSpell = _smartCombat.activeSpell;
    if (newActiveSpell != null) {
      game.log.message("Active spell: ${newActiveSpell.type.name}");
    } else {
      game.log.message("No spells available.");
    }
  }
  
  /// Initialize mage spells to ensure they can be cycled from the start
  void _initializeMageSpells() {
    var mageSpells = [
      "Icicle",
      "Brilliant Beam", 
      "Windstorm",
      "Fire Barrier",
      "Tidal Wave"
    ];
    
    for (var spellName in mageSpells) {
      try {
        var skill = Skills.find(spellName);
        // Ensure the spell is discovered for the mage
        if (!game.hero.skills.isDiscovered(skill)) {
          game.hero.skills.discover(skill);
        }
      } catch (e) {
        // Spell not found, skip it
        continue;
      }
    }
    
    // Set initial queue to mage spells
    _actionQueues.setCurrentQueue(4);
    _updateActionMapping();
  }
  
  /// Handle heal item action
  Action? _handleHealAction() {
    var healItem = _actionQueues.getHealQueueItem();
    if (!healItem.isAvailable || healItem.item == null) {
      return null;
    }
    
    // Always allow healing - even if it will overfill
    var action = UseAction(ItemLocation.inventory, healItem.item!);
    
    return action;
  }
  
  /// Find the archery skill
  dynamic _findArcherySkill() {
    try {
      for (var skill in game.content.skills) {
        if (skill.name.toLowerCase() == 'archery') {
          return skill;
        }
      }
    } catch (e) {
      // game.log.message('Debug: Error finding archery skill: $e');
    }
    return null;
  }
  
  /// Find target for ranged attack
  Actor? _findRangedTarget() {
    // Find nearest visible enemy
    Actor? nearest;
    var nearestDistance = 999;
    
    for (var actor in game.stage.actors) {
      if (actor == game.hero || !actor.isAlive) continue;
      if (!game.heroCanPerceive(actor)) continue;
      
      var distance = (actor.pos - game.hero.pos).rookLength;
      if (distance < nearestDistance) {
        nearest = actor;
        nearestDistance = distance;
      }
    }
    
    return nearest;
  }
  
  /// Quick level up for debug purposes (Shift+Alt+L)
  void _quickLevelUp() {
    if (game.hero.level == Hero.maxLevel) {
      game.log.message("Already at max level.");
    } else {
      game.hero.experience = experienceLevelCost(game.hero.level + 1);
      game.hero.refreshProperties();
      //game.log.message("Debug: Level up! You are now level ${game.hero.level}.");
    }
    dirty();
  }
  
  /// Track game events for loop meter progress
  void _trackGameEvents(GameResult result) {
    // Track enemy kills by checking if any actors died
    var currentEnemyCount = game.stage.actors.where((actor) => actor != game.hero && actor.isAlive).length;
    
    if (currentEnemyCount < _previousEnemyCount) {
      var killCount = _previousEnemyCount - currentEnemyCount;
      for (var i = 0; i < killCount; i++) {
        _loopManager.recordEnemyKill();
        // Force immediate UI update
        dirty();
      }
      
      // Show immediate feedback
      if (killCount > 0) {
        var meterProgress = _loopManager.loopMeter.progress.toStringAsFixed(1);
        game.log.message("Enemy defeated! Loop meter: ${meterProgress}%");
      }
    }
    
    _previousEnemyCount = currentEnemyCount;
    
    // Loot pickups are tracked in the handleLoopInput method when items are picked up
  }
  
  /// Handle loop completion based on loop meter state
  void _handleLoopComplete() {
    var loopMeter = _loopManager.loopMeter;
    var rewardTier = loopMeter.getRewardTier();
    var progress = loopMeter.progress;
    
    // Show the new supply case screen for all tiers
    ui.push(SupplyCaseScreen(game, game.content, rewardTier, progress, _loopManager.currentLoop, () {
      // Pop the supply case screen and return to this screen
      ui.pop();
    }));
  }
  
  /// Continue to the next loop after rewards
  void _continueToNextLoop() {
    // Reset the loop meter for the new loop (this will be done in LoopManager.selectReward)
    
    // Use the existing reward selection logic to continue
    _loopManager.selectReward(LoopReward.generateRewardOptions(1, _loopManager.currentLoop, game.content, game.hero.save.heroClass.name).first);
    
    // Create a new game for the next level
    var depth = _loopManager.getCurrentDepth();
    ui.goTo(LoopGameScreen.create(_storage, game.content, game.hero.save, _loopManager));
  }
}
