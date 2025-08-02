# Requirements Document

## Introduction

This feature implements a global achievements system that tracks player progress across all heroes and game sessions. The system will display collection progress for weapons, items, and enemies on the main menu, with detailed views showing what remains to be collected. This builds upon the existing Lore system but aggregates data globally rather than per-hero.

## Requirements

### Requirement 1

**User Story:** As a player, I want to see my global collection progress on the main menu, so that I can quickly understand my overall game completion status.

#### Acceptance Criteria

1. WHEN the main menu is displayed THEN the system SHALL show collection counters for weapons, items, and enemies
2. WHEN displaying counters THEN the system SHALL show format "X out of Y" for each category
3. WHEN no progress exists THEN the system SHALL show "0 out of [total]" for each category

### Requirement 2

**User Story:** As a player, I want to access detailed achievement information, so that I can see exactly which items or enemies I still need to find.

#### Acceptance Criteria

1. WHEN I press a designated key on the main menu THEN the system SHALL open a detailed achievements screen
2. WHEN the detailed screen is open THEN the system SHALL show separate tabs or sections for weapons, items, and enemies
3. WHEN viewing detailed lists THEN the system SHALL clearly indicate which items are collected vs uncollected
4. WHEN viewing detailed lists THEN the system SHALL show item names and basic information

### Requirement 3

**User Story:** As a player, I want my achievements to persist across all heroes and game sessions, so that my progress is never lost regardless of which character I play.

#### Acceptance Criteria

1. WHEN any hero picks up an item THEN the system SHALL record it in global achievements
2. WHEN any hero kills an enemy THEN the system SHALL record it in global achievements  
3. WHEN the game is saved THEN the system SHALL persist global achievement data
4. WHEN the game is loaded THEN the system SHALL restore global achievement data
5. WHEN switching between heroes THEN the system SHALL maintain the same global achievement progress

### Requirement 4

**User Story:** As a player, I want the achievement system to automatically track my progress without manual intervention, so that I can focus on playing the game.

#### Acceptance Criteria

1. WHEN an item is picked up during gameplay THEN the system SHALL automatically update global achievements
2. WHEN an enemy is killed during gameplay THEN the system SHALL automatically update global achievements
3. WHEN tracking occurs THEN the system SHALL not interrupt or slow down gameplay
4. WHEN items are found multiple times THEN the system SHALL only count unique discoveries

### Requirement 5

**User Story:** As a player, I want to distinguish between different types of collectibles, so that I can focus on specific collection goals.

#### Acceptance Criteria

1. WHEN categorizing items THEN the system SHALL separate weapons from other items
2. WHEN displaying progress THEN the system SHALL show separate counters for weapons, items, and enemies
3. WHEN viewing detailed lists THEN the system SHALL group items by their appropriate category
4. WHEN an item fits multiple categories THEN the system SHALL count it in the most specific category