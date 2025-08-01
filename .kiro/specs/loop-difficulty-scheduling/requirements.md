# Requirements Document

## Introduction

The Loop Difficulty Scheduling System provides structured difficulty progression and level variety for the roguelite loop mode. It tags each generated level with an archetype (COMBAT, LOOT, BOSS), applies configurable difficulty scalars, and provides debugging tools for tuning the game balance during the 3-day jam.

## Requirements

### Requirement 1

**User Story:** As a game designer, I want each generated level to be tagged with an archetype, so that the loop system knows what type of content was spawned.

#### Acceptance Criteria

1. WHEN a level is generated THEN the system SHALL assign one of three archetypes: COMBAT, LOOT, or BOSS
2. WHEN level generation completes THEN the archetype metadata SHALL be available to the loop manager
3. WHEN debugging THEN the current level archetype SHALL be visible in logs

### Requirement 2

**User Story:** As a game designer, I want a configurable difficulty schedule, so that I can control the pacing and variety of level types.

#### Acceptance Criteria

1. WHEN starting a new loop THEN the system SHALL follow a predefined schedule of level archetypes
2. WHEN the schedule reaches the end THEN it SHALL cycle back to the beginning
3. WHEN configuring the schedule THEN it SHALL default to [COMBAT, COMBAT, LOOT] pattern
4. WHEN the schedule is modified THEN changes SHALL take effect on the next loop

### Requirement 3

**User Story:** As a game designer, I want density scalars for enemies and items, so that every level feels appropriately challenging and rewarding.

#### Acceptance Criteria

1. WHEN generating a COMBAT level THEN enemy density SHALL be scaled by the combat multiplier
2. WHEN generating a LOOT level THEN item density SHALL be scaled by the loot multiplier  
3. WHEN generating a BOSS level THEN enemy density SHALL be scaled by the boss multiplier
4. WHEN scalars are not specified THEN they SHALL default to 100%

### Requirement 4

**User Story:** As a game developer, I want reward choice logging, so that I can analyze player preferences and balance rewards.

#### Acceptance Criteria

1. WHEN a player selects a reward THEN the system SHALL log the loop number, level archetype, and choice ID
2. WHEN logging reward choices THEN data SHALL be written to a CSV format
3. WHEN the game session ends THEN all logged data SHALL be preserved

### Requirement 5

**User Story:** As a game developer, I want a runtime tuning console, so that I can adjust difficulty scalars during gameplay testing.

#### Acceptance Criteria

1. WHEN the tilde key (~) is pressed THEN a tuning overlay SHALL appear
2. WHEN the overlay is active THEN arrow keys SHALL adjust scalars by ±10%
3. WHEN scalars are modified THEN changes SHALL apply to the next generated level
4. WHEN the overlay is closed THEN current scalar values SHALL be displayed in the UI

### Requirement 6

**User Story:** As a game developer, I want simple keypress, so that I can quickly capture data during testing - {loop, deaths, avgTurnTime, dmgDealt, dmgTaken} for example

#### Acceptance Criteria

1. WHEN F5 is pressed THEN the system SHALL dump current metrics to the log
2. WHEN metrics are captured THEN they SHALL include loop number, deaths, average turn time, damage dealt, and damage taken
3. WHEN metrics are logged THEN they SHALL be in JSON format for easy parsing
