// lib/src/engine/loop/reward_choice_log.dart

import 'dart:convert';
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

/// Manages logging of reward choices for web-compatible analysis
class RewardChoiceLogger {
  static final List<RewardChoiceLog> _logEntries = [];
  static bool _headerLogged = false;

  /// Log a reward choice (web-compatible version)
  static void logChoice(RewardChoiceLog entry) {
    try {
      _logEntries.add(entry);
      
      // Log header on first entry
      if (!_headerLogged) {
        print('REWARD_LOG_HEADER: ${RewardChoiceLog.csvHeader()}');
        _headerLogged = true;
      }
      
      // Log the entry in CSV format for easy analysis
      print('REWARD_LOG_ENTRY: ${entry.toCsvRow()}');
      
      // Also log in JSON format for debugging
      print('Reward choice logged: ${jsonEncode(entry.toJson())}');
    } catch (e) {
      print('Error logging reward choice: $e');
    }
  }

  /// Log a reward choice with current timestamp
  static void logChoiceNow(
    int loopNumber,
    LevelArchetype archetype,
    String choiceId,
  ) {
    final entry = RewardChoiceLog.create(loopNumber, archetype, choiceId);
    logChoice(entry);
  }

  /// Get all logged entries (for debugging/analysis)
  static List<RewardChoiceLog> getLoggedEntries() {
    return List.unmodifiable(_logEntries);
  }

  /// Export all logs as CSV string for external analysis
  static String exportToCsv() {
    if (_logEntries.isEmpty) return RewardChoiceLog.csvHeader();
    
    final buffer = StringBuffer();
    buffer.writeln(RewardChoiceLog.csvHeader());
    
    for (final entry in _logEntries) {
      buffer.writeln(entry.toCsvRow());
    }
    
    return buffer.toString();
  }

  /// Export all logs as JSON string for external analysis
  static String exportToJson() {
    return jsonEncode(_logEntries.map((e) => e.toJson()).toList());
  }

  /// Clear the log entries (for testing)
  static void clearLog() {
    _logEntries.clear();
    _headerLogged = false;
    print('Cleared reward choice log');
  }

  /// Print summary of logged entries
  static void printSummary() {
    if (_logEntries.isEmpty) {
      print('No reward choices logged yet');
      return;
    }

    print('=== Reward Choice Summary ===');
    print('Total entries: ${_logEntries.length}');
    
    // Group by archetype
    final archetypeGroups = <LevelArchetype, List<RewardChoiceLog>>{};
    for (final entry in _logEntries) {
      archetypeGroups.putIfAbsent(entry.archetype, () => []).add(entry);
    }
    
    for (final archetype in LevelArchetype.values) {
      final entries = archetypeGroups[archetype] ?? [];
      print('${archetype.name}: ${entries.length} choices');
    }
    
    print('=============================');
  }
}