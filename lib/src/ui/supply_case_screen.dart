// lib/src/ui/supply_case_screen.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../engine/hero/stat.dart';
import '../engine/loop/loop_meter.dart';
import '../engine/loop/loop_reward.dart';
import '../engine/core/content.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Screen that shows the tiered supply case rewards based on loop meter performance
class SupplyCaseScreen extends Screen<Input> {
  final Game game;
  final Content content;
  final LoopMeterRewardTier earnedTier;
  final double meterProgress;
  final int loopNumber;
  final Function() onComplete;
  
  int _selectedChoice = 0;
  List<LoopReward> _availableRewards = [];
  RewardType _currentRewardType = RewardType.weapon;
  bool _showingChoice = false;
  
  SupplyCaseScreen(this.game, this.content, this.earnedTier, this.meterProgress, this.loopNumber, this.onComplete) {
    _initializeRewards();
  }
  
  void _initializeRewards() {
    // Determine what type of reward this loop offers
    _currentRewardType = RewardCycleManager.getRewardType(loopNumber);
    
    // Generate 3 reward options based on the current cycle
    var heroClass = game.hero.save.heroClass.name;
    _availableRewards = LoopReward.generateRewardOptions(3, loopNumber, content, heroClass);
    
    // For higher tier performance, allow choosing between options
    _showingChoice = (earnedTier == LoopMeterRewardTier.legendary || 
                     earnedTier == LoopMeterRewardTier.master ||
                     earnedTier == LoopMeterRewardTier.apprentice);
                     
    // For lower tiers, just give the first option or basic rewards
    if (!_showingChoice) {
      if (_availableRewards.isNotEmpty && earnedTier != LoopMeterRewardTier.survival) {
        _availableRewards = [_availableRewards.first];
      } else {
        _availableRewards = [];
      }
    }
  }
  
