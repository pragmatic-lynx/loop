// lib/src/engine/loop/loop_manager.dart

import '../core/content.dart';
import '../hero/hero_save.dart';
import 'archetype_metadata.dart';
import 'difficulty_scheduler.dart';
import 'hero_preset.dart';
import 'loop_reward.dart';
import 'loop_meter.dart';
import 'metrics_collector.dart';
// TODO: Re-enable when build issues are resolved
// import 'item/loop_item_manager.dart';

/// Manages the roguelite meta-game loop system
class LoopManager {
  static const int movesPerLoop = 100; // Number of moves before showing rewards
  static const int startingDepth = 1; // Starting dungeon depth
  
  int currentLoop = 0;
  int threatLevel = 0;
  int moveCount = 0;
  bool isLoopActive = false;
  bool isRewardSelection = false;
  
  /// Current hero preset configuration
  HeroPreset? currentPreset;
  
  /// Available reward options for the current loop
  List<LoopReward> currentRewardOptions = [];
  
  /// Active temporary bonuses from previous loop rewards
  List<LoopReward> activeRewards = [];
  
  /// Content reference for item generation
  Content? _content;
  
  /// Item manager for loop progression
  // TODO: Re-enable when build issues are resolved
  // LoopItemManager? _itemManager;
  
  /// Difficulty scheduler for archetype management
  final DifficultyScheduler _scheduler = DifficultyScheduler();
  
  /// Current level's archetype metadata
  ArchetypeMetadata? currentArchetypeMetadata;
  
  /// Metrics collector for gameplay analysis
  final MetricsCollector _metricsCollector = MetricsCollector();
  
  /// Loop meter for tracking progress within the current loop
  final LoopMeter _loopMeter = LoopMeter();
  
  /// Initialize the loop system
  LoopManager();
  
  /// Get the current loop meter
  LoopMeter get loopMeter => _loopMeter;
  
  /// Set content for item generation
  void setContent(Content content) {
    _content = content;
    // TODO: Re-enable when build issues are resolved
    // _itemManager = LoopItemManager(content);
  }
  
  /// Start a new loop with the given preset
  void startLoop(HeroPreset preset) {
    currentPreset = preset;
    currentLoop++;
    moveCount = 0;
    isLoopActive = true;
    isRewardSelection = false;
    
    // Clear previous temporary rewards when starting a new loop
    activeRewards.clear();
    
    // Reset loop meter for new loop
    _loopMeter.reset();
    
    // Generate archetype metadata for this loop
    _generateArchetypeMetadata();
    
    print('Starting Loop $currentLoop with preset: ${preset.name}');
    print('Level archetype: ${currentArchetypeMetadata?.archetype.name}');
  }
  
  /// Track a move made by the hero
  void recordMove() {
    if (!isLoopActive) {
      print('recordMove called but loop not active. isLoopActive: $isLoopActive, isRewardSelection: $isRewardSelection');
      return;
    }
    
    moveCount++;
    _metricsCollector.recordTurn();
    
    // Debug info with archetype context
    var archetypeInfo = currentArchetypeMetadata != null ? 
        '${currentArchetypeMetadata!.archetype.name}' : 'unknown';
    print('MOVE_RECORDED: $moveCount/$movesPerLoop (Loop $currentLoop, $archetypeInfo archetype)');
    
    // Check if it's time for reward selection
    if (moveCount >= movesPerLoop) {
      triggerRewardSelection();
    }
  }
  
  /// Trigger the reward selection phase
  void triggerRewardSelection() {
    isLoopActive = false;
    isRewardSelection = true;
    
    // Don't generate the old style reward options anymore
    // The new system will handle rewards based on loop meter fill level
    currentRewardOptions = []; // Clear old options
    
    var archetypeInfo = currentArchetypeMetadata != null ? 
        '${currentArchetypeMetadata!.archetype.name}' : 'unknown';
    var meterProgress = _loopMeter.progress.toStringAsFixed(1);
    print('LOOP_COMPLETE: Loop $currentLoop ($archetypeInfo archetype) - $moveCount moves made, ${meterProgress}% loop meter. Using loop meter rewards!');
  }
  
  /// Apply a selected reward and prepare for next loop
  void selectReward(LoopReward reward) {
    if (!isRewardSelection) {
      print('Warning: selectReward called but not in reward selection phase');
      return;
    }
    
    var prevArchetype = currentArchetypeMetadata?.archetype.name ?? 'unknown';
    print('REWARD_SELECTED: ${reward.name} (from $prevArchetype archetype)');
    activeRewards.add(reward);
    isRewardSelection = false;
    
    // Prepare for next loop
    moveCount = 0;
    threatLevel++; // Increase difficulty
    currentLoop++; // Increment loop counter
    isLoopActive = true; // Reactivate the loop for the next round
    _loopMeter.reset(); // Reset loop meter for the new loop
    
    // Generate metadata for the next loop
    _generateArchetypeMetadata();
    var nextArchetype = currentArchetypeMetadata?.archetype.name ?? 'unknown';
    
    print('LOOP_START: Loop $currentLoop - $nextArchetype archetype, Threat: $threatLevel, Depth: ${getCurrentDepth()}');
    print('DIFFICULTY_SCALARS: Enemy=${currentArchetypeMetadata?.scalars.enemyMultiplier ?? 1.0}x, Item=${currentArchetypeMetadata?.scalars.itemMultiplier ?? 1.0}x');
  }

