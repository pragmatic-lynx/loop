import 'package:malison/malison.dart';

import '../engine/loop/difficulty_scheduler.dart';
import '../engine/loop/level_archetype.dart';
import '../hues.dart';
import 'draw.dart';
import 'panel/panel.dart';

/// Overlay panel for runtime tuning of difficulty scalars
class TuningOverlay extends Panel {
  final DifficultyScheduler scheduler;
  LevelArchetype _selectedArchetype = LevelArchetype.combat;
  bool _editingEnemy = true; // true for enemy, false for item

  TuningOverlay(this.scheduler);

  /// Handle arrow key input for scalar adjustments
  bool handleArrowKey(String direction) {
    var archetype = _selectedArchetype;
    var scalars = scheduler.getScalars(archetype);
    var currentValue = _editingEnemy ? scalars.enemyMultiplier : scalars.itemMultiplier;
    
    double newValue;
    switch (direction) {
      case 'up':
        newValue = (currentValue * 1.1).clamp(0.1, 5.0);
      case 'down':
        newValue = (currentValue * 0.9).clamp(0.1, 5.0);
      case 'left':
        // Switch between enemy/item editing
        _editingEnemy = !_editingEnemy;
        return true;
      case 'right':
        // Switch between enemy/item editing
        _editingEnemy = !_editingEnemy;
        return true;
      default:
        return false;
    }

    // Apply the change
    if (_editingEnemy) {
      scheduler.updateEnemyMultiplier(archetype, newValue);
    } else {
      scheduler.updateItemMultiplier(archetype, newValue);
    }
    
    return true;
  }

  /// Handle tab key to switch between archetypes
  bool handleTab() {
    var archetypes = LevelArchetype.values;
    var currentIndex = archetypes.indexOf(_selectedArchetype);
    _selectedArchetype = archetypes[(currentIndex + 1) % archetypes.length];
    return true;
  }

  @override
  void renderPanel(Terminal terminal) {
    var width = 40;
    var height = 12;
    var x = (terminal.width - width) ~/ 2;
    var y = (terminal.height - height) ~/ 2;

    // Draw background
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        terminal.writeAt(x + dx, y + dy, " ", ash, darkerCoolGray);
      }
    }

    // Draw frame
    Draw.frame(terminal, x, y, width, height, label: "TUNING OVERLAY");

    var row = y + 2;
    
    // Instructions
    terminal.writeAt(x + 2, row, "Tab: Switch Archetype", lightWarmGray);
    terminal.writeAt(x + 2, row + 1, "←→: Switch Enemy/Item", lightWarmGray);
    terminal.writeAt(x + 2, row + 2, "↑↓: Adjust ±10%", lightWarmGray);
    terminal.writeAt(x + 2, row + 3, "~: Close", lightWarmGray);
    
    row += 5;

    // Current archetype header
    var archetypeColor = _getArchetypeColor(_selectedArchetype);
    terminal.writeAt(x + 2, row, "Current: ${_selectedArchetype.name}", archetypeColor);
    row += 2;

    // Display scalars for current archetype
    var scalars = scheduler.getScalars(_selectedArchetype);
    
    // Enemy multiplier
    var enemyColor = _editingEnemy ? yellow : lightWarmGray;
    var enemyPrefix = _editingEnemy ? "► " : "  ";
    var enemyText = "${enemyPrefix}Enemy: ${(scalars.enemyMultiplier * 100).round()}%";
    terminal.writeAt(x + 2, row, enemyText, enemyColor);
    
    // Item multiplier
    var itemColor = !_editingEnemy ? yellow : lightWarmGray;
    var itemPrefix = !_editingEnemy ? "► " : "  ";
    var itemText = "${itemPrefix}Item:  ${(scalars.itemMultiplier * 100).round()}%";
    terminal.writeAt(x + 2, row + 1, itemText, itemColor);
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
}