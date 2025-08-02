// lib/src/ui/choose_reward_dialog.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../engine/hero/stat.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Dialog for choosing between permanent trait, large heal, or rare item rewards
class ChooseRewardDialog extends Screen<Input> {
  final Game game;
  final Function(RewardChoice) onRewardSelected;
  final List<RewardChoice> _options = [];
  
  int _selectedIndex = 0;
  
  ChooseRewardDialog(this.game, this.onRewardSelected) {
    _generateRewardOptions();
  }
  
  void _generateRewardOptions() {
    // Option 1: Permanent Trait (+1 to a random stat)
    var randomStat = _getRandomStat();
    _options.add(RewardChoice(
      type: RewardType.permanentTrait,
      name: "Permanent ${randomStat.name} Boost",
      description: "Permanently increase your ${randomStat.name} by 1",
      flavorText: "The ring's power flows into your very essence, strengthening you forever.",
      statToBoost: randomStat,
    ));
    
    // Option 2: Large Heal Consumable
    _options.add(RewardChoice(
      type: RewardType.largeHeal,
      name: "Complete Restoration",
      description: "Restore to full HP and remove all negative status effects",
      flavorText: "Ancient healing energy washes over you, purging all ailments.",
    ));
    
    // Option 3: Rare Item
    _options.add(RewardChoice(
      type: RewardType.rareItem,
      name: "Legendary Artifact",
      description: "Receive a powerful rare item from the depths",
      flavorText: "The ring reveals a treasure from ages past, crackling with power.",
    ));
  }
  
  Stat _getRandomStat() {
    var availableStats = [Stat.strength, Stat.agility, Stat.fortitude, Stat.intellect, Stat.will];
    return availableStats[game.stage.actors.length % availableStats.length]; // Simple pseudo-random
  }
  
  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n:
        if (_selectedIndex > 0) {
          _selectedIndex--;
          dirty();
        }
        return true;
        
      case Input.s:
        if (_selectedIndex < _options.length - 1) {
          _selectedIndex++;
          dirty();
        }
        return true;
        
      case Input.ok:
        _selectReward();
        return true;
        
      default:
        return false;
    }
  }
  
  void _selectReward() {
    if (_selectedIndex >= 0 && _selectedIndex < _options.length) {
      var selectedReward = _options[_selectedIndex];
      onRewardSelected(selectedReward);
      ui.pop(selectedReward);
    }
  }
  
  @override
  void render(Terminal terminal) {
    // Center the dialog
    var dialogWidth = 60;
    var dialogHeight = 20;
    var x = (terminal.width - dialogWidth) ~/ 2;
    var y = (terminal.height - dialogHeight) ~/ 2;
    
    var dialogTerminal = terminal.rect(x, y, dialogWidth, dialogHeight);
    
    // Draw dialog background and border
    for (var x = 0; x < dialogWidth; x++) {
      for (var y = 0; y < dialogHeight; y++) {
        dialogTerminal.writeAt(x, y, ' ', ash, darkerCoolGray);
      }
    }
    Draw.doubleBox(dialogTerminal, 0, 0, dialogWidth, dialogHeight);
    
    // Title
    dialogTerminal.writeAt(2, 2, "RING LOOP COMPLETE!", gold);
    dialogTerminal.writeAt(2, 3, "Choose your reward:", ash);
    
    Draw.hLine(dialogTerminal, 2, 5, dialogWidth - 4);
    
    // Render reward options
    for (var i = 0; i < _options.length; i++) {
      var option = _options[i];
      var yPos = 7 + i * 4;
      var isSelected = i == _selectedIndex;
      
      var nameColor = isSelected ? gold : lightBlue;
      var descColor = isSelected ? lightWarmGray : ash;
      var flavorColor = isSelected ? warmGray : darkWarmGray;
      
      if (isSelected) {
        // Draw selection highlight
        for (var x = 1; x < dialogWidth - 1; x++) {
          for (var dy = 0; dy < 3; dy++) {
            dialogTerminal.writeAt(x, yPos - 1 + dy, ' ', ash, coolGray);
          }
        }
      }
      
      // Option number and name
      dialogTerminal.writeAt(3, yPos, "${i + 1}. ${option.name}", nameColor);
      
      // Description
      dialogTerminal.writeAt(6, yPos + 1, option.description, descColor);
      
      // Flavor text (wrapped)
      _writeWrappedText(dialogTerminal, 6, yPos + 2, dialogWidth - 12, option.flavorText, flavorColor);
    }
    
    // Controls
    Draw.helpKeys(terminal, {
      "↕": "Choose option",
      "OK": "Select reward",
    });
  }
  
  void _writeWrappedText(Terminal terminal, int x, int y, int width, String text, Color color) {
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

/// Represents a reward choice in the dialog
class RewardChoice {
  final RewardType type;
  final String name;
  final String description;
  final String flavorText;
  final Stat? statToBoost; // Only used for permanent trait rewards
  
  RewardChoice({
    required this.type,
    required this.name,
    required this.description,
    required this.flavorText,
    this.statToBoost,
  });
}

/// Types of rewards available in the dialog
enum RewardType {
  permanentTrait,
  largeHeal,
  rareItem,
}
