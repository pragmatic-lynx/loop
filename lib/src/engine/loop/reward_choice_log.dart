import 'dart:io';

import 'level_archetype.dart';

/// Logs reward choices with archetype context for analysis
class RewardChoiceLog {
  final int loopNumber;
  final LevelArchetype archetype;
  final String choiceId;
  final DateTime timestamp;

  RewardChoiceLog({
    required this.loopNumber,
    required this.archetype,
    required this.choiceId,
    required this.timestamp,
  });

  /// Create a log entry with current timestamp
  factory RewardChoiceLog.create(
    int loopNumber,
    LevelArchetype archetype,
    String choiceId,
  ) {
    return RewardChoiceLog(
      loopNumber: loopNumber,
      archetype: archetype,
      choiceId: choiceId,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to CSV row format
  String toCsvRow() {
    return '$loopNumber,${archetype.name},$choiceId,${timestamp.toIso8601String()}';
  }

  /// CSV header for the log file
  static String csvHeader() {
    return 'loopNumber,archetype,choiceId,timestamp';
  }

  /// Convert to JSON for debugging
  Map<String, dynamic> toJson() {
    return {
      'loopNumber': loopNumber,
      'archetype': archetype.name,
      'choiceId': choiceId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'RewardChoiceLog(loop: $loopNumber, archetype: ${archetype.name}, choice: $choiceId, time: $timestamp)';
  }
}

/// Manages logging of reward choices to CSV file
class RewardChoiceLogger {
  static const String _logFileName = 'reward_choices.csv';
  static bool _headerWritten = false;

  /// Log a reward choice to CSV file
  static Future<void> logChoice(RewardChoiceLog entry) async {
    try {
      final file = File(_logFileName);
      
      // Write header if this is the first entry
      if (!_headerWritten && !await file.exists()) {
        await file.writeAsString('${RewardChoiceLog.csvHeader()}\n');
        _headerWritten = true;
      }
      
      // Append the log entry
      await file.writeAsString('${entry.toCsvRow()}\n', mode: FileMode.append);
      
      print('Logged reward choice: ${entry.toString()}');
    } catch (e) {
      print('Error logging reward choice: $e');
    }
  }

  /// Log a reward choice with current timestamp
  static Future<void> logChoiceNow(
    int loopNumber,
    LevelArchetype archetype,
    String choiceId,
  ) async {
    final entry = RewardChoiceLog.create(loopNumber, archetype, choiceId);
    await logChoice(entry);
  }

  /// Get all logged entries (for debugging/analysis)
  static Future<List<RewardChoiceLog>> getLoggedEntries() async {
    try {
      final file = File(_logFileName);
      if (!await file.exists()) {
        return [];
      }

      final lines = await file.readAsLines();
      final entries = <RewardChoiceLog>[];

      // Skip header line
      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(',');
        if (parts.length >= 4) {
          try {
            final entry = RewardChoiceLog(
              loopNumber: int.parse(parts[0]),
              archetype: LevelArchetype.values.firstWhere(
                (a) => a.name == parts[1],
                orElse: () => LevelArchetype.combat,
              ),
              choiceId: parts[2],
              timestamp: DateTime.parse(parts[3]),
            );
            entries.add(entry);
          } catch (e) {
            print('Error parsing log entry: ${lines[i]} - $e');
          }
        }
      }

      return entries;
    } catch (e) {
      print('Error reading reward choice log: $e');
      return [];
    }
  }

  /// Clear the log file (for testing)
  static Future<void> clearLog() async {
    try {
      final file = File(_logFileName);
      if (await file.exists()) {
        await file.delete();
        _headerWritten = false;
        print('Cleared reward choice log');
      }
    } catch (e) {
      print('Error clearing reward choice log: $e');
    }
  }
}