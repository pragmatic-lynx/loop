# Implementation Plan

- [-] 1. Create WorldStateManager class with basic serialization



  - Create `lib/src/engine/core/world_state_manager.dart` file
  - Implement `saveWorldState()` method to serialize Game object to JSON
  - Implement basic stage serialization including tiles, dimensions, and metadata
  - Write unit tests for basic serialization functionality
  - _Requirements: 1.1, 1.2_

- [ ] 2. Implement stage data serialization
  - Add tile serialization methods to WorldStateManager
  - Implement item position and inventory serialization for stage items
  - Add actor serialization for monsters and hero position
  - Create helper methods for Vec position serialization
  - Write tests for stage serialization round-trip accuracy
  - _Requirements: 1.1, 1.2_

- [ ] 3. Implement hero state integration
  - Integrate existing HeroSave serialization with world state
  - Add hero position and current health to world state data
  - Ensure hero inventory and equipment are included in serialization
  - Handle hero-specific state that differs from HeroSave
  - Write tests for hero state serialization
  - _Requirements: 1.2_

- [ ] 4. Create world state deserialization
  - Implement `loadWorldState()` method in WorldStateManager
  - Add tile deserialization and Stage reconstruction
  - Implement item placement from serialized data
  - Add actor spawning from serialized monster data
  - Create Game object reconstruction with loaded Stage and Hero
  - Write tests for deserialization accuracy
  - _Requirements: 3.2, 3.3_

- [ ] 5. Implement WorldStateValidator class
  - Create `lib/src/engine/core/world_state_validator.dart` file
  - Implement schema validation for JSON structure
  - Add content validation for item types, breeds, and tile references
  - Create logical validation for hero position and stage bounds
  - Implement ValidationResult class with errors and warnings
  - Write comprehensive validation tests
  - _Requirements: 3.4, 4.2_

- [ ] 6. Add error handling and recovery
  - Implement graceful degradation for missing content references
  - Add default substitution for invalid items and actors
  - Create detailed error messages for validation failures
  - Add warning system for non-critical issues
  - Write tests for error recovery scenarios
  - _Requirements: 2.3, 3.4, 4.2_

- [ ] 7. Extend Storage class with world state methods
  - Add `saveWorldStateToFile()` method to Storage class
  - Implement `loadWorldStateFromFile()` method
  - Add browser-compatible file download functionality
  - Implement file input handling for loading
  - Create fallback text-based copy/paste interface
  - Write integration tests with existing Storage functionality
  - _Requirements: 1.4, 3.1, 3.5_

- [ ] 8. Create LevelEditorUI component
  - Create `lib/src/ui/level_editor_ui.dart` file
  - Implement save dialog with filename input and download trigger
  - Add load dialog with file input and validation feedback
  - Create progress indicators for file operations
  - Add success/error message display
  - Write UI component tests
  - _Requirements: 1.4, 3.1, 3.5_

- [ ] 9. Integrate level editor UI with game menus
  - Add "Save World State" menu option to debug/development menus
  - Add "Load World State" menu option with file selection
  - Implement menu callbacks to trigger WorldStateManager operations
  - Add keyboard shortcuts for quick save/load operations
  - Ensure UI integration works with existing menu systems
  - Write integration tests for menu functionality
  - _Requirements: 1.4, 3.1_

- [ ] 10. Modify Game constructor for custom world loading
  - Update Game constructor to accept optional pre-built Stage parameter
  - Add alternative constructor path that skips procedural generation
  - Ensure hero initialization works with loaded world state
  - Maintain compatibility with existing Game creation workflows
  - Write tests for both generation and loading paths
  - _Requirements: 3.2, 4.1_

- [ ] 11. Add comprehensive integration tests
  - Create end-to-end tests for save/load workflow
  - Test game mechanics functionality with loaded worlds
  - Verify existing save/load systems work with custom levels
  - Add performance tests for large world state files
  - Create regression tests for edge cases and error conditions
  - _Requirements: 4.1, 4.3_

- [ ] 12. Implement file format versioning and migration
  - Add version field to world state JSON format
  - Create migration system for future format changes
  - Implement backward compatibility checks
  - Add version validation in WorldStateValidator
  - Write tests for version handling and migration
  - _Requirements: 3.4, 4.2_