# Design Document

## Overview

The Loop Difficulty Scheduling System extends the existing `LoopManager` and `Architect` classes to provide structured level variety and difficulty scaling. It introduces level archetypes, configurable scheduling, density multipliers, and debugging tools while maintaining compatibility with the existing dungeon generation pipeline.

## Architecture

### Core Components

1. **LevelArchetype Enum**: Defines COMBAT, LOOT, BOSS level types
2. **DifficultyScheduler**: Manages archetype scheduling and density scalars
3. **ArchetypeMetadata**: Carries archetype info through the generation pipeline
4. **TuningOverlay**: Runtime debugging interface
5. **MetricsCollector**: Performance data capture system

### Integration Points

- `LoopManager`: Extended with scheduler and metrics
- `Architect.buildStage()`: Modified to accept and apply density scalars
- `ArchitecturalStyle.pick()`: Enhanced to consider archetype requirements
- `LoopGameScreen`: Handles tuning overlay and metrics hotkeys

## Components and Interfaces

### LevelArchetype Enum
```dart
enum LevelArchetype {
  combat('COMBAT'),
  loot('LOOT'), 
  boss('BOSS');
  
  const LevelArchetype(this.name);
  final String name;
}
```

### DifficultyScheduler Class
```dart
class DifficultyScheduler {
  List<LevelArchetype> schedule;
  Map<LevelArchetype, DensityScalars> scalars;
  
  LevelArchetype getNextArchetype(int loopIndex);
  DensityScalars getScalars(LevelArchetype archetype);
  void updateScalars(LevelArchetype archetype, double enemyMultiplier, double itemMultiplier);
}
```

### DensityScalars Class
```dart
class DensityScalars {
  double enemyMultiplier;
  double itemMultiplier;
  
  DensityScalars({this.enemyMultiplier = 1.0, this.itemMultiplier = 1.0});
}
```

### ArchetypeMetadata Class
```dart
class ArchetypeMetadata {
  LevelArchetype archetype;
  DensityScalars scalars;
  int loopNumber;
  
  ArchetypeMetadata(this.archetype, this.scalars, this.loopNumber);
}
```

## Data Models

### Reward Choice Log Entry
```dart
class RewardChoiceLog {
  int loopNumber;
  LevelArchetype archetype;
  String choiceId;
  DateTime timestamp;
}
```

### Metrics Snapshot
```dart
class MetricsSnapshot {
  int loop;
  int deaths;
  double avgTurnTime;
  int dmgDealt;
  int dmgTaken;
  DateTime timestamp;
}
```

## Error Handling

- **Invalid Archetype**: Falls back to COMBAT archetype
- **Missing Scalars**: Uses default 1.0 multipliers
- **Schedule Empty**: Uses default [COMBAT, COMBAT, LOOT] pattern
- **File I/O Errors**: Logs errors but continues execution
- **Overlay Rendering**: Gracefully handles terminal size constraints

## Testing Strategy

### Manual
- Generate 10 levels and verify archetype distribution matches schedule
- Adjust scalars via overlay and confirm next level reflects changes
- Press F5 and verify metrics JSON format in logs
- Test CSV logging of reward choices across multiple loops
