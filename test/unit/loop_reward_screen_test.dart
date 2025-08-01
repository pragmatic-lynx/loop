// test/unit/loop_reward_screen_test.dart

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/src/ui/loop_reward_screen.dart';
import '../../lib/src/engine/loop/loop_manager.dart';
import '../../lib/src/engine/loop/loop_reward.dart';
import '../../lib/src/engine/core/content.dart';
import '../../lib/src/engine/hero/hero_save.dart';
import '../../lib/src/ui/storage.dart';
import '../../lib/src/ui/input.dart';

// Generate mocks
@GenerateMocks([Content, Storage, LoopManager, HeroSave])
import 'loop_reward_screen_test.mocks.dart';

void main() {
  group('LoopRewardScreen', () {
    late MockContent mockContent;
    late MockStorage mockStorage;
    late MockLoopManager mockLoopManager;
    late MockHeroSave mockHero;
    late LoopRewardScreen screen;

    setUp(() {
      mockContent = MockContent();
      mockStorage = MockStorage();
      mockLoopManager = MockLoopManager();
      mockHero = MockHeroSave();
    });

    group('Empty reward list handling', () {
      test('should handle empty reward options gracefully', () {
        // Setup: Mock loop manager with empty reward options
        when(mockLoopManager.currentRewardOptions).thenReturn(<LoopReward>[]);
        
        // This should not throw an exception
        expect(() {
          screen = LoopRewardScreen(mockContent, mockStorage, mockLoopManager, mockHero);
        }, returnsNormally);
        
        // Verify that fallback rewards were generated
        expect(screen.rewardOptions.isNotEmpty, isTrue);
        expect(screen.rewardOptions.length, equals(3));
      });

      test('should trigger reward selection if no options available', () {
        // Setup: Mock loop manager with empty reward options initially
        when(mockLoopManager.currentRewardOptions).thenReturn(<LoopReward>[]);
        
        screen = LoopRewardScreen(mockContent, mockStorage, mockLoopManager, mockHero);
        
        // Verify that triggerRewardSelection was called
        verify(mockLoopManager.triggerRewardSelection()).called(1);
      });

      test('should prevent crash when selecting reward from empty list', () {
        // Setup: Mock loop manager with empty reward options
        when(mockLoopManager.currentRewardOptions).thenReturn(<LoopReward>[]);
        
        screen = LoopRewardScreen(mockContent, mockStorage, mockLoopManager, mockHero);
        
        // Clear the fallback rewards to simulate the bug condition
        screen.rewardOptions.clear();
        
        // This should not crash
        expect(() {
          screen.handleInput(Input.ok);
        }, returnsNormally);
        
        // Verify that selectReward was not called on the loop manager
        verifyNever(mockLoopManager.selectReward(any));
      });

      test('should reset selectedReward index if out of bounds', () {
        // Setup: Create screen with some rewards
        var testRewards = [
          const DamageBoostReward(1.25),
          const ArmorBoostReward(5),
        ];
        when(mockLoopManager.currentRewardOptions).thenReturn(testRewards);
        
        screen = LoopRewardScreen(mockContent, mockStorage, mockLoopManager, mockHero);
        
        // Set selected reward to an invalid index
        screen.selectedReward = 5;
        
        // Try to select reward - should reset index to 0
        screen.handleInput(Input.ok);
        
        expect(screen.selectedReward, equals(0));
      });
    });

    group('Navigation', () {
      test('should navigate between reward options correctly', () {
        var testRewards = [
          const DamageBoostReward(1.25),
          const ArmorBoostReward(5),
          const HealthBoostReward(20),
        ];
        when(mockLoopManager.currentRewardOptions).thenReturn(testRewards);
        
        screen = LoopRewardScreen(mockContent, mockStorage, mockLoopManager, mockHero);
        
        // Test moving down
        expect(screen.selectedReward, equals(0));
        screen.handleInput(Input.s);
        expect(screen.selectedReward, equals(1));
        screen.handleInput(Input.s);
        expect(screen.selectedReward, equals(2));
        
        // Test boundary - should not go beyond last option
        screen.handleInput(Input.s);
        expect(screen.selectedReward, equals(2));
        
        // Test moving up
        screen.handleInput(Input.n);
        expect(screen.selectedReward, equals(1));
        screen.handleInput(Input.n);
        expect(screen.selectedReward, equals(0));
        
        // Test boundary - should not go below 0
        screen.handleInput(Input.n);
        expect(screen.selectedReward, equals(0));
      });
    });

    group('Reward selection', () {
      test('should select reward and apply it correctly', () {
        var testRewards = [
          const DamageBoostReward(1.25),
          const ArmorBoostReward(5),
        ];
        when(mockLoopManager.currentRewardOptions).thenReturn(testRewards);
        
        screen = LoopRewardScreen(mockContent, mockStorage, mockLoopManager, mockHero);
        screen.selectedReward = 1; // Select armor boost
        
        screen.handleInput(Input.ok);
        
        // Verify that the correct reward was selected
        verify(mockLoopManager.selectReward(testRewards[1])).called(1);
      });
    });
  });
}
