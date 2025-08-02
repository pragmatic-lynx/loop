import '../items/item.dart';
import '../monster/breed.dart';
import 'global_achievements.dart';

/// Service for managing global achievement tracking.
class AchievementTracker {
  static GlobalAchievements _achievements = GlobalAchievements();

  /// Gets the current global achievements instance.
  static GlobalAchievements get achievements => _achievements;

  /// Tracks that an item has been found by any hero.
  static void trackItemFound(Item item) {
    var itemType = item.type;
    
    // Record the item in general items
    _achievements.recordItem(itemType);
    
    // If it's a weapon, also record it in weapons
    if (itemType.weaponType != null) {
      _achievements.recordWeapon(itemType);
    }
  }

  /// Tracks that an enemy has been slain by any hero.
  static void trackEnemySlain(Breed breed) {
    _achievements.recordEnemy(breed);
  }

  /// Loads achievement data from storage.
  static void loadFromStorage(Map<String, dynamic> data) {
    _achievements = GlobalAchievements.fromJson(data);
  }

  /// Saves achievement data to storage format.
  static Map<String, dynamic> saveToStorage() {
    return _achievements.toJson();
  }

  /// Resets achievements (for testing or new game scenarios).
  static void reset() {
    _achievements = GlobalAchievements();
  }
}