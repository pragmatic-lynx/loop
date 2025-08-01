import 'level_archetype.dart';
import 'density_scalars.dart';

/// Carries archetype information through the level generation pipeline
class ArchetypeMetadata {
  final LevelArchetype archetype;
  final DensityScalars scalars;
  final int loopNumber;

  ArchetypeMetadata(this.archetype, this.scalars, this.loopNumber);

  /// Create metadata with default scalars
  ArchetypeMetadata.withDefaults(this.archetype, this.loopNumber)
      : scalars = DensityScalars();

  /// Serialize for logging
  Map<String, dynamic> toJson() {
    return {
      'archetype': archetype.name,
      'enemyMultiplier': scalars.enemyMultiplier,
      'itemMultiplier': scalars.itemMultiplier,
      'loopNumber': loopNumber,
    };
  }

  @override
  String toString() => 'ArchetypeMetadata(${archetype.name}, loop: $loopNumber, scalars: $scalars)';
}