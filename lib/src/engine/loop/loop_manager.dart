// lib/src/engine/loop/loop_manager.dart

import '../hero/hero_save.dart';
import '../core/content.dart';
import 'loop_reward.dart';
import 'hero_preset.dart';
import 'item/loop_item_manager.dart';

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
  LoopItemManager? _itemManager;
  
  /// Initialize the loop system
  LoopManager();
  
  /// Set content for item generation
  void setContent(Content content) {
    _content = content;
    _itemManager = LoopItemManager(content);
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
    
    print('Starting Loop $currentLoop with preset: ${preset.name}');
  }
  
  /// Track a move made by the hero
  void recordMove() {
    if (!isLoopActive) {
      print('recordMove called but loop not active. isLoopActive: $isLoopActive, isRewardSelection: $isRewardSelection');
      return;
    }
    
    moveCount++;
    print('Move recorded: $moveCount/$movesPerLoop (Loop $currentLoop)');
    
    // Check if it's time for reward selection
    if (moveCount >= movesPerLoop) {
      triggerRewardSelection();
    }
  }
  
  /// Trigger the reward selection phase
  void triggerRewardSelection() {
    isLoopActive = false;
    isRewardSelection = true;
    
    // Generate 3 random reward options (now including item rewards)
    currentRewardOptions = LoopReward.generateRewardOptions(3, 
      content: _content, 
      currentLoop: currentLoop
    );
    
    print('Loop $currentLoop complete! $moveCount moves made. Time for rewards!');
  }
  
  /// Apply a selected reward and prepare for next loop
  void selectReward(LoopReward reward) {
    if (!isRewardSelection) {
      print('Warning: selectReward called but not in reward selection phase');
      return;
    }
    
    print('Selecting reward: ${reward.name}');
    activeRewards.add(reward);
    isRewardSelection = false;
    
    // Prepare for next loop
    moveCount = 0;
    threatLevel++; // Increase difficulty
    currentLoop++; // Increment loop counter
    isLoopActive = true; // Reactivate the loop for the next round
    
    print('Selected reward: ${reward.name}. Threat level now: $threatLevel, Loop: $currentLoop');
    print('Next depth will be: ${getCurrentDepth()}');
  }
  
  /// Get current depth for dungeon generation
  int getCurrentDepth() {
    var depth = startingDepth + threatLevel;
    // Ensure depth is always at least 1
    return depth < 1 ? 1 : depth;
  }
  
  /// Check if hero should be given temporary bonuses
  void applyActiveRewards(HeroSave hero) {
    for (var reward in activeRewards) {
      reward.apply(hero);
    }
  }
  
  /// Apply loop-based starting items to hero
  void applyLoopItems(HeroSave hero) {
    if (_itemManager != null) {
      _itemManager!.applyLoopStartingItems(hero, currentLoop);
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
