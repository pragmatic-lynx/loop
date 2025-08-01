# Implementation Plan

- [x] 1. Create core archetype and scheduling infrastructure





  - Create `LevelArchetype` enum with COMBAT, LOOT, BOSS values
  - Implement `DensityScalars` class for enemy/item multipliers
  - Build `DifficultyScheduler` class with configurable schedule cycling
  - _Requirements: 1.1, 2.1, 2.3, 3.4_

- [x] 2. Integrate archetype system with level generation





  - [x] 2.1 Modify LoopManager to use DifficultyScheduler


    - Add scheduler instance to LoopManager
    - Update level creation to get current archetype and scalars
    - Pass archetype metadata to game generation
    - _Requirements: 1.2, 2.1, 2.2_



  - [x] 2.2 Extend Architect class to accept density scalars





    - Add optional scalars parameter to buildStage method
    - Modify ArchitecturalStyle.pick() to apply enemy/item multipliers
    - Ensure scalars are applied during decoration phase
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 3. Implement archetype metadata tracking






  - [ ] 3.1 Create ArchetypeMetadata class
    - Store archetype, scalars, and loop number
    - Add serialization methods for logging


    - _Requirements: 1.2, 4.2_

  - [ ] 3.2 Add metadata to Game class
    - Store current level's archetype metadata
    - Make metadata accessible for logging and debugging
    - _Requirements: 1.2, 1.3_

- [ ] 4. Build reward choice logging system
  - [ ] 4.1 Create RewardChoiceLog class
    - Define data structure for loop, archetype, choice tracking
    - Implement CSV serialization methods
    - _Requirements: 4.1, 4.2_

  - [ ] 4.2 Integrate logging with LoopRewardScreen
    - Capture reward selections with archetype context
    - Write log entries to CSV file
    - Ensure data persistence across sessions
    - _Requirements: 4.1, 4.3_

- [ ] 5. Implement runtime tuning console
  - [ ] 5.1 Create TuningOverlay UI component
    - Build overlay panel showing current scalars
    - Handle keyboard input for scalar adjustments
    - Display archetype-specific multipliers
    - _Requirements: 5.1, 5.4_

  - [ ] 5.2 Integrate tuning overlay with LoopGameScreen
    - Add tilde key handler to show/hide overlay
    - Implement arrow key handlers for ±10% adjustments
    - Apply scalar changes to scheduler in real-time
    - _Requirements: 5.1, 5.2, 5.3_

- [ ] 6. Build metrics snapshot system
  - [ ] 6.1 Create MetricsCollector class
    - Track loop progress, deaths, turn times, damage stats
    - Implement JSON serialization for metrics data
    - _Requirements: 6.2, 6.3_

  - [ ] 6.2 Add F5 metrics capture to LoopGameScreen
    - Handle F5 key press to trigger metrics dump
    - Output formatted JSON to game log
    - Include current archetype in metrics snapshot
    - _Requirements: 6.1, 6.2, 6.3_

- [ ] 7. Add debugging and logging enhancements
  - Enhance existing log messages to include archetype information
  - Add debug output for scheduler state changes
  - Implement archetype display in game UI for testing
  - _Requirements: 1.3, 2.4_

- [ ] 8. Create default configuration and testing
  - Set up default [COMBAT, COMBAT, LOOT] schedule
  - Initialize default density scalars (100% for all archetypes)
  - Add validation and error handling for edge cases
  - _Requirements: 2.3, 3.4_