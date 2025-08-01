/// Holds multipliers for enemy and item density based on level archetype
class DensityScalars {
  double enemyMultiplier;
  double itemMultiplier;

  DensityScalars({
    this.enemyMultiplier = 1.0,
    this.itemMultiplier = 1.0,
  });

  /// Create a copy with modified values
  DensityScalars copyWith({
    double? enemyMultiplier,
    double? itemMultiplier,
  }) {
    return DensityScalars(
      enemyMultiplier: enemyMultiplier ?? this.enemyMultiplier,
      itemMultiplier: itemMultiplier ?? this.itemMultiplier,
    );
  }

  @override
  String toString() => 'DensityScalars(enemy: ${enemyMultiplier}x, item: ${itemMultiplier}x)';
}