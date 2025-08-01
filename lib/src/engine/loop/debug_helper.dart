// lib/src/engine/loop/debug_helper.dart

import 'dart:math' as math;
import '../core/game.dart';
import '../hero/hero.dart';
import '../items/item.dart';

/// Provides debug functionality for testing queues
class DebugHelper {
  final Game game;
  final Hero hero;
  final math.Random _random = math.Random();
  
  // Sample items for testing - use partial matches for maximum variety
  static const List<String> _sampleRangedWeapons = [
    'bow', 'cross', 'dart', 'sling', 'short', 'long', 'javelin', 'throw'
  ];
  
  static const List<String> _sampleMagicItems = [
    'scroll', 'bottled', 'wand', 'sidestepping', 'phasing', 'teleportation',
    'detection', 'disappearing', 'lightning', 'fireball', 'ice', 'fire',
    'cold', 'wind', 'earth', 'water', 'acid', 'poison', 'light', 'dark',
    'spirit', 'ocean', 'shadow', 'radiance', 'quickness', 'alacrity', 'speed'
  ];
  
  static const List<String> _sampleHealItems = [
    'balm', 'salve', 'poultice', 'potion', 'amelioration', 'rejuvenation',
    'antidote', 'healing', 'mending', 'soothing', 'elixir', 'bottle'
  ];
  
  static const List<String> _sampleResistanceItems = [
    'resistance', 'heat', 'cold', 'light', 'wind', 'lightning', 'darkness',
    'earth', 'water', 'acid', 'poison', 'death', 'fire', 'air', 'spirit'
  ];
  
  DebugHelper(this.game) : hero = game.hero;
  
  /// Add random items for testing queues
  void addRandomTestItems() {
    // Add lots of items of each type for comprehensive testing
    addRandomRangedWeapons(2);  // Add 2 ranged weapons
    addRandomMagicItems(5);     // Add 5 different magic items
    addRandomHealItems(4);      // Add 4 different heal items  
    addRandomResistanceItems(3); // Add 3 resistance items
    
    // Give hero basic archery skill so ranged weapons work
    _giveBasicArcherySkill();
    
    game.log.message('Debug: Added lots of random test items!');
  }
  
  /// Add multiple random ranged weapons
  void addRandomRangedWeapons(int count) {
    var allRangedWeapons = <Item>[];
    
    // Find all ranged weapons available  
    for (var keyword in _sampleRangedWeapons) {
      var items = _findItemsByKeyword(keyword);
      for (var item in items) {
        if (_isRangedWeaponByName(item.type.name)) {
          allRangedWeapons.add(item);
        }
      }
    }
    
    // Add random weapons from what we found - always add new ones
    for (var i = 0; i < count && allRangedWeapons.isNotEmpty; i++) {
      var weapon = allRangedWeapons[_random.nextInt(allRangedWeapons.length)];
      var result = hero.inventory.tryAdd(weapon);
      if (result.added > 0) {
        game.log.message('Debug: Added ${weapon.type.name}');
      }
      // Don't remove from list - allow duplicates for easier testing
    }
  }
  
