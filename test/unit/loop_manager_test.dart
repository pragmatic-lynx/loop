// test/unit/loop_manager_test.dart

import 'package:test/test.dart';

import '../../lib/src/engine/loop/loop_manager.dart';
import '../../lib/src/engine/loop/hero_preset.dart';
import '../../lib/src/engine/loop/loop_reward.dart';

/// Helper function to create a test preset
HeroPreset _createTestPreset() {
  return const HeroPreset(
    name: "Test Warrior",
    description: "A test preset for unit testing",
    raceName: "Human",
    className: "Warrior",
    startingEquipment: {},
    startingInventory: {},
    startingGold: 1000,
  );
}

void main() {
  group('LoopManager', () {
    late LoopManager loopManager;

    setUp(() {
      loopManager = LoopManager();
    });

    group('Move tracking and reset after death', () {
      test('should track moves correctly during normal gameplay', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        expect(loopManager.moveCount, equals(0));
        expect(loopManager.isLoopActive, isTrue);
        expect(loopManager.isRewardSelection, isFalse);
        
        // Record some moves
        for (int i = 1; i <= 50; i++) {
          loopManager.recordMove();
          expect(loopManager.moveCount, equals(i));
          expect(loopManager.isLoopActive, isTrue);
          expect(loopManager.isRewardSelection, isFalse);
        }
      });

      test('should trigger reward selection at 100 moves', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Record 99 moves - should still be active
        for (int i = 1; i <= 99; i++) {
          loopManager.recordMove();
        }
        expect(loopManager.isLoopActive, isTrue);
        expect(loopManager.isRewardSelection, isFalse);
        
        // Record 100th move - should trigger reward selection
        loopManager.recordMove();
        expect(loopManager.moveCount, equals(100));
        expect(loopManager.isLoopActive, isFalse);
        expect(loopManager.isRewardSelection, isTrue);
        expect(loopManager.currentRewardOptions.isNotEmpty, isTrue);
      });

      test('should reset move count and state after death', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Record moves up to reward selection
        for (int i = 1; i <= 100; i++) {
          loopManager.recordMove();
        }
        
        // Verify we're in reward selection state
        expect(loopManager.moveCount, equals(100));
        expect(loopManager.isLoopActive, isFalse);
        expect(loopManager.isRewardSelection, isTrue);
        
        // Hero dies
        loopManager.recordDeath();
        
        // Verify state is reset
        expect(loopManager.moveCount, equals(0));
        expect(loopManager.isLoopActive, isFalse);
        expect(loopManager.isRewardSelection, isFalse);
        expect(loopManager.currentRewardOptions.isEmpty, isTrue);
      });

      test('should reset move count after death at any point', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Record some moves (not full 100)
        for (int i = 1; i <= 75; i++) {
          loopManager.recordMove();
        }
        
        expect(loopManager.moveCount, equals(75));
        expect(loopManager.isLoopActive, isTrue);
        
        // Hero dies
        loopManager.recordDeath();
        
        // Verify state is reset
        expect(loopManager.moveCount, equals(0));
        expect(loopManager.isLoopActive, isFalse);
        expect(loopManager.isRewardSelection, isFalse);
      });

      test('should allow restarting loop after death', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Record moves to trigger reward selection
        for (int i = 1; i <= 100; i++) {
          loopManager.recordMove();
        }
        
        // Hero dies during reward selection
        loopManager.recordDeath();
        
        // Should be able to start a new loop
        loopManager.startLoop(preset);
        expect(loopManager.moveCount, equals(0));
        expect(loopManager.isLoopActive, isTrue);
        expect(loopManager.isRewardSelection, isFalse);
        
        // Should be able to record moves normally
        loopManager.recordMove();
        expect(loopManager.moveCount, equals(1));
      });
    });

    group('Reward selection', () {
      test('should generate reward options when triggered', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        expect(loopManager.currentRewardOptions.isEmpty, isTrue);
        
        loopManager.triggerRewardSelection();
        
        expect(loopManager.currentRewardOptions.isNotEmpty, isTrue);
        expect(loopManager.currentRewardOptions.length, equals(3));
        expect(loopManager.isRewardSelection, isTrue);
        expect(loopManager.isLoopActive, isFalse);
      });

      test('should properly transition to next loop after reward selection', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Trigger reward selection
        loopManager.triggerRewardSelection();
        var initialLoop = loopManager.currentLoop;
        var initialThreat = loopManager.threatLevel;
        
        // Select a reward
        var reward = loopManager.currentRewardOptions.first;
        loopManager.selectReward(reward);
        
        // Verify loop progression
        expect(loopManager.currentLoop, equals(initialLoop + 1));
        expect(loopManager.threatLevel, equals(initialThreat + 1));
        expect(loopManager.moveCount, equals(0));
        expect(loopManager.isLoopActive, isTrue);
        expect(loopManager.isRewardSelection, isFalse);
        expect(loopManager.activeRewards.contains(reward), isTrue);
      });
    });

    group('Status reporting', () {
      test('should provide accurate status information', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Record some moves
        for (int i = 1; i <= 25; i++) {
          loopManager.recordMove();
        }
        
        var status = loopManager.getStatus();
        expect(status['moveCount'], equals(25));
        expect(status['movesRemaining'], equals(75));
        expect(status['isActive'], isTrue);
        expect(status['isRewardSelection'], isFalse);
        expect(status['currentLoop'], greaterThan(0));
      });

      test('should show correct status during reward selection', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        loopManager.triggerRewardSelection();
        
        var status = loopManager.getStatus();
        expect(status['isActive'], isFalse);
        expect(status['isRewardSelection'], isTrue);
        expect(status['moveCount'], greaterThanOrEqualTo(0));
      });
    });

    group('System reset', () {
      test('should completely reset all state', () {
        var preset = _createTestPreset();
        loopManager.startLoop(preset);
        
        // Make some progress
        for (int i = 1; i <= 50; i++) {
          loopManager.recordMove();
        }
        loopManager.triggerRewardSelection();
        var reward = loopManager.currentRewardOptions.first;
        loopManager.selectReward(reward);
        
        // Reset everything
        loopManager.reset();
        
        // Verify complete reset
        expect(loopManager.currentLoop, equals(0));
        expect(loopManager.threatLevel, equals(0));
        expect(loopManager.moveCount, equals(0));
        expect(loopManager.isLoopActive, isFalse);
        expect(loopManager.isRewardSelection, isFalse);
        expect(loopManager.currentRewardOptions.isEmpty, isTrue);
        expect(loopManager.activeRewards.isEmpty, isTrue);
      });
    });
  });
}
