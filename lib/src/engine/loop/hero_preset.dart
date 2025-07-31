// lib/src/engine/loop/hero_preset.dart

import '../hero/hero_save.dart';
import '../hero/hero_class.dart';
import '../hero/race.dart';
import '../items/item.dart';
import '../items/item_type.dart';
import '../core/content.dart';
import '../core/option.dart';

/// A preset configuration for quickly setting up heroes for roguelite runs
class HeroPreset {
  final String name;
  final String description;
  final String raceName;
  final String className;
  final Map<String, int> startingEquipment;
  final Map<String, int> startingInventory;
  final int startingGold;
  
  const HeroPreset({
    required this.name,
    required this.description,
    required this.raceName,
    required this.className,
    required this.startingEquipment,
    required this.startingInventory,
    this.startingGold = 1000,
  });
  
  /// Create a hero from this preset
  HeroSave createHero(String heroName, Content content) {
    // Find the correct class
    HeroClass? heroClass;
    for (var cls in content.classes) {
      if (cls.name == className) {
        heroClass = cls;
        break;
      }
    }
    heroClass ??= content.classes.first; // Default to first class if not found
    
    // Create the hero using content.createHero (race defaults to human)
    var hero = content.createHero(heroName,
        heroClass: heroClass,
        permadeath: false);
    
    // Set starting gold
    hero.gold = startingGold;
    
    // Add starting equipment
    for (var entry in startingEquipment.entries) {
      var itemType = content.tryFindItem(entry.key);
      if (itemType != null) {
        var item = Item(itemType, entry.value);
        if (hero.equipment.canEquip(item)) {
          hero.equipment.equip(item);
        } else {
          hero.inventory.tryAdd(item);
        }
      }
    }
    
    // Add starting inventory items
    for (var entry in startingInventory.entries) {
      var itemType = content.tryFindItem(entry.key);
      if (itemType != null) {
        var item = Item(itemType, entry.value);
        hero.inventory.tryAdd(item);
      }
    }
    
    return hero;
  }
  
  /// Get all available presets
  static List<HeroPreset> getAllPresets() {
    return [
      _warrior,
      _rogue,
      _mage,
      _ranger,
    ];
  }
  
  static const _warrior = HeroPreset(
    name: "Warrior",
    description: "A sturdy fighter with heavy armor and weapons",
    raceName: "Human",
    className: "Warrior", 
    startingEquipment: {
      "Club": 1,
      "Robe": 1,
      "Leather Cap": 1,
    },
    startingInventory: {
      "Healing Potion": 3,
      "Loaf of Bread": 5,
      "Tallow Candle": 2,
    },
    startingGold: 1500,
  );
  
  static const _rogue = HeroPreset(
    name: "Rogue", 
    description: "A nimble fighter focusing on agility and stealth",
    raceName: "Human",
    className: "Adventurer",
    startingEquipment: {
      "Dirk": 1,
      "Robe": 1,
    },
    startingInventory: {
      "Scroll of Sidestepping": 4,
      "Mending Salve": 3,
      "Loaf of Bread": 3,
      "Tallow Candle": 3,
    },
    startingGold: 800,
  );
  
  static const _mage = HeroPreset(
    name: "Mage",
    description: "A spellcaster with magical abilities and scrolls",
    raceName: "Human", 
    className: "Mage",
    startingEquipment: {
      "Staff": 1,
      "Robe": 1,
    },
    startingInventory: {
      "Scroll of Lightning Bolt": 2,
      "Healing Potion": 3,
      "Scroll of Mapping": 1,
      "Loaf of Bread": 2,
      "Tallow Candle": 4,
    },
    startingGold: 500,
  );
  
  static const _ranger = HeroPreset(
    name: "Ranger",
    description: "A balanced fighter with ranged capabilities",
    raceName: "Human",
    className: "Adventurer",
    startingEquipment: {
      "Bow": 1,
      "Robe": 1,
    },
    startingInventory: {
      "Arrow": 20,
      "Healing Potion": 2,
      "Loaf of Bread": 4,
      "Tallow Candle": 2,
    },
    startingGold: 1200,
  );
}