  @override
  bool handleInput(Input input) {
    if (_showingChoice) {
      return _handleRewardChoice(input);
    }
    
    switch (input) {
      case Input.ok:
        _applyRewards();
        onComplete();
        return true;
        
      default:
        return false;
    }
  }
  
  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_showingChoice) {
      switch (keyCode) {
        case 38: // Up arrow
        case 87: // W key
          if (_selectedChoice > 0) {
            _selectedChoice--;
            dirty();
          }
          return true;
          
        case 40: // Down arrow
        case 83: // S key
          if (_selectedChoice < _availableRewards.length - 1) {
            _selectedChoice++;
            dirty();
          }
          return true;
          
        case 13: // Enter
        case 32: // Space
        case 69: // E key
          _applyRewards();
          onComplete();
          return true;
      }
    } else {
      switch (keyCode) {
        case 13: // Enter
        case 32: // Space
        case 69: // E key
          _applyRewards();
          onComplete();
          return true;
      }
    }
    
    return false;
  }
  
  bool _handleRewardChoice(Input input) {
    switch (input) {
      case Input.n:
        if (_selectedChoice > 0) {
          _selectedChoice--;
          dirty();
        }
        return true;
        
      case Input.s:
        if (_selectedChoice < _availableRewards.length - 1) {
          _selectedChoice++;
          dirty();
        }
        return true;
        
      case Input.ok:
        _applyRewards();
        onComplete();
        return true;
        
      default:
        return false;
    }
  }
  
  void _applyRewards() {
    var hero = game.hero;
    if (hero == null) {
      game.log.error("Error: Hero not found!");
      onComplete();
      return;
    }
    
    // Apply the selected reward from the cycle (weapon/stat/armor)
    if (_availableRewards.isNotEmpty) {
      var selectedIndex = _showingChoice ? _selectedChoice : 0;
      if (selectedIndex < _availableRewards.length) {
        var selectedReward = _availableRewards[selectedIndex];
        selectedReward.apply(hero.save);
        game.log.gain("${selectedReward.name} - ${selectedReward.description}");
      }
    }
    
    // Apply additional supply bundle based on performance tier
    switch (earnedTier) {
      case LoopMeterRewardTier.legendary:
        _addSupplyBundle(BundleSize.large);
        break;
        
      case LoopMeterRewardTier.master:
        _addSupplyBundle(BundleSize.medium);
        break;
        
      case LoopMeterRewardTier.apprentice:
        _addSupplyBundle(BundleSize.small);
        break;
        
      case LoopMeterRewardTier.novice:
        _addBasicSurvival();
        break;
        
      case LoopMeterRewardTier.survival:
        _addMinimalSurvival();
        break;
    }
    
    // Always restore to full health after every loop
    hero.health = hero.maxHealth;
    if (hero.poison != null) hero.poison.cancel();
    if (hero.cold != null) hero.cold.cancel();
    game.log.gain("You are fully restored!");
  }
  
  void _addSupplyBundle(BundleSize size) {
    switch (size) {
      case BundleSize.large:
        game.log.gain("Large Supply Bundle: 3x Bottled Earth, 2x Resistance Scrolls, 4x Healing Potions");
        break;
      case BundleSize.medium:
        game.log.gain("Medium Supply Bundle: 2x Bottled Earth, 1x Resistance Scroll, 3x Healing Potions");
        break;
      case BundleSize.small:
        game.log.gain("Small Supply Bundle: 1x Bottled Earth, 2x Healing Potions");
        break;
    }
    // TODO: Actually add items to inventory when item system is available
  }
  
  void _addBasicSurvival() {
    game.log.gain("Basic Survival: 1x Healing Potion");
    // TODO: Add actual items
  }
  
  void _addMinimalSurvival() {
    game.log.gain("Minimal Survival: Bread crumbs and determination");
    // TODO: Add actual items
  }
  
  @override
  void render(Terminal terminal) {
    terminal.clear();
    
    if (_showingChoice) {
      _renderRewardChoice(terminal);
    } else {
      _renderSupplyCaseDisplay(terminal);
    }
  }
  
  void _renderRewardChoice(Terminal terminal) {
    var dialogWidth = 70;
    var dialogHeight = 20;
    var x = (terminal.width - dialogWidth) ~/ 2;
    var y = (terminal.height - dialogHeight) ~/ 2;
    
    var dialogTerminal = terminal.rect(x, y, dialogWidth, dialogHeight);
    
    // Draw dialog background
    for (var dx = 0; dx < dialogWidth; dx++) {
      for (var dy = 0; dy < dialogHeight; dy++) {
        dialogTerminal.writeAt(dx, dy, ' ', ash, darkerCoolGray);
      }
    }
    Draw.doubleBox(dialogTerminal, 0, 0, dialogWidth, dialogHeight);
    
    var cycleName = RewardCycleManager.getCycleName(loopNumber);
    dialogTerminal.writeAt(2, 2, "Loop $loopNumber Reward: $cycleName", gold);
    
    // Show current hero stats for context
    dialogTerminal.writeAt(2, 4, "Current Stats:", lightBlue);
    var hero = game.hero;
    if (hero != null) {
      dialogTerminal.writeAt(4, 5, "STR: ${hero.strength.value}", ash);
      dialogTerminal.writeAt(16, 5, "AGI: ${hero.agility.value}", ash);
      dialogTerminal.writeAt(28, 5, "FOR: ${hero.fortitude.value}", ash);
      dialogTerminal.writeAt(40, 5, "INT: ${hero.intellect.value}", ash);
      dialogTerminal.writeAt(52, 5, "WIL: ${hero.will.value}", ash);
    }
    
    Draw.hLine(dialogTerminal, 2, 7, dialogWidth - 4);
    
    dialogTerminal.writeAt(2, 8, "Choose your reward:", lightBlue);
    
    for (var i = 0; i < _availableRewards.length; i++) {
      var reward = _availableRewards[i];
      var color = i == _selectedChoice ? gold : ash;
      var prefix = i == _selectedChoice ? "> " : "  ";
      
      dialogTerminal.writeAt(4, 10 + i * 2, "${prefix}${reward.name}", color);
      dialogTerminal.writeAt(6, 11 + i * 2, reward.description, i == _selectedChoice ? lightBlue : darkWarmGray);
    }
    
    Draw.helpKeys(terminal, {
      "↕": "Choose reward",
      "Enter": "Confirm choice",
    });
  }
  
  void _renderSupplyCaseDisplay(Terminal terminal) {
    var centerTerminal = terminal.rect(
        (terminal.width - 80) ~/ 2, (terminal.height - 35) ~/ 2, 80, 35);
    
    centerTerminal.clear();
    Draw.doubleBox(centerTerminal, 0, 0, centerTerminal.width, centerTerminal.height);
    
    // Title with progress and reward cycle info
    centerTerminal.writeAt(3, 2, 'LOOP $loopNumber COMPLETE', gold);
    var cycleName = RewardCycleManager.getCycleName(loopNumber);
    centerTerminal.writeAt(3, 3, 'Loop filled to ${meterProgress.toInt()}% - ${earnedTier.displayName} earned', ash);
    centerTerminal.writeAt(3, 4, 'Reward Type: $cycleName', lightBlue);
    
    // Show current stats
    centerTerminal.writeAt(3, 6, 'Current Stats:', lightBlue);
    var hero = game.hero;
    if (hero != null) {
      centerTerminal.writeAt(5, 7, 'STR: ${hero.strength.value}', ash);
      centerTerminal.writeAt(17, 7, 'AGI: ${hero.agility.value}', ash);
      centerTerminal.writeAt(29, 7, 'FOR: ${hero.fortitude.value}', ash);
      centerTerminal.writeAt(41, 7, 'INT: ${hero.intellect.value}', ash);
      centerTerminal.writeAt(53, 7, 'WIL: ${hero.will.value}', ash);
    }
    
    Draw.hLine(centerTerminal, 3, 9, centerTerminal.width - 6);
    
    var currentY = 11;
    
    // Show the specific reward you're getting
    if (_availableRewards.isNotEmpty) {
      centerTerminal.writeAt(3, currentY, 'Your Reward:', gold);
      currentY++;
      
      if (_showingChoice) {
        centerTerminal.writeAt(5, currentY, 'Choose from ${_availableRewards.length} options:', lightBlue);
        currentY++;
        for (var i = 0; i < _availableRewards.length; i++) {
          var reward = _availableRewards[i];
          centerTerminal.writeAt(7, currentY, '• ${reward.name}', ash);
          currentY++;
        }
      } else {
        var reward = _availableRewards.first;
        centerTerminal.writeAt(5, currentY, '• ${reward.name}', gold);
        currentY++;
        centerTerminal.writeAt(7, currentY, reward.description, lightBlue);
        currentY++;
      }
      currentY++;
    }
    
    // Show performance tier rewards
    centerTerminal.writeAt(3, currentY, 'Performance Bonuses:', lightBlue);
    currentY++;
    
    var allTiers = [LoopMeterRewardTier.legendary, LoopMeterRewardTier.master, 
                   LoopMeterRewardTier.apprentice, LoopMeterRewardTier.novice, LoopMeterRewardTier.survival];
    
    for (var tier in allTiers) {
      var earned = _tierEarned(tier);
      var prefix = earned ? "[✓]" : "[✗]";
      var color = earned ? gold : darkWarmGray;
      
      centerTerminal.writeAt(3, currentY, prefix, color);
      centerTerminal.writeAt(7, currentY, '${tier.displayName} (${tier.threshold.toInt()}%+)', color);
      
      currentY++;
      centerTerminal.writeAt(7, currentY, _getTierRewards(tier), earned ? lightBlue : darkWarmGray);
      
      currentY += 2;
    }
    
    // Next cycle hint
    var nextCycleName = RewardCycleManager.getCycleName(loopNumber + 1);
    centerTerminal.writeAt(3, currentY, 
        'Next Loop: ${nextCycleName}', yellow);
    
    // Instructions
    if (_showingChoice) {
      Draw.helpKeys(terminal, {
        "Enter": "Choose reward",
      });
    } else {
      Draw.helpKeys(terminal, {
        "Enter": "Continue",
      });
    }
  }
  
  bool _tierEarned(LoopMeterRewardTier tier) {
    return meterProgress >= tier.threshold;
  }
  
  String _getTierRewards(LoopMeterRewardTier tier) {
    switch (tier) {
      case LoopMeterRewardTier.legendary:
        return "• Large Combat/Resistance/Survival Bundles";
      case LoopMeterRewardTier.master:
        return "• Medium Combat/Resistance/Survival Bundles";
      case LoopMeterRewardTier.apprentice:
        return "• Small Combat/Resistance/Survival Bundles";
      case LoopMeterRewardTier.novice:
        return "• Basic Survival Bundle (1x Healing Potion)";
      case LoopMeterRewardTier.survival:
        return "• Minimal Supplies (breadcrumbs and hope)";
    }
  }
}

enum BundleSize {
  large,
  medium,
  small,
}
