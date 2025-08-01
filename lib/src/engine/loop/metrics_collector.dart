import 'dart:convert';
import '../core/game.dart';
import 'level_archetype.dart';

/// Collects and tracks gameplay metrics for analysis during development
class MetricsCollector {
  int _deaths = 0;
  int _totalTurns = 0;
  int _damageDealt = 0;
  int _damageTaken = 0;
  DateTime? _sessionStart;
  final List<DateTime> _turnTimes = [];
  
  /// Initialize metrics collection
  MetricsCollector() {
    _sessionStart = DateTime.now();
  }
  
  /// Record a death event
  void recordDeath() {
    _deaths++;
  }
  
  /// Record a turn taken by the hero
  void recordTurn() {
    _totalTurns++;
    _turnTimes.add(DateTime.now());
    
    // Keep only the last 100 turn times for average calculation
    if (_turnTimes.length > 100) {
      _turnTimes.removeAt(0);
    }
  }
  
  /// Record damage dealt by the hero
  void recordDamageDealt(int damage) {
    _damageDealt += damage;
  }
  
  /// Record damage taken by the hero
  void recordDamageTaken(int damage) {
    _damageTaken += damage;
  }
  
  /// Calculate average turn time in milliseconds
  double get averageTurnTime {
    if (_turnTimes.length < 2) return 0.0;
    
    var totalTime = 0;
    for (var i = 1; i < _turnTimes.length; i++) {
      totalTime += _turnTimes[i].difference(_turnTimes[i - 1]).inMilliseconds;
    }
    
    return totalTime / (_turnTimes.length - 1);
  }
  
  /// Create a metrics snapshot for the current game state
  MetricsSnapshot createSnapshot(Game game, int loopNumber) {
    return MetricsSnapshot(
      loop: loopNumber,
      deaths: _deaths,
      avgTurnTime: averageTurnTime,
      dmgDealt: _damageDealt,
      dmgTaken: _damageTaken,
      archetype: game.getArchetypeMetadata()?.archetype,
      timestamp: DateTime.now(),
    );
  }
  
  /// Reset all metrics (typically called when starting a new session)
  void reset() {
    _deaths = 0;
    _totalTurns = 0;
    _damageDealt = 0;
    _damageTaken = 0;
    _sessionStart = DateTime.now();
    _turnTimes.clear();
  }
  
  /// Get current metrics as a map for debugging
  Map<String, dynamic> getMetrics() {
    return {
      'deaths': _deaths,
      'totalTurns': _totalTurns,
      'damageDealt': _damageDealt,
      'damageTaken': _damageTaken,
      'averageTurnTime': averageTurnTime,
      'sessionDuration': _sessionStart != null 
          ? DateTime.now().difference(_sessionStart!).inMinutes 
          : 0,
    };
  }
}

/// Represents a snapshot of metrics at a specific point in time
class MetricsSnapshot {
  final int loop;
  final int deaths;
  final double avgTurnTime;
  final int dmgDealt;
  final int dmgTaken;
  final LevelArchetype? archetype;
  final DateTime timestamp;
  
  MetricsSnapshot({
    required this.loop,
    required this.deaths,
    required this.avgTurnTime,
    required this.dmgDealt,
    required this.dmgTaken,
    this.archetype,
    required this.timestamp,
  });
  
  /// Convert to JSON format for logging
  String toJson() {
    return jsonEncode({
      'loop': loop,
      'deaths': deaths,
      'avgTurnTime': avgTurnTime.toStringAsFixed(2),
      'dmgDealt': dmgDealt,
      'dmgTaken': dmgTaken,
      'archetype': archetype?.name,
      'timestamp': timestamp.toIso8601String(),
    });
  }
  
  /// Create from JSON (for potential future loading)
  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) {
    return MetricsSnapshot(
      loop: json['loop'] as int,
      deaths: json['deaths'] as int,
      avgTurnTime: double.parse(json['avgTurnTime'].toString()),
      dmgDealt: json['dmgDealt'] as int,
      dmgTaken: json['dmgTaken'] as int,
      archetype: json['archetype'] != null 
          ? LevelArchetype.values.firstWhere((a) => a.name == json['archetype'])
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  
  @override
  String toString() {
    return 'MetricsSnapshot(loop: $loop, deaths: $deaths, '
           'avgTurnTime: ${avgTurnTime.toStringAsFixed(2)}ms, '
           'dmgDealt: $dmgDealt, dmgTaken: $dmgTaken, '
           'archetype: ${archetype?.name ?? 'none'})';
  }
}