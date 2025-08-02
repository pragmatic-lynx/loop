# Design Document

## Overview

The global achievements system extends the existing per-hero Lore system to track collection progress across all heroes. It provides a unified view of what items, weapons, and enemies the player has encountered globally, with both summary displays on the main menu and detailed achievement screens.

The system leverages the existing `lore.findItem()` and `lore.slay()` tracking points but aggregates this data into a global achievements store that persists independently of individual heroes.

## Architecture

### Core Components

1. **GlobalAchievements Class** - Central data store for global progress
2. **AchievementTracker Service** - Handles updates from hero actions  
3. **MainMenuAchievements Widget** - Summary display on main menu
4. **DetailedAchievementsScreen** - Full achievement browser
5. **Storage Integration** - Persistence layer extensions

### Data Flow

```
Hero Action (pickup/kill) → Lore Update → AchievementTracker → GlobalAchievements → Storage
                                                                      ↓
MainMenu ← AchievementTracker ← GlobalAchievements ← Storage (on load)
```

## Components and Interfaces

### GlobalAchievements Class

```dart
class GlobalAchievements {
  final Set<String> foundItems = {};
  final Set<String> foundWeapons = {};  
  final Set<String> slainEnemies = {};
  
  void recordItem(ItemType itemType);
  void recordWeapon(ItemType weaponType);
  void recordEnemy(Breed breed);
  
  AchievementStats getStats(Content content);
  bool hasFoundItem(String itemName);
  bool hasSlainEnemy(String breedName);
}
```

### AchievementTracker Service

```dart
class AchievementTracker {
  static GlobalAchievements _achievements = GlobalAchievements();
  
  static void trackItemFound(Item item);
  static void trackEnemySlain(Breed breed);
  static GlobalAchievements get achievements => _achievements;
  static void loadFromStorage(Map<String, dynamic> data);
  static Map<String, dynamic> saveToStorage();
}
```

### AchievementStats Data Class

```dart
class AchievementStats {
  final int foundItems;
  final int totalItems;
  final int foundWeapons; 
  final int totalWeapons;
  final int slainEnemies;
  final int totalEnemies;
}
```

## Data Models

### Storage Schema Extension

The global achievements data will be stored in localStorage alongside hero data:

```json
{
  "heroes": [...],
  "globalAchievements": {
    "foundItems": ["Sword", "Health Potion", ...],
    "foundWeapons": ["Sword", "Bow", ...],
    "slainEnemies": ["Goblin", "Orc", ...]
  }
}
```

### Item Categorization

Items are categorized using existing ItemType properties:
- **Weapons**: Items where `weaponType != null`
- **Items**: All ItemType entries (includes weapons for total count)
- **Enemies**: All Breed entries from content

## Error Handling

### Data Integrity
- Validate item/enemy names against content definitions on load
- Remove invalid entries that no longer exist in game content
- Handle missing achievement data gracefully with empty sets

### Storage Failures
- Graceful degradation if localStorage is unavailable
- Automatic recovery from corrupted achievement data
- Fallback to empty achievement state if loading fails

### UI Resilience
- Handle missing content gracefully in UI displays
- Show "0 out of 0" if content cannot be loaded
- Prevent crashes from malformed achievement data