  /// Finishes the current loop and handles any pending level-ups
  /// Returns true if level-up screen should be shown
  bool finishLoop(HeroSave hero) {
    if (hero.pendingLevels > 0) {
      return true; // Signal that level-up screen should be shown
    }
    return false;
  }
  
  /// Get current depth for dungeon generation
  int getCurrentDepth() {
    var depth = startingDepth + threatLevel;
    // Ensure depth is always at least 1
    return depth < 1 ? 1 : depth;
  }
  
  /// Generate archetype metadata for the current loop
  void _generateArchetypeMetadata() {
    var archetype = _scheduler.getNextArchetype(currentLoop - 1); // 0-based indexing
    var scalars = _scheduler.getScalars(archetype);
    currentArchetypeMetadata = ArchetypeMetadata(
      archetype: archetype,
      scalars: scalars,
      loopNumber: currentLoop,
    );
  }
  
  /// Get the current archetype metadata for level generation
  ArchetypeMetadata? getArchetypeMetadata() {
    return currentArchetypeMetadata;
  }
  
  /// Get the difficulty scheduler for external access
  DifficultyScheduler get scheduler => _scheduler;
  
  /// Get the metrics collector for external access
  MetricsCollector get metricsCollector => _metricsCollector;
  
  /// Record a hero death for metrics
  void recordDeath() {
    var archetypeInfo = currentArchetypeMetadata != null ? 
        '${currentArchetypeMetadata!.archetype.name}' : 'unknown';
    print('HERO_DEATH: Loop $currentLoop ($archetypeInfo archetype) - Move $moveCount/${movesPerLoop}');
    _metricsCollector.recordDeath();
    
    // Reset loop state after death to prevent getting stuck in reward selection
    _resetLoopAfterDeath();
  }
  
  /// Reset loop state after hero death to prevent getting stuck
  void _resetLoopAfterDeath() {
    // Reset move count and loop state
    moveCount = 0;
    isLoopActive = false;
    isRewardSelection = false;
    
    // Clear any pending reward options since the loop was interrupted
    currentRewardOptions.clear();
    
    print('LOOP_RESET_AFTER_DEATH: Loop $currentLoop reset, ready for restart');
  }
  
  /// Check if hero should be given temporary bonuses
  void applyActiveRewards(HeroSave hero) {
    for (var reward in activeRewards) {
      reward.apply(hero);
    }
  }
  
  /// Apply loop-based starting items to hero
  void applyLoopItems(HeroSave hero) {
    // TODO: Re-enable when build issues are resolved
    // if (_itemManager != null) {
    //   _itemManager!.applyLoopStartingItems(hero, currentLoop);
    // }
  }
  
  /// Reset the entire loop system
  void reset() {
    currentLoop = 0;
    threatLevel = 0;
    moveCount = 0;
    isLoopActive = false;
    isRewardSelection = false;
    currentPreset = null;
    currentRewardOptions.clear();
    activeRewards.clear();
    _loopMeter.reset();
    _metricsCollector.reset();
  }
  
  /// Get status info for UI
  Map<String, dynamic> getStatus() {
    return {
      'currentLoop': currentLoop,
      'threatLevel': threatLevel,
      'moveCount': moveCount,
      'movesRemaining': movesPerLoop - moveCount,
      'isActive': isLoopActive,
      'isRewardSelection': isRewardSelection,
      'currentDepth': getCurrentDepth(),
      'archetype': currentArchetypeMetadata?.archetype.name,
      'scalars': currentArchetypeMetadata?.scalars.toString(),
      'loopMeter': _loopMeter.getState(),
    };
  }
  
  /// Record an enemy kill for loop meter progress
  void recordEnemyKill() {
    if (!isLoopActive) return;
    
    var newProgress = _loopMeter.addKillProgress();
    print('ENEMY_KILL: Loop meter now at ${newProgress.toStringAsFixed(1)}%');
    
    // Check for instant Ring Loop completion at 100%
    if (_loopMeter.progress >= 100.0 && !isRewardSelection) {
      print('RING_LOOP_TRIGGERED: Enemy kill completed the ring!');
      triggerRewardSelection();
    }
  }
  
  /// Record a loot pickup for loop meter progress
  void recordLootPickup() {
    if (!isLoopActive) return;
    
    var newProgress = _loopMeter.addLootProgress();
    print('LOOT_PICKUP: Loop meter now at ${newProgress.toStringAsFixed(1)}%');
    
    // Check for instant Ring Loop completion at 100%
    if (_loopMeter.progress >= 100.0 && !isRewardSelection) {
      print('RING_LOOP_TRIGGERED: Loot pickup completed the ring!');
      triggerRewardSelection();
    }
  }
  
  /// Record a shrine sacrifice for loop meter progress
  void recordShrineSacrifice(double hpLost, double maxHp) {
    if (!isLoopActive) return;
    
    var newProgress = _loopMeter.addSacrificeProgress(hpLost, maxHp);
    var progressAdded = (hpLost / maxHp) * 100.0;
    print('SHRINE_SACRIFICE: Added ${progressAdded.toStringAsFixed(1)}% progress, meter now at ${newProgress.toStringAsFixed(1)}%');
    
    // Check for instant Ring Loop completion at 100%
    if (_loopMeter.progress >= 100.0 && !isRewardSelection) {
      print('RING_LOOP_TRIGGERED: Shrine sacrifice completed the ring!');
      triggerRewardSelection();
    }
  }
}