  /// Add multiple random magic items
  void addRandomMagicItems(int count) {
    var allMagicItems = <Item>[];
    
    // Find all magic items available
    for (var keyword in _sampleMagicItems) {
      var items = _findItemsByKeyword(keyword);
      for (var item in items) {
        if (_isMagicItemByName(item.type.name)) {
          allMagicItems.add(item);
        }
      }
    }
    
    // Always try to add items, regardless of existing ones
    for (var i = 0; i < count && allMagicItems.isNotEmpty; i++) {
      var item = allMagicItems[_random.nextInt(allMagicItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
    }
  }
  
  /// Add multiple random heal items
  void addRandomHealItems(int count) {
    var allHealItems = <Item>[];
    
    // Find all heal items available
    for (var keyword in _sampleHealItems) {
      var items = _findItemsByKeyword(keyword);
      for (var item in items) {
        if (_isHealItemByName(item.type.name)) {
          allHealItems.add(item);
        }
      }
    }
    
    // Always try to add items
    for (var i = 0; i < count && allHealItems.isNotEmpty; i++) {
      var item = allHealItems[_random.nextInt(allHealItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
    }
  }
  
  /// Add multiple random resistance items
  void addRandomResistanceItems(int count) {
    var allResistanceItems = <Item>[];
    
    // Find all resistance items available
    for (var keyword in _sampleResistanceItems) {
      var items = _findItemsByKeyword(keyword);
      for (var item in items) {
        if (_isResistanceItemByName(item.type.name)) {
          allResistanceItems.add(item);
        }
      }
    }
    
    // Always try to add items
    for (var i = 0; i < count && allResistanceItems.isNotEmpty; i++) {
      var item = allResistanceItems[_random.nextInt(allResistanceItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
    }
  }
  
  /// Find multiple items by keyword
  List<Item> _findItemsByKeyword(String keyword) {
    var foundItems = <Item>[];
    var lowerKeyword = keyword.toLowerCase();
    
    // Search through all available item types
    for (var itemType in game.content.items) {
      var itemName = itemType.name.toLowerCase();
      if (itemName.contains(lowerKeyword)) {
        foundItems.add(Item(itemType, 1));
      }
    }
    
    return foundItems;
  }
  
  /// Check if item name indicates a magic item
  bool _isMagicItemByName(String itemName) {
    var name = itemName.toLowerCase();
    return name.contains('scroll') ||
           name.contains('wand') ||
           name.contains('spell') ||
           name.contains('tome') ||
           name.contains('book') ||
           name.contains('orb') ||
           name.contains('bottled') ||
           name.contains('detection') ||
           name.contains('teleport') ||
           name.contains('phasing') ||
           name.contains('sidestepping') ||
           name.contains('disappearing');
  }
  
  /// Check if item name indicates a heal item
  bool _isHealItemByName(String itemName) {
    var name = itemName.toLowerCase();
    return name.contains('healing') ||
           name.contains('potion') ||
           name.contains('elixir') ||
           name.contains('balm') ||
           name.contains('salve') ||
           name.contains('mending') ||
           name.contains('soothing') ||
           name.contains('amelioration') ||
           name.contains('rejuvenation') ||
           name.contains('antidote') ||
           name.contains('poultice');
  }
  
  /// Check if item name indicates a ranged weapon
  bool _isRangedWeaponByName(String itemName) {
    var name = itemName.toLowerCase();
    return name.contains('bow') ||
           name.contains('crossbow') ||
           name.contains('dart') ||
           name.contains('sling') ||
           name.contains('javelin') ||
           name.contains('throwing') ||
           name.contains('short bow') ||
           name.contains('longbow');
  }
  
  /// Check if item name indicates a resistance item
  bool _isResistanceItemByName(String itemName) {
    var name = itemName.toLowerCase();
    return name.contains('resistance') ||
           name.contains('resist') ||
           (name.contains('salve') && (
             name.contains('heat') ||
             name.contains('cold') ||
             name.contains('light') ||
             name.contains('wind') ||
             name.contains('lightning') ||
             name.contains('darkness') ||
             name.contains('earth') ||
             name.contains('water') ||
             name.contains('acid') ||
             name.contains('poison') ||
             name.contains('death') ||
             name.contains('fire') ||
             name.contains('air') ||
             name.contains('spirit')
           ));  
  }
  
  /// Give hero basic archery skill so ranged weapons work
  void _giveBasicArcherySkill() {
    // Find the archery skill and give some basic points
    try {
      for (var skill in game.content.skills) {
        if (skill.name.toLowerCase() == 'archery') {
          // Give enough points for level 10 archery (should be proficient)
          hero.skills.earnPoints(skill, 5000);
          game.log.message('Debug: Granted advanced Archery skill (Level 10)!');
          break;
        }
      }
    } catch (e) {
      // If we can't find the skill system, just log it
      game.log.message('Debug: Could not grant archery skill: $e');
    }
  }
}
