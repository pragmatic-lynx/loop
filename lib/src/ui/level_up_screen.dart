// lib/src/ui/level_up_screen.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../engine/core/option.dart';
import '../engine/audio_manager.dart';
import '../engine/sfx_id.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';
import 'storage.dart';

/// Screen for handling hero level-ups with skill point awards
class LevelUpScreen extends Screen<Input> {
  final HeroSave hero;
  final int pendingLevels;
  final Storage storage;
  int currentLevel = 0;
  
  LevelUpScreen({required this.hero, required this.pendingLevels, required this.storage}) {
    // Play level up sound when screen appears
    AudioManager.i.play(SfxId.levelUp);
  }
  
  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.ok:
      case Input.cancel:
        _nextLevel();
        return true;
    }
    
    return false;
  }
  
  void _nextLevel() {
    // Award skill points for this level-up
    var skillPointsGained = Option.skillPointsPerLevel;
    
    // For now, award skill points to discovered skills randomly
    // In a full implementation, this could be a choice system
    var discoveredSkills = hero.skills.discovered.toList();
    if (discoveredSkills.isNotEmpty) {
      var skill = rng.item(discoveredSkills);
      hero.skills.earnPoints(skill, hero.skills.points(skill) + skillPointsGained);
      hero.log.gain('You gained $skillPointsGained skill points in ${skill.name}!');
    } else {
      hero.log.gain('You gained $skillPointsGained skill points!');
    }
    
    currentLevel++;
    
    if (currentLevel >= pendingLevels) {
      // All level-ups processed, return to game
      ui.pop();
    } else {
      dirty();
    }
  }
  
  @override
  void render(Terminal terminal) {
    terminal.clear();
    
    var currentLevelNum = hero.level - pendingLevels + currentLevel + 1;
    
    // Header
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height);
    terminal.writeAt(
      (terminal.width - 12) ~/ 2, 
      2, 
      "LEVEL UP!", 
      gold
    );
    
    terminal.writeAt(
      (terminal.width - 20) ~/ 2, 
      4, 
      "You reached level $currentLevelNum!", 
      lightWarmGray
    );
    
    terminal.writeAt(
      (terminal.width - 35) ~/ 2, 
      6, 
      "You gain ${Option.skillPointsPerLevel} skill points!", 
      aqua
    );
    
    // Show current skills
    var discoveredSkills = hero.skills.discovered.toList();
    if (discoveredSkills.isNotEmpty) {
      terminal.writeAt(
        (terminal.width - 20) ~/ 2, 
        8, 
        "Your discovered skills:", 
        ash
      );
      
      var startY = 10;
      for (var i = 0; i < discoveredSkills.length && i < 8; i++) {
        var skill = discoveredSkills[i];
        var level = skill.calculateLevel(hero);
        terminal.writeAt(
          (terminal.width - 30) ~/ 2, 
          startY + i, 
          "${skill.name} (Level $level)", 
          lightWarmGray
        );
      }
    }
    
    // Progress indicator
    if (pendingLevels > 1) {
      terminal.writeAt(
        (terminal.width - 20) ~/ 2, 
        terminal.height - 6, 
        "Level ${currentLevel + 1} of $pendingLevels", 
        ash
      );
    }
    
    // Instructions
    terminal.writeAt(
      (terminal.width - 20) ~/ 2, 
      terminal.height - 4, 
      "Press any key to continue", 
      darkWarmGray
    );
  }
}
