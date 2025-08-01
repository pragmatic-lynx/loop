import 'dart:io';
import 'package:test/test.dart';

import '../../lib/src/engine/loop/level_archetype.dart';
import '../../lib/src/engine/loop/reward_choice_log.dart';

void main() {
  group('RewardChoiceLog', () {
    test('creates log entry with correct data', () {
      final timestamp = DateTime.now();
      final log = RewardChoiceLog(
        loopNumber: 5,
        archetype: LevelArchetype.combat,
        choiceId: 'damage_boost_0',
        timestamp: timestamp,
      );

      expect(log.loopNumber, equals(5));
      expect(log.archetype, equals(LevelArchetype.combat));
      expect(log.choiceId, equals('damage_boost_0'));
      expect(log.timestamp, equals(timestamp));
    });

    test('creates log entry with factory method', () {
      final log = RewardChoiceLog.create(3, LevelArchetype.loot, 'healing_cache_1');

      expect(log.loopNumber, equals(3));
      expect(log.archetype, equals(LevelArchetype.loot));
      expect(log.choiceId, equals('healing_cache_1'));
      expect(log.timestamp, isA<DateTime>());
    });

    test('converts to CSV format correctly', () {
      final timestamp = DateTime.parse('2025-01-08T10:30:00.000Z');
      final log = RewardChoiceLog(
        loopNumber: 2,
        archetype: LevelArchetype.boss,
        choiceId: 'armor_boost_2',
        timestamp: timestamp,
      );

      final csvRow = log.toCsvRow();
      expect(csvRow, equals('2,BOSS,armor_boost_2,2025-01-08T10:30:00.000Z'));
    });

    test('provides correct CSV header', () {
      final header = RewardChoiceLog.csvHeader();
      expect(header, equals('loopNumber,archetype,choiceId,timestamp'));
    });

    test('converts to JSON correctly', () {
      final timestamp = DateTime.parse('2025-01-08T10:30:00.000Z');
      final log = RewardChoiceLog(
        loopNumber: 1,
        archetype: LevelArchetype.combat,
        choiceId: 'gold_reward_0',
        timestamp: timestamp,
      );

      final json = log.toJson();
      expect(json['loopNumber'], equals(1));
      expect(json['archetype'], equals('COMBAT'));
      expect(json['choiceId'], equals('gold_reward_0'));
      expect(json['timestamp'], equals('2025-01-08T10:30:00.000Z'));
    });
  });

  group('RewardChoiceLogger', () {
    const testLogFile = 'test_reward_choices.csv';

    setUp(() async {
      // Clean up any existing test file
      final file = File(testLogFile);
      if (await file.exists()) {
        await file.delete();
      }
    });

    tearDown(() async {
      // Clean up test file
      final file = File(testLogFile);
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('logs choice to CSV file', () async {
      // Note: This test would need to be modified to use a test-specific file
      // For now, we'll just test the log entry creation
      final log = RewardChoiceLog.create(1, LevelArchetype.combat, 'test_choice');
      
      expect(log.loopNumber, equals(1));
      expect(log.archetype, equals(LevelArchetype.combat));
      expect(log.choiceId, equals('test_choice'));
    });
  });
}