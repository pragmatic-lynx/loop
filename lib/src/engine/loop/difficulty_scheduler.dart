import 'density_scalars.dart';
import 'level_archetype.dart';

/// Manages the scheduling of level archetypes and their associated difficulty scalars
class DifficultyScheduler {
  /// The repeating schedule of level archetypes
  List<LevelArchetype> schedule;
  
  /// Density scalars for each archetype type
  Map<LevelArchetype, DensityScalars> scalars;

  DifficultyScheduler({
    List<LevelArchetype>? schedule,
    Map<LevelArchetype, DensityScalars>? scalars,
  }) : schedule = schedule ?? _defaultSchedule(),
       scalars = scalars ?? _defaultScalars();

  /// Default schedule: [COMBAT, COMBAT, LOOT]
  static List<LevelArchetype> _defaultSchedule() {
    return [
      LevelArchetype.combat,
      LevelArchetype.combat,
      LevelArchetype.loot,
    ];
  }

  /// Default scalars: 100% for all archetypes
  static Map<LevelArchetype, DensityScalars> _defaultScalars() {
    return {
      LevelArchetype.combat: DensityScalars(),
      LevelArchetype.loot: DensityScalars(),
      LevelArchetype.boss: DensityScalars(),
    };
  }

  /// Get the archetype for the given loop index (0-based)
  LevelArchetype getNextArchetype(int loopIndex) {
    if (schedule.isEmpty) {
      return LevelArchetype.combat; // Fallback
    }
    return schedule[loopIndex % schedule.length];
  }

  /// Get the density scalars for the given archetype
  DensityScalars getScalars(LevelArchetype archetype) {
    return scalars[archetype] ?? DensityScalars();
  }

  /// Update the scalars for a specific archetype
  void updateScalars(LevelArchetype archetype, double enemyMultiplier, double itemMultiplier) {
    // Validate inputs
    if (enemyMultiplier < 0.1 || enemyMultiplier > 5.0) {
      print('Warning: Enemy multiplier $enemyMultiplier is outside valid range [0.1, 5.0], clamping.');
      enemyMultiplier = enemyMultiplier.clamp(0.1, 5.0);
    }
    if (itemMultiplier < 0.1 || itemMultiplier > 5.0) {
      print('Warning: Item multiplier $itemMultiplier is outside valid range [0.1, 5.0], clamping.');
      itemMultiplier = itemMultiplier.clamp(0.1, 5.0);
    }
    
    scalars[archetype] = DensityScalars(
      enemyMultiplier: enemyMultiplier,
      itemMultiplier: itemMultiplier,
    );
    
    print('SCALARS_UPDATED: ${archetype.name} - Enemy: ${enemyMultiplier}x, Item: ${itemMultiplier}x');
  }

  /// Update just the enemy multiplier for an archetype
  void updateEnemyMultiplier(LevelArchetype archetype, double multiplier) {
    // Validate input
    if (multiplier < 0.1 || multiplier > 5.0) {
      print('Warning: Enemy multiplier $multiplier is outside valid range [0.1, 5.0], clamping.');
      multiplier = multiplier.clamp(0.1, 5.0);
    }
    
    var current = scalars[archetype] ?? DensityScalars();
    scalars[archetype] = current.copyWith(enemyMultiplier: multiplier);
    
    print('ENEMY_SCALAR_UPDATED: ${archetype.name} - ${multiplier}x');
  }

  /// Update just the item multiplier for an archetype
  void updateItemMultiplier(LevelArchetype archetype, double multiplier) {
    // Validate input
    if (multiplier < 0.1 || multiplier > 5.0) {
      print('Warning: Item multiplier $multiplier is outside valid range [0.1, 5.0], clamping.');
      multiplier = multiplier.clamp(0.1, 5.0);
    }
    
    var current = scalars[archetype] ?? DensityScalars();
    scalars[archetype] = current.copyWith(itemMultiplier: multiplier);
    
    print('ITEM_SCALAR_UPDATED: ${archetype.name} - ${multiplier}x');
  }

  /// Get current status for debugging
  Map<String, dynamic> getStatus() {
    return {
      'schedule': schedule.map((a) => a.name).toList(),
      'scalars': scalars.map((key, value) => MapEntry(
        key.name,
        {
          'enemy': value.enemyMultiplier,
          'item': value.itemMultiplier,
        },
      )),
    };
  }

  @override
  String toString() {
    var scheduleStr = schedule.map((a) => a.name).join(', ');
    return 'DifficultyScheduler(schedule: [$scheduleStr], scalars: $scalars)';
  }
}