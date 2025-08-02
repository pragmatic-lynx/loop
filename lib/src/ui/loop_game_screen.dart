// lib/src/ui/loop_game_screen.dart

import 'dart:math' as math;

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine/action/action.dart';
import '../engine/action/action_mapping.dart';
import '../engine/action/attack.dart';
import '../engine/action/item.dart';
import '../engine/action/slam.dart';
import '../engine/action/movement.dart';
import '../engine/action/toss.dart';
import '../engine/action/walk.dart';
import '../engine/core/combat.dart';
import '../engine/core/element.dart';
import '../engine/items/inventory.dart';
import '../engine/items/item.dart';
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
import '../engine/loop/smart_combat.dart';
import '../engine/stage/tile.dart';
import '../content/tiles.dart';
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
    terminal.writeAt(1, 1, "Movement:", ash);
    terminal.writeAt(1, 2, "Arrow Keys", lightWarmGray);
    terminal.writeAt(1, 3, " ", ash);
    terminal.writeAt(1, 4, "Actions:", ash);
    
    // New control scheme
    terminal.writeAt(1, 5, "1: ${actionMapping.attackLabel}", lightBlue);
    terminal.writeAt(1, 6, "2: ${actionMapping.utilityLabel}", lima);
    terminal.writeAt(1, 7, "3: ${actionMapping.healLabel}", pink);
    
    // Movement and cycling
    var movementStatus = MovementAction.canUseMovement() ? "Ready" : "${MovementAction.remainingCooldown()} moves";
    terminal.writeAt(1, 8, "W: Movement ($movementStatus)", aqua);
    terminal.writeAt(1, 9, "Q: Cycle ${actionMapping.categoryLabel}", gold);
    
    // Context-aware E action
    var eAction = _getEActionDescription();
    terminal.writeAt(1, 10, "E: ${eAction.icon} ${eAction.description}", eAction.color);
    
    // Extra keys
    terminal.writeAt(1, 12, "I: Inventory", ash);
    terminal.writeAt(1, 13, "Tab: Cycle Categories", ash);
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
    
    // Default action when nothing special is available
    return (icon: "❌", description: "Nothing", color: ash);
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
    
    // Initialize dynamic action mapping
    _updateActionMapping();
    
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

      case LoopInput.inventory:
        // Show inventory
        ui.push(InventoryDialog(game));
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
      case LoopInput.nw:
        action = WalkAction(Direction.nw);
      case LoopInput.wait:
        action = WalkAction(Direction.none);

      // New control scheme
      case LoopInput.attack:
        action = _handleAttackAction();
        if (action == null) {
          game.log.message("Cannot attack.");
          dirty();
        }

      case LoopInput.utility:
        action = _handleUtilityAction();
        if (action == null) {
          game.log.message("No utility items available.");
          dirty();
        }

      case LoopInput.heal:
        action = _handleHealAction();
        if (action == null) {
          game.log.message("No healing available.");
          dirty();
        }
        
      case LoopInput.movement:
        action = MovementAction();
        if (action == null) {
          dirty();
        }
        
      case LoopInput.cycle:
        // Cycle through items within the current active category
        _actionQueues.cycleWithinCategory();
        _updateActionMapping();
        var categoryName = _actionQueues.getCategoryName();
        game.log.message("Cycling ${categoryName.toLowerCase()} items");
        return true;
        
      case LoopInput.cycleCategory:
        // Cycle between categories (spells/utility/healing)
        _actionQueues.cycleCategory();
        _updateActionMapping();
        game.log.message("Active category: ${_actionQueues.getCategoryName()}");
        return true;
        
      case LoopInput.debug:
        // Debug functionality - add random items
        _debugHelper.addRandomTestItems();
        _updateActionMapping();
        return true;

      case LoopInput.interact:
        return _handleInteractAction();
    }

    if (action != null) {
      game.hero.setNextAction(action);
      
      // Track movement for cooldown system
      if (action is WalkAction) {
        // Check if it's actual movement (not resting)
        var walkAction = action as WalkAction;
        // Use reflection or create a getter - for now, assume any WalkAction is movement
        _trackMovement();
      }
      
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
      _loopManager.recordDeath();
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
    
    // Controls panel at bottom right - increased height for new controls
    var controlsHeight = 14;
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
    _loopManager.selectReward(LoopReward.generateRewardOptions(1).first);
    
    // Create a new game for the next level
    var depth = _loopManager.getCurrentDepth();
    var newGame = GameScreen.loop(_storage, game.content, game.hero.save, _loopManager, depth);
    
    // Replace current screen with new game screen
    ui.goTo(LoopGameScreen.create(_storage, game.content, game.hero.save, _loopManager));
  }
  
  /// Handle context-aware attack action (button 1)
  Action? _handleAttackAction() {
    var hero = game.hero;
    
    // 1. If mage class -> prioritize spells (especially Windstorm)
    if (hero.save.heroClass.name.toLowerCase() == 'mage') {
      var spellItem = _getMageAttackSpell();
      if (spellItem != null) {
        return UseAction(ItemLocation.inventory, spellItem);
      }
    }
    
    // 2. If warrior class -> SlamAction (always available with cooldown)
    if (hero.save.heroClass.name.toLowerCase() == 'warrior') {
      if (SlamAction.canUseSlam()) {
        return SlamAction();
      } else {
        // Slam on cooldown, show message but still allow other attacks
        var remaining = SlamAction.remainingSlamCooldown();
        game.log.message("Slam ready in $remaining moves. Using regular attack.");
      }
    }
    
    // 3. If adjacent enemy -> MeleeAction
    var adjacentEnemy = _getAdjacentEnemy();
    if (adjacentEnemy != null) {
      return AttackAction(adjacentEnemy);
    }
    
    // 4. If bow equipped and line of sight -> BoltAction
    if (_hasBowEquipped() && _hasRangedTarget()) {
      var target = _findRangedTarget();
      if (target != null) {
        return _createBowAttack(target);
      }
    }
    
    // 5. If any spell equipped -> CastSpell (but not movement spells)
    var spellItem = _getFirstNonMovementSpell();
    if (spellItem != null) {
      return UseAction(ItemLocation.inventory, spellItem);
    }
    
    return null;
  }
  
  /// Check if hero has adjacent enemies
  bool _hasAdjacentEnemies() {
    for (var direction in Direction.all) {
      var pos = game.hero.pos + direction;
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor != game.hero && actor.isAlive) {
        return true;
      }
    }
    return false;
  }
  
  /// Get first adjacent enemy
  Actor? _getAdjacentEnemy() {
    for (var direction in Direction.all) {
      var pos = game.hero.pos + direction;
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor != game.hero && actor.isAlive) {
        return actor;
      }
    }
    return null;
  }
  
  /// Check if hero has bow equipped
  bool _hasBowEquipped() {
    for (var item in game.hero.equipment) {
      var name = item.type.name.toLowerCase();
      if (name.contains('bow') || name.contains('crossbow')) {
        return true;
      }
    }
    return false;
  }
  
  /// Check if there are ranged targets
  bool _hasRangedTarget() {
    return _findRangedTarget() != null;
  }
  
  /// Create bow attack action
  Action? _createBowAttack(Actor target) {
    // Find equipped bow
    for (var item in game.hero.equipment) {
      var name = item.type.name.toLowerCase();
      if (name.contains('bow') || name.contains('crossbow')) {
        // Don't toss the bow itself - it should fire arrows/bolts
        // Check if we have arrows in inventory for this bow
        var ammunition = _findAmmunition(item);
        if (ammunition != null) {
          // Fire ammunition from bow
          var hit = ammunition.toss!.attack.createHit();
          return TossAction(ItemLocation.inventory, ammunition, hit, target.pos);
        } else {
          // No ammunition, try using bow's own attack if it has one
          if (item.attack != null) {
            var hit = item.attack!.createHit();
            // This represents the bow firing (not being thrown)
            return TossAction(ItemLocation.equipment, item, hit, target.pos);
          }
        }
      }
    }
    return AttackAction(target); // Fallback to melee
  }
  
  /// Find ammunition for a bow in inventory
  Item? _findAmmunition(Item bow) {
    var bowName = bow.type.name.toLowerCase();
    
    for (var item in game.hero.inventory) {
      var itemName = item.type.name.toLowerCase();
      
      // Match arrows to bows, bolts to crossbows
      if (bowName.contains('bow') && !bowName.contains('cross') && itemName.contains('arrow')) {
        return item;
      }
      if (bowName.contains('crossbow') && itemName.contains('bolt')) {
        return item;
      }
    }
    return null;
  }
  
  /// Get priority attack spell for mages (prioritize Windstorm)
  Item? _getMageAttackSpell() {
    Item? windstorm;
    Item? otherSpell;
    
    for (var item in game.hero.inventory) {
      if (item.use != null) {
        var name = item.type.name.toLowerCase();
        
        // Exclude movement spells
        if (name.contains('flee') || name.contains('escape') || name.contains('disappear')) {
          continue;
        }
        
        // Exclude healing and utility spells
        if (name.contains('heal') || name.contains('cure') || name.contains('restore')) {
          continue;
        }
        
        // Prefer Windstorm
        if (name.contains('windstorm')) {
          windstorm = item;
        } else if (name.contains('scroll') || name.contains('bolt') || name.contains('fire') || name.contains('ice')) {
          otherSpell ??= item; // First offensive spell found
        }
      }
    }
    
    return windstorm ?? otherSpell;
  }
  
  /// Get first non-movement spell from inventory
  Item? _getFirstNonMovementSpell() {
    for (var item in game.hero.inventory) {
      if (item.use != null) {
        var name = item.type.name.toLowerCase();
        // Exclude movement spells
        if (!name.contains('flee') && !name.contains('escape') && !name.contains('disappear')) {
          return item;
        }
      }
    }
    return null;
  }
  
  /// Handle utility action (button 2) - changes based on active category
  Action? _handleUtilityAction() {
    var utilityItem = _actionQueues.getUtilityQueueItem();
    if (!utilityItem.isAvailable || utilityItem.item == null) {
      return null;
    }
    
    var action = UseAction(ItemLocation.inventory, utilityItem.item!);
    
    // Replace the used item with a new one after use
    _actionQueues.replaceUsedItem(utilityItem.item!);
    
    return action;
  }
  
  /// Handle interact action (E key)
  bool _handleInteractAction() {
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
        _updateActionMapping();
        return true;
      } else {
        // Regular item pickup
        var result = game.hero.inventory.tryAdd(item);
        if (result.added > 0) {
          game.log.message('Picked up ${item.clone(result.added)}.');
          
          if (result.remaining == 0) {
            game.stage.removeItem(item, game.hero.pos);
          }
          
          game.hero.pickUp(game, item);
          _updateActionMapping();
          return true;
        } else {
          game.log.message('Your inventory is full.');
          return true;
        }
      }
    }
    
    // Nothing to interact with
    game.log.message("Nothing to pick up or interact with.");
    dirty();
    return true;
  }
  
  /// Track movement for cooldown systems
  void _trackMovement() {
    MovementAction.recordMove();
    
    // Also track slam cooldown for warriors
    var hero = game.hero;
    if (hero.save.heroClass.name.toLowerCase() == 'warrior') {
      SlamAction.recordMove();
    }
  }
  
  /// Handle heal item action
  Action? _handleHealAction() {
    var healItem = _actionQueues.getHealQueueItem();
    if (!healItem.isAvailable || healItem.item == null) {
      return null;
    }
    
    // Always allow healing - even if it will overfill
    var action = UseAction(ItemLocation.inventory, healItem.item!);
    
    // Replace the used item with a new one after use
    _actionQueues.replaceUsedItem(healItem.item!);
    
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
}
