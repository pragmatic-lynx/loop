// lib/src/engine/loop/loop_manager.dart

import '../hero/hero_save.dart';
import 'loop_reward.dart';
import 'hero_preset.dart';

/// Manages the roguelite meta-game loop system
class LoopManager {
  static const int movesPerLoop = 50; // Number of moves before showing rewards
  static const int startingDepth = 3; // Starting dungeon depth
  
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
  
  /// Initialize the loop system
  LoopManager();
  
  /// Start a new loop with the given preset
  void startLoop(HeroPreset preset) {
    currentPreset = preset;
    currentLoop++;
    moveCount = 0;
    isLoopActive = true;
    isRewardSelection = false;
    
    // Clear previous temporary rewards when starting a new loop
    activeRewards.clear();
    
    print('Starting Loop $currentLoop with preset: ${preset.name}');
  }
  
  /// Track a move made by the hero
  void recordMove() {
    if (!isLoopActive) return;
    
    moveCount++;
    
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
    
    print('Loop $currentLoop complete! $moveCount moves made. Time for rewards!');
  }
  
  /// Apply a selected reward and prepare for next loop
  void selectReward(LoopReward reward) {
    if (!isRewardSelection) return;
    
    activeRewards.add(reward);
    isRewardSelection = false;
    
    // Prepare for next loop
    moveCount = 0;
    threatLevel++; // Increase difficulty
    
    print('Selected reward: ${reward.name}. Threat level now: $threatLevel');
  }
  
  /// Get current depth for dungeon generation
  int getCurrentDepth() {
    return startingDepth + threatLevel;
  }
  
  /// Check if hero should be given temporary bonuses
  void applyActiveRewards(HeroSave hero) {
    for (var reward in activeRewards) {
      reward.apply(hero);
    }
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
    };
  }
}
