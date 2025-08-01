import 'dart:convert';

import 'density_scalars.dart';
import 'level_archetype.dart';

/// Metadata about a level's archetype and difficulty settings
class ArchetypeMetadata {
  final LevelArchetype archetype;
  final DensityScalars scalars;
  final int loopNumber;

  ArchetypeMetadata({
    required this.archetype,
    required this.scalars,
    required this.loopNumber,
  });

  /// Create metadata from individual components
  factory ArchetypeMetadata.create(
    LevelArchetype archetype,
    DensityScalars scalars,
    int loopNumber,
  ) {
    return ArchetypeMetadata(
      archetype: archetype,
      scalars: scalars,
      loopNumber: loopNumber,
    );
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'archetype': archetype.name,
      'loopNumber': loopNumber,
      'scalars': {
        'enemyMultiplier': scalars.enemyMultiplier,
        'itemMultiplier': scalars.itemMultiplier,
      },
    };
  }

  /// Convert to JSON string for logging
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON (for potential deserialization)
  factory ArchetypeMetadata.fromJson(Map<String, dynamic> json) {
    return ArchetypeMetadata(
      archetype: LevelArchetype.values.firstWhere(
        (a) => a.name == json['archetype'],
        orElse: () => LevelArchetype.combat,
      ),
      loopNumber: json['loopNumber'] ?? 0,
      scalars: DensityScalars(
        enemyMultiplier: (json['scalars'] as Map<String, dynamic>?)?['enemyMultiplier'] as double? ?? 1.0,
        itemMultiplier: (json['scalars'] as Map<String, dynamic>?)?['itemMultiplier'] as double? ?? 1.0,
      ),
    );
  }

  /// Convert to CSV format for logging
  String toCsvRow() {
    return '$loopNumber,${archetype.name},${scalars.enemyMultiplier},${scalars.itemMultiplier}';
  }

  /// CSV header for logging
  static String csvHeader() {
    return 'loopNumber,archetype,enemyMultiplier,itemMultiplier';
  }

  @override
  String toString() {
    return 'ArchetypeMetadata(archetype: ${archetype.name}, loop: $loopNumber, scalars: $scalars)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArchetypeMetadata &&
        other.archetype == archetype &&
        other.loopNumber == loopNumber &&
        other.scalars.enemyMultiplier == scalars.enemyMultiplier &&
        other.scalars.itemMultiplier == scalars.itemMultiplier;
  }

  @override
  int get hashCode {
    return Object.hash(
      archetype,
      loopNumber,
      scalars.enemyMultiplier,
      scalars.itemMultiplier,
    );
  }
}