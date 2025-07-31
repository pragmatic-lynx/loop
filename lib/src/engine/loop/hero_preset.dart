// lib/src/engine/loop/hero_preset.dart

import '../hero/hero_save.dart';
import '../hero/hero_class.dart';
import '../items/item.dart';
import '../core/content.dart';

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
      "Sword": 1,           // Much better weapon
      "Leather Armor": 1,   // Actual armor
      "Leather Cap": 1,
    },
    startingInventory: {
      "Healing Potion": 8,   // More healing for fast combat
      "Loaf of Bread": 3,
      "Tallow Candle": 5,
    },
    startingGold: 2000,       // More gold for upgrades
  );
  
  static const _rogue = HeroPreset(
    name: "Rogue", 
    description: "A nimble fighter focusing on agility and stealth",
    raceName: "Human",
    className: "Adventurer",
    startingEquipment: {
      "Rapier": 1,           // Better weapon
      "Leather Armor": 1,   // Light armor for protection
    },
    startingInventory: {
      "Scroll of Sidestepping": 6,  // More mobility
      "Healing Potion": 5,          // Better healing
      "Loaf of Bread": 2,
      "Tallow Candle": 4,
    },
    startingGold: 1500,
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
      "Scroll of Lightning Bolt": 6,  // More offensive spells
      "Scroll of Heal": 4,           // Healing magic
      "Healing Potion": 4,           // Backup healing
      "Scroll of Teleportation": 2,   // Escape option
      "Loaf of Bread": 2,
      "Tallow Candle": 6,            // More light for spellcasting
    },
    startingGold: 1000,
  );
  
  static const _ranger = HeroPreset(
    name: "Ranger",
    description: "A balanced fighter with ranged capabilities",
    raceName: "Human",
    className: "Adventurer",
    startingEquipment: {
      "Bow": 1,
      "Leather Armor": 1,   // Armor for survivability
      "Dagger": 1,          // Backup melee weapon
    },
    startingInventory: {
      "Arrow": 50,           // Plenty of arrows for 50-move battles
      "Healing Potion": 6,   // More healing
      "Loaf of Bread": 3,
      "Tallow Candle": 4,
    },
    startingGold: 1800,
  );
}
