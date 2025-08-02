// lib/src/ui/loop_reward_screen.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../engine/loop/reward_choice_log.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';
import 'level_up_screen.dart';
import 'loop_game_screen.dart';
import 'storage.dart';

class LoopRewardScreen extends Screen<Input> {
  final Content content;
  final Storage storage;
  final LoopManager loopManager;
  final HeroSave hero;
  final List<LoopReward> rewardOptions;
  
  int selectedReward = 0;
  
  LoopRewardScreen(this.content, this.storage, this.loopManager, this.hero)
      : rewardOptions = loopManager.currentRewardOptions {
    // Ensure loop manager has content for generating item rewards
    loopManager.setContent(content);
    
    // If no reward options are available, generate them now
    if (loopManager.currentRewardOptions.isEmpty) {
      loopManager.triggerRewardSelection();
      // Update our local reference to the newly generated options
      rewardOptions.clear();
      rewardOptions.addAll(loopManager.currentRewardOptions);
    }
    
    // Ensure we have at least one reward option to prevent crashes
    if (rewardOptions.isEmpty) {
      print('Warning: No reward options available, generating cycle-based rewards');
      rewardOptions.addAll(LoopReward.generateRewardOptions(3, loopManager.currentLoop, content, hero.heroClass.name));
    }
  }
  
  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n when selectedReward > 0:
        selectedReward--;
        dirty();
        return true;
        
      case Input.s when selectedReward < rewardOptions.length - 1:
        selectedReward++;
        dirty();
        return true;
        
      case Input.ok:
        _selectReward();
        return true;
    }
    
    return false;
  }
  
  void _selectReward() {
    // Safety check to prevent index out of bounds
    if (rewardOptions.isEmpty) {
      print('Error: No reward options available');
      return;
    }
    
    if (selectedReward >= rewardOptions.length) {
      print('Error: Selected reward index $selectedReward is out of bounds (max: ${rewardOptions.length - 1})');
      selectedReward = 0; // Reset to first option
    }
    
    var reward = rewardOptions[selectedReward];
    
    // Log the reward choice with archetype context
    _logRewardChoice(reward);
    
    // Apply the selected reward to the loop manager
    loopManager.selectReward(reward);
    
    // Apply immediate effects to hero
    reward.apply(hero);
    
    // Continue to next loop
    _startNextLoop();
  }

  void _logRewardChoice(LoopReward reward) {
    try {
      // Get current archetype metadata from loop manager
      var metadata = loopManager.getArchetypeMetadata();
      if (metadata != null) {
        // Generate choice ID from reward name and index
        var choiceId = '${reward.name.replaceAll(' ', '_').toLowerCase()}_$selectedReward';
        
        // Log the choice asynchronously
        RewardChoiceLogger.logChoiceNow(
          metadata.loopNumber,
          metadata.archetype,
          choiceId,
        );
      } else {
        print('Warning: No archetype metadata available for reward choice logging');
      }
    } catch (e) {
      print('Error logging reward choice: $e');
    }
  }
  
  void _startNextLoop() {
    // Check if we need to show level-up screen after reward selection
    if (loopManager.finishLoop(hero)) {
      // Show level-up screen before starting next loop
      ui.push(LevelUpScreen(
        hero: hero,
        pendingLevels: hero.pendingLevels,
        storage: storage,
      ));
      
      // Clear pending levels after showing screen
      hero.pendingLevels = 0;
    }
    
    // Start the next loop at increased depth
    var depth = loopManager.getCurrentDepth();
    print("Starting next loop at depth: $depth");
    
    // Ensure depth is never 0 or negative
    if (depth <= 0) {
      print("Warning: depth was $depth, setting to 1");
      depth = 1;
    }
    
    ui.goTo(LoopGameScreen.create(storage, content, hero, loopManager));
  }
  
  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    return false; // No escape from reward selection - must choose!
  }
  
  @override
  void render(Terminal terminal) {
    terminal.clear();
    
    // Center the content
    var centerTerminal = terminal.rect(
        (terminal.width - 80) ~/ 2, (terminal.height - 30) ~/ 2, 80, 30);
    
    centerTerminal.clear();
    Draw.doubleBox(centerTerminal, 0, 0, centerTerminal.width, centerTerminal.height);
    
    // Title
    var status = loopManager.getStatus();
    centerTerminal.writeAt(3, 2, 'LOOP ${status['currentLoop']} COMPLETE!', UIHue.primary);
    centerTerminal.writeAt(3, 3, 'You made ${status['moveCount']} moves. Choose your reward:', UIHue.text);
    
    Draw.hLine(centerTerminal, 3, 5, centerTerminal.width - 6);
    
    // Reward options
    centerTerminal.writeAt(3, 7, 'Select your boon for the next challenge:', UIHue.text);
    
    for (var i = 0; i < rewardOptions.length; i++) {
      var reward = rewardOptions[i];
      var yStart = 9 + i * 6;
      
      var primary = UIHue.primary;
      var secondary = UIHue.secondary;
      var accent = UIHue.disabled;
      
      if (i == selectedReward) {
        primary = UIHue.selection;
        secondary = UIHue.selection;
        accent = UIHue.text;
        
        // Draw selection box
        Draw.box(centerTerminal, 2, yStart - 1, centerTerminal.width - 4, 5);
      }
      
      centerTerminal.writeAt(4, yStart, reward.name, primary);
      centerTerminal.writeAt(4, yStart + 1, reward.description, secondary);
      
      // Wrap flavor text
      _writeWrappedText(centerTerminal, 4, yStart + 2, 
          centerTerminal.width - 8, reward.flavorText, accent);
    }
    
    // Progress info
    var nextDepth = status['currentDepth'] + 1;
    centerTerminal.writeAt(3, centerTerminal.height - 4, 
        'Next Challenge: Depth $nextDepth', UIHue.secondary);
    centerTerminal.writeAt(3, centerTerminal.height - 3,
        'Threat Level: ${status['threatLevel'] + 1}', UIHue.secondary);
    
    Draw.helpKeys(terminal, {
      "OK": "Select reward",
      "↕": "Change selection",
    });
  }
  
  void _writeWrappedText(Terminal terminal, int x, int y, int width, 
      String text, Color color) {
    var words = text.split(' ');
    var currentLine = '';
    var currentY = y;
    
    for (var word in words) {
      if (currentLine.isEmpty) {
        currentLine = word;
      } else if (currentLine.length + word.length + 1 <= width) {
        currentLine += ' $word';
      } else {
        terminal.writeAt(x, currentY, currentLine, color);
        currentLine = word;
        currentY++;
      }
    }
    
    if (currentLine.isNotEmpty) {
      terminal.writeAt(x, currentY, currentLine, color);
    }
  }
}
