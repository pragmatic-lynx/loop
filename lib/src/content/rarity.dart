// lib/src/content/rarity.dart

/// Represents the rarity tiers for items and chests
enum Rarity { 
  common, 
  rare, 
  legendary;

  String get displayName {
    switch (this) {
      case Rarity.common:
        return 'Common';
      case Rarity.rare:
        return 'Rare';
      case Rarity.legendary:
        return 'Legendary';
    }
  }

  /// Color associated with this rarity tier
  String get colorHex {
    switch (this) {
      case Rarity.common:
        return '#bcbcbc'; // Gray
      case Rarity.rare:
        return '#51c0ff'; // Blue  
      case Rarity.legendary:
        return '#ffb547'; // Gold
    }
  }

  /// Get rarity from index for convenience
  static Rarity fromIndex(int index) {
    return Rarity.values[index.clamp(0, Rarity.values.length - 1)];
  }
}
