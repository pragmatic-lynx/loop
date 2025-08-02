# Implementation Plan

- [ ] 1. Create core achievement system



  - Implement GlobalAchievements class with item/weapon/enemy tracking sets
  - Create AchievementTracker service for managing global state
  - Add item categorization to distinguish weapons from other items
  - _Requirements: 3.1, 3.2, 4.1, 4.2, 5.1, 5.2_

- [ ] 2. Integrate with existing hero actions
  - Modify Hero.pickUp() method to call achievement tracking
  - Modify Hero.onKilled() method to track enemy kills globally
  - Ensure tracking works alongside existing lore system
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 3. Extend storage system for persistence
  - Add globalAchievements field to Storage class
  - Implement save/load methods for achievement data
  - Handle migration for existing saves without achievements
  - _Requirements: 3.3, 3.4, 3.5_

- [ ] 4. Add main menu achievement display
  - Show "X out of Y" counters for weapons, items, and enemies
  - Position within existing main menu layout
  - Update display when achievements change
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 5. Create detailed achievements screen
  - Implement AchievementsScreen with navigation from main menu
  - Show separate sections for weapons, items, and enemies
  - Display collected vs uncollected with clear visual indicators
  - Add keyboard navigation and help text
  - _Requirements: 2.1, 2.2, 2.3, 2.4_

- [ ] 6. Add error handling and polish
  - Handle corrupted data and storage failures gracefully
  - Apply consistent UI styling to match game theme
  - Validate achievement data against current content
  - _Requirements: 3.3, 3.4_