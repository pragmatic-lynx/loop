// lib/src/engine/loop/loop_manager.dart

import '../core/content.dart';
import '../hero/hero_save.dart';
import 'archetype_metadata.dart';
import 'difficulty_scheduler.dart';
import 'hero_preset.dart';
import 'loop_reward.dart';
import 'metrics_collector.dart';
// TODO: Re-enable when build issues are resolved
// import 'item/loop_item_manager.dart';

/// Manages the roguelite meta-game loop system
class LoopManager {
  static const int movesPerLoop = 50; // Number of moves before showing rewards
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
  
  /// Initialize the loop system
  LoopManager();
  
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
    
    // Generate 3 random reward options
    currentRewardOptions = LoopReward.generateRewardOptions(3);
    
    var archetypeInfo = currentArchetypeMetadata != null ? 
        '${currentArchetypeMetadata!.archetype.name}' : 'unknown';
    print('LOOP_COMPLETE: Loop $currentLoop ($archetypeInfo archetype) - $moveCount moves made. Time for rewards!');
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
    
    // Generate metadata for the next loop
    _generateArchetypeMetadata();
    var nextArchetype = currentArchetypeMetadata?.archetype.name ?? 'unknown';
    
    print('LOOP_START: Loop $currentLoop - $nextArchetype archetype, Threat: $threatLevel, Depth: ${getCurrentDepth()}');
    print('DIFFICULTY_SCALARS: Enemy=${currentArchetypeMetadata?.scalars.enemyMultiplier ?? 1.0}x, Item=${currentArchetypeMetadata?.scalars.itemMultiplier ?? 1.0}x');
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
    };
  }
}
