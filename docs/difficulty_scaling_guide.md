# Difficulty Scaling and Spawn Rate Guide

This guide explains how to use the difficulty scheduling system to adjust enemy spawn rates and item (including spells) density in the game.

## Table of Contents
1. [Overview](#overview)
2. [Key Components](#key-components)
   - [Level Archetypes](#level-archetypes)
   - [Density Scalars](#density-scalars)
   - [Difficulty Scheduler](#difficulty-scheduler)
3. [Adjusting Spawn Rates](#adjusting-spawn-rates)
   - [Using the Tuning Overlay](#using-the-tuning-overlay)
   - [Programmatic Adjustments](#programmatic-adjustments)
4. [Advanced Configuration](#advanced-configuration)
   - [Custom Schedules](#custom-schedules)
   - [Per-Archetype Scaling](#per-archetype-scaling)
5. [Troubleshooting](#troubleshooting)

## Overview

The difficulty scheduling system allows you to control:
- Enemy spawn rates
- Item and spell drop rates
- The sequence of level types (combat, loot, boss)
- Difficulty progression over time

## Key Components

### Level Archetypes

There are three main level archetypes:
1. **COMBAT**: Focused on enemy encounters
2. **LOOT**: Focused on finding items and spells
3. **BOSS**: Special levels with boss encounters

### Density Scalars

Density scalars control the multiplier for spawn rates:
- `enemyMultiplier`: Affects enemy spawn rates (0.1x to 5.0x)
- `itemMultiplier`: Affects item and spell spawn rates (0.1x to 5.0x)

### Difficulty Scheduler

The `DifficultyScheduler` class manages:
- The sequence of level archetypes
- Density scalars for each archetype
- Progression through the game loop

## Adjusting Spawn Rates

### Using the Tuning Overlay

1. Press `~` (tilde) during gameplay to open the tuning overlay
2. Use `TAB` to cycle between archetypes (COMBAT, LOOT, BOSS)
3. Use `UP`/`DOWN` arrows to adjust the selected multiplier
4. Use `LEFT`/`RIGHT` to switch between enemy and item multipliers
5. Changes take effect in the next generated level

Example values for more intense gameplay:
- Combat levels: 2.5x enemies, 1.0x items
- Loot levels: 0.5x enemies, 3.0x items
- Boss levels: 1.5x enemies, 2.0x items

### Programmatic Adjustments

You can modify spawn rates in code:

```dart
// Get the scheduler instance (e.g., from your game state)
final scheduler = game.loopManager.scheduler;

// Increase enemy spawn rate for combat levels
scheduler.updateEnemyMultiplier(LevelArchetype.combat, 2.5);

// Increase item/spell drop rate for loot levels
scheduler.updateItemMultiplier(LevelArchetype.loot, 3.0);

// Update both at once for boss levels
scheduler.updateScalars(
  LevelArchetype.boss,
  enemyMultiplier: 1.5,
  itemMultiplier: 2.0,
);
```

## Advanced Configuration

### Custom Schedules

You can define custom level sequences:

```dart
final customSchedule = [
  LevelArchetype.combat,
  LevelArchetype.combat,
  LevelArchetype.loot,
  LevelArchetype.combat,
  LevelArchetype.boss,
];

final scheduler = DifficultyScheduler(
  schedule: customSchedule,
  scalars: {
    LevelArchetype.combat: DensityScalars(enemyMultiplier: 2.0, itemMultiplier: 0.5),
    LevelArchetype.loot: DensityScalars(enemyMultiplier: 0.5, itemMultiplier: 3.0),
    LevelArchetype.boss: DensityScalars(enemyMultiplier: 1.5, itemMultiplier: 1.5),
  },
);
```

### Per-Archetype Scaling

You can scale difficulty based on the current loop:

```dart
void onNewLevel(int loopNumber) {
  final baseMultiplier = 1.0 + (loopNumber * 0.1); // 10% increase per loop
  
  scheduler.updateScalars(
    LevelArchetype.combat,
    enemyMultiplier: baseMultiplier * 1.5,
    itemMultiplier: baseMultiplier * 0.8,
  );
  
  // Keep loot levels relatively safe but rewarding
  scheduler.updateScalars(
    LevelArchetype.loot,
    enemyMultiplier: baseMultiplier * 0.5,
    itemMultiplier: baseMultiplier * 1.2,
  );
}
```

## Troubleshooting

### Common Issues

1. **Changes not taking effect**
   - Ensure you're modifying the scheduler before level generation
   - Check that the correct archetype is selected in the tuning overlay

2. **Performance problems with high spawn rates**
   - The system caps multipliers at 5.0x for stability
   - Consider reducing the base spawn rates if you need higher densities

3. **Unbalanced gameplay**
   - Start with small adjustments (0.2-0.5 increments)
   - Monitor player experience and adjust accordingly

### Debugging

To check current settings:

```dart
final status = scheduler.getStatus();
print('Current schedule: ${status['schedule']}');
print('Current scalars: ${status['scalars']}');
```

## Conclusion

The difficulty scheduling system provides flexible control over enemy and item spawn rates. By adjusting these values, you can create a wide range of gameplay experiences, from relaxed exploration to intense combat challenges.
