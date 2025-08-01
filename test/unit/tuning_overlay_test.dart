import 'package:test/test.dart';
import '../../lib/src/engine/loop/difficulty_scheduler.dart';
import '../../lib/src/engine/loop/level_archetype.dart';
import '../../lib/src/ui/tuning_overlay.dart';

void main() {
  group('TuningOverlay', () {
    late DifficultyScheduler scheduler;
    late TuningOverlay overlay;

    setUp(() {
      scheduler = DifficultyScheduler();
      overlay = TuningOverlay(scheduler);
    });

    test('should handle arrow key adjustments', () {
      // Initial values should be 1.0 (100%)
      var initialScalars = scheduler.getScalars(LevelArchetype.combat);
      expect(initialScalars.enemyMultiplier, equals(1.0));
      expect(initialScalars.itemMultiplier, equals(1.0));

      // Test up arrow increases enemy multiplier by 10%
      var handled = overlay.handleArrowKey('up');
      expect(handled, isTrue);
      
      var updatedScalars = scheduler.getScalars(LevelArchetype.combat);
      expect(updatedScalars.enemyMultiplier, closeTo(1.1, 0.01));
      expect(updatedScalars.itemMultiplier, equals(1.0)); // Should remain unchanged

      // Test down arrow decreases enemy multiplier by 10%
      overlay.handleArrowKey('down');
      updatedScalars = scheduler.getScalars(LevelArchetype.combat);
      expect(updatedScalars.enemyMultiplier, closeTo(1.0, 0.01)); // Back to original
    });

    test('should switch between enemy and item editing', () {
      // Start with enemy editing (default)
      overlay.handleArrowKey('up'); // Increase enemy multiplier
      var scalars = scheduler.getScalars(LevelArchetype.combat);
      expect(scalars.enemyMultiplier, closeTo(1.1, 0.01));
      expect(scalars.itemMultiplier, equals(1.0));

      // Switch to item editing
      overlay.handleArrowKey('left');
      overlay.handleArrowKey('up'); // Should now increase item multiplier
      scalars = scheduler.getScalars(LevelArchetype.combat);
      expect(scalars.enemyMultiplier, closeTo(1.1, 0.01)); // Unchanged
      expect(scalars.itemMultiplier, closeTo(1.1, 0.01)); // Now increased
    });

    test('should cycle through archetypes with tab', () {
      // Start with combat archetype (default)
      overlay.handleArrowKey('up'); // Modify combat archetype
      var combatScalars = scheduler.getScalars(LevelArchetype.combat);
      expect(combatScalars.enemyMultiplier, closeTo(1.1, 0.01));

      // Switch to loot archetype
      overlay.handleTab();
      overlay.handleArrowKey('up'); // Modify loot archetype
      var lootScalars = scheduler.getScalars(LevelArchetype.loot);
      expect(lootScalars.enemyMultiplier, closeTo(1.1, 0.01));
      
      // Combat archetype should be unchanged
      combatScalars = scheduler.getScalars(LevelArchetype.combat);
      expect(combatScalars.enemyMultiplier, closeTo(1.1, 0.01));
    });

    test('should clamp values between 0.1 and 5.0', () {
      // Test upper bound
      for (var i = 0; i < 20; i++) {
        overlay.handleArrowKey('up');
      }
      var scalars = scheduler.getScalars(LevelArchetype.combat);
      expect(scalars.enemyMultiplier, lessThanOrEqualTo(5.0));

      // Test lower bound
      for (var i = 0; i < 50; i++) {
        overlay.handleArrowKey('down');
      }
      scalars = scheduler.getScalars(LevelArchetype.combat);
      expect(scalars.enemyMultiplier, greaterThanOrEqualTo(0.1));
    });
  });
}