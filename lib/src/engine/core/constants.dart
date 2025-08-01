// lib/src/engine/core/constants.dart

/// Game constants for tweaking gameplay balance
class GameConstants {
  /// XP bonus for descending stairs (configurable for easy tuning)
  static const int stairXpBonus = 25;
  
  /// Path to XP curve JSON file
  static const String xpCurveAssetPath = "assets/xp_curve.json";
  
  /// Default XP curve to use if asset loading fails
  static const List<int> defaultXpCurve = [
    0, 0, 50, 120, 220, 350, 500, 700, 920, 1200,
    1500, 1850, 2250, 2700, 3200, 3750, 4350, 5000,
    5700, 6450, 7250, 8100, 9000, 9950, 10950, 12000,
    13100, 14250, 15450, 16700, 18000, 19350, 20750, 22200,
    23700, 25250, 26850, 28500, 30200, 31950, 33750, 35600,
    37500, 39450, 41450, 43500, 45600, 47750, 49950, 52200
  ];
}
