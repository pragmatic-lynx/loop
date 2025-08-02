# Implementation Plan

- [ ] 1. Create core achievement data structures
  - Implement GlobalAchievements class with item/weapon/enemy tracking sets
  - Create AchievementStats data class for UI display
  - Add item categorization helper methods to distinguish weapons from other items
  - _Requirements: 3.1, 3.2, 5.1, 5.2_

- [ ] 2. Implement AchievementTracker service
  - Create static service class for managing global achievement state
  - Add methods for tracking item pickups and enemy kills
  - Implement data validation and content verification
  - _Requirements: 4.1, 4.2, 4.4_

- [ ] 3. Integrate achievement tracking with existing hero actions
  - Modify Hero.pickUp() method to call AchievementTracker.trackItemFound()
  - Modify Hero.onKilled() method to call AchievementTracker.trackEnemySlain()
  - Ensure tracking occurs after lore updates to maintain existing functionality
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 4. Extend storage system for global achievements persistence
  - Modify Storage class to include globalAchievements field
  - Add serialization methods for achievement data in save() method
  - Add deserialization methods for achievement data in _load() method
  - Handle migration for existing saves without achievement data
  - _Requirements: 3.3, 3.4, 3.5_

- [ ] 5. Create main menu achievement display widget
  - Add achievement counters to MainMenuScreen showing "X out of Y" format
  - Position counters appropriately within existing main menu layout
  - Update counters when achievement data changes
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 6. Implement detailed achievements screen
  - Create new AchievementsScreen class extending Screen<Input>
  - Add navigation from main menu using designated key press
  - Implement tabbed or sectioned view for weapons/items/enemies
  - Display collected vs uncollected items with clear visual indicators
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 7. Add keyboard navigation and input handling
  - Implement key binding in MainMenuScreen to open achievements screen
  - Add input handling in AchievementsScreen for navigation and closing
  - Update help text to show new achievement key binding
  - _Requirements: 2.1_

- [ ] 8. Create unit tests for achievement system
  - Write tests for GlobalAchievements class methods
  - Write tests for AchievementTracker service functionality
  - Write tests for storage serialization/deserialization
  - Write tests for item categorization logic
  - _Requirements: 4.4, 5.1_

- [ ] 9. Add error handling and data validation
  - Implement graceful handling of corrupted achievement data
  - Add validation for item/enemy names against content definitions
  - Handle storage failures with appropriate fallbacks
  - Add error recovery for missing or invalid achievement data
  - _Requirements: 3.3, 3.4_

- [ ] 10. Polish UI and integrate with existing game styling
  - Apply consistent styling to match existing game UI
  - Add appropriate colors and formatting for achievement displays
  - Ensure proper text wrapping and layout for different screen sizes
  - Test and refine visual presentation
  - _Requirements: 1.1, 2.3, 2.4_