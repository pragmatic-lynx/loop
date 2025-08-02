// lib/src/ui/supply_case_screen.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../engine/hero/stat.dart';
import '../engine/loop/loop_meter.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Screen that shows the tiered supply case rewards based on loop meter performance
class SupplyCaseScreen extends Screen<Input> {
  final Game game;
  final LoopMeterRewardTier earnedTier;
  final double meterProgress;
  final Function() onComplete;
  
  int _selectedStat = 0;
  List<Stat> _availableStats = [Stat.strength, Stat.agility, Stat.fortitude, Stat.intellect, Stat.will];
  bool _showingStatChoice = false;
  
  SupplyCaseScreen(this.game, this.earnedTier, this.meterProgress, this.onComplete);
  
  @override
  bool handleInput(Input input) {
    if (_showingStatChoice) {
      return _handleStatChoice(input);
    }
    
    switch (input) {
      case Input.ok:
        if (earnedTier == LoopMeterRewardTier.legendary || earnedTier == LoopMeterRewardTier.master) {
          _showingStatChoice = true;
          dirty();
        } else {
          _applyRewards();
          onComplete();
        }
        return true;
        
      default:
        return false;
    }
  }
  
  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_showingStatChoice) {
      switch (keyCode) {
        case 38: // Up arrow
        case 87: // W key
          if (_selectedStat > 0) {
            _selectedStat--;
            dirty();
          }
          return true;
          
        case 40: // Down arrow
        case 83: // S key
          if (_selectedStat < _availableStats.length - 1) {
            _selectedStat++;
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
          if (earnedTier == LoopMeterRewardTier.legendary || earnedTier == LoopMeterRewardTier.master) {
            _showingStatChoice = true;
            dirty();
          } else {
            _applyRewards();
            onComplete();
          }
          return true;
      }
    }
    
    return false;
  }
  
  bool _handleStatChoice(Input input) {
    switch (input) {
      case Input.n:
        if (_selectedStat > 0) {
          _selectedStat--;
          dirty();
        }
        return true;
        
      case Input.s:
        if (_selectedStat < _availableStats.length - 1) {
          _selectedStat++;
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
    
    switch (earnedTier) {
      case LoopMeterRewardTier.legendary:
        // +2 stat boost + Large bundles
        if (_showingStatChoice && _selectedStat < _availableStats.length) {
          var chosenStat = _availableStats[_selectedStat];
          // TODO: Implement permanent stat bonus system
          game.log.gain("Legendary power! Your ${chosenStat.name} would increase by 2!");
        }
        _addSupplyBundle(BundleSize.large);
        break;
        
      case LoopMeterRewardTier.master:
        // +1 stat boost + Medium bundles
        if (_showingStatChoice && _selectedStat < _availableStats.length) {
          var chosenStat = _availableStats[_selectedStat];
          // TODO: Implement permanent stat bonus system
          game.log.gain("Mastery achieved! Your ${chosenStat.name} would increase by 1!");
        }
        _addSupplyBundle(BundleSize.medium);
        break;
        
      case LoopMeterRewardTier.apprentice:
        // +1 random stat + Small bundles
        var randomStat = _availableStats[game.stage.actors.length % _availableStats.length];
        // TODO: Implement permanent stat bonus system
        game.log.gain("Your ${randomStat.name} would increase by 1!");
        _addSupplyBundle(BundleSize.small);
        break;
        
      case LoopMeterRewardTier.novice:
        // Basic survival items only
        game.log.gain("You receive basic survival supplies.");
        _addBasicSurvival();
        break;
        
      case LoopMeterRewardTier.survival:
        // Minimal items
        game.log.gain("You scrape together minimal supplies.");
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
    
    if (_showingStatChoice) {
      _renderStatChoice(terminal);
    } else {
      _renderSupplyCaseDisplay(terminal);
    }
  }
  
  void _renderStatChoice(Terminal terminal) {
    var dialogWidth = 60;
    var dialogHeight = 18;
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
    
    dialogTerminal.writeAt(2, 2, "Choose Your Stat Boost!", gold);
    
    // Show current stats
    dialogTerminal.writeAt(2, 4, "Current Stats:", lightBlue);
    var hero = game.hero;
    if (hero != null) {
      dialogTerminal.writeAt(4, 5, "STR: ${hero.strength.value}", ash);
      dialogTerminal.writeAt(16, 5, "AGI: ${hero.agility.value}", ash);
      dialogTerminal.writeAt(28, 5, "FOR: ${hero.fortitude.value}", ash);
      dialogTerminal.writeAt(4, 6, "INT: ${hero.intellect.value}", ash);
      dialogTerminal.writeAt(16, 6, "WIL: ${hero.will.value}", ash);
    }
    
    Draw.hLine(dialogTerminal, 2, 7, dialogWidth - 4);
    
    for (var i = 0; i < _availableStats.length; i++) {
      var stat = _availableStats[i];
      var color = i == _selectedStat ? gold : ash;
      var prefix = i == _selectedStat ? "> " : "  ";
      
      dialogTerminal.writeAt(4, 9 + i, "${prefix}${stat.name}", color);
    }
    
    Draw.helpKeys(terminal, {
      "↕": "Choose stat",
      "Enter": "Confirm choice",
    });
  }
  
  void _renderSupplyCaseDisplay(Terminal terminal) {
    var centerTerminal = terminal.rect(
        (terminal.width - 80) ~/ 2, (terminal.height - 35) ~/ 2, 80, 35);
    
    centerTerminal.clear();
    Draw.doubleBox(centerTerminal, 0, 0, centerTerminal.width, centerTerminal.height);
    
    // Title with progress
    centerTerminal.writeAt(3, 2, 'LOOP COMPLETE!', gold);
    centerTerminal.writeAt(3, 3, 'Ring filled to ${meterProgress.toInt()}% - ${earnedTier.displayName} earned!', ash);
    
    // Show current stats
    centerTerminal.writeAt(3, 5, 'Current Stats:', lightBlue);
    var hero = game.hero;
    if (hero != null) {
      centerTerminal.writeAt(5, 6, 'STR: ${hero.strength.value}', ash);
      centerTerminal.writeAt(17, 6, 'AGI: ${hero.agility.value}', ash);
      centerTerminal.writeAt(29, 6, 'FOR: ${hero.fortitude.value}', ash);
      centerTerminal.writeAt(41, 6, 'INT: ${hero.intellect.value}', ash);
      centerTerminal.writeAt(53, 6, 'WIL: ${hero.will.value}', ash);
    }
    
    Draw.hLine(centerTerminal, 3, 8, centerTerminal.width - 6);
    
    var currentY = 10;
    
    // Show all tiers with what you got vs what you missed
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
    
    // Next tier hint
    if (earnedTier != LoopMeterRewardTier.legendary) {
      var nextTier = _getNextTier();
      if (nextTier != null) {
        centerTerminal.writeAt(3, currentY, 
            'Next time: Reach ${nextTier.threshold.toInt()}% for ${nextTier.displayName}!', yellow);
      }
    }
    
    // Instructions
    if (earnedTier == LoopMeterRewardTier.legendary || earnedTier == LoopMeterRewardTier.master) {
      Draw.helpKeys(terminal, {
        "Enter": "Choose stat boost",
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
  
  LoopMeterRewardTier? _getNextTier() {
    var allTiers = [LoopMeterRewardTier.survival, LoopMeterRewardTier.novice, 
                   LoopMeterRewardTier.apprentice, LoopMeterRewardTier.master, LoopMeterRewardTier.legendary];
    
    for (var tier in allTiers) {
      if (!_tierEarned(tier)) {
        return tier;
      }
    }
    return null;
  }
  
  String _getTierRewards(LoopMeterRewardTier tier) {
    switch (tier) {
      case LoopMeterRewardTier.legendary:
        return "• +2 Stat Boost (choose) + Large Combat/Resistance/Survival Bundles";
      case LoopMeterRewardTier.master:
        return "• +1 Stat Boost (choose) + Medium Combat/Resistance/Survival Bundles";
      case LoopMeterRewardTier.apprentice:
        return "• +1 Random Stat Boost + Small Combat/Resistance/Survival Bundles";
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
