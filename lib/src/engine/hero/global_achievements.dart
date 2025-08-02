import '../core/content.dart';
import '../items/item_type.dart';
import '../monster/breed.dart';

/// Statistics about global achievement progress.
class AchievementStats {
  final int foundItems;
  final int totalItems;
  final int foundWeapons;
  final int totalWeapons;
  final int slainEnemies;
  final int totalEnemies;

  AchievementStats({
    required this.foundItems,
    required this.totalItems,
    required this.foundWeapons,
    required this.totalWeapons,
    required this.slainEnemies,
    required this.totalEnemies,
  });
}

/// Tracks global achievements across all heroes and game sessions.
class GlobalAchievements {
  final Set<String> foundItems = <String>{};
  final Set<String> foundWeapons = <String>{};
  final Set<String> slainEnemies = <String>{};

  /// Records that an item has been found globally.
  void recordItem(ItemType itemType) {
    foundItems.add(itemType.name);
  }

  /// Records that a weapon has been found globally.
  void recordWeapon(ItemType weaponType) {
    foundWeapons.add(weaponType.name);
  }

  /// Records that an enemy has been slain globally.
  void recordEnemy(Breed breed) {
    slainEnemies.add(breed.name);
  }

  /// Gets achievement statistics based on the current content.
  AchievementStats getStats(Content content) {
    var totalItems = content.items.length;
    var totalWeapons = content.items.where((item) => item.weaponType != null).length;
    var totalEnemies = content.breeds.length;

    return AchievementStats(
      foundItems: foundItems.length,
      totalItems: totalItems,
      foundWeapons: foundWeapons.length,
      totalWeapons: totalWeapons,
      slainEnemies: slainEnemies.length,
      totalEnemies: totalEnemies,
    );
  }

  /// Checks if a specific item has been found.
  bool hasFoundItem(String itemName) {
    return foundItems.contains(itemName);
  }

  /// Checks if a specific enemy has been slain.
  bool hasSlainEnemy(String breedName) {
    return slainEnemies.contains(breedName);
  }

  /// Creates a GlobalAchievements instance from saved data.
  static GlobalAchievements fromJson(Map<String, dynamic> data) {
    var achievements = GlobalAchievements();
    
    var foundItemsList = data['foundItems'] as List<dynamic>? ?? [];
    achievements.foundItems.addAll(foundItemsList.cast<String>());
    
    var foundWeaponsList = data['foundWeapons'] as List<dynamic>? ?? [];
    achievements.foundWeapons.addAll(foundWeaponsList.cast<String>());
    
    var slainEnemiesList = data['slainEnemies'] as List<dynamic>? ?? [];
    achievements.slainEnemies.addAll(slainEnemiesList.cast<String>());
    
    return achievements;
  }

  /// Converts the achievements to JSON for saving.
  Map<String, dynamic> toJson() {
    return {
      'foundItems': foundItems.toList(),
      'foundWeapons': foundWeapons.toList(),
      'slainEnemies': slainEnemies.toList(),
    };
  }
}