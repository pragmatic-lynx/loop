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
  
  // Sample items for testing - use partial matches
  static const List<String> _sampleRangedWeapons = [
    'bow',
    'cross',
    'dart',
    'sling',
    'short',
    'long'
  ];
  
  static const List<String> _sampleMagicItems = [
    'scroll',
    'bottled',
    'wand',
    'sidestepping',
    'phasing',
    'teleportation',
    'detection',
    'disappearing'
  ];
  
  static const List<String> _sampleHealItems = [
    'balm',
    'salve',
    'poultice', 
    'potion',
    'amelioration',
    'rejuvenation',
    'antidote'
  ];
  
  DebugHelper(this.game) : hero = game.hero;
  
  /// Add random items for testing queues
  void addRandomTestItems() {
    // Add multiple items of each type for better testing
    _addRandomRangedWeapon();
    _addRandomMagicItems(2); // Add 2 different magic items
    _addRandomHealItems(2);  // Add 2 different heal items
    
    game.log.message('Debug: Added random test items!');
  }
  
  /// Add a random ranged weapon
  void _addRandomRangedWeapon() {
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
    
    if (allRangedWeapons.isNotEmpty) {
      var weapon = allRangedWeapons[_random.nextInt(allRangedWeapons.length)];
      var result = hero.inventory.tryAdd(weapon);
      if (result.added > 0) {
        game.log.message('Debug: Added ${weapon.type.name}');
      }
    }
  }
  
  /// Add multiple random magic items
  void _addRandomMagicItems(int count) {
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
    
    // Add random items from what we found
    for (var i = 0; i < count && allMagicItems.isNotEmpty; i++) {
      var item = allMagicItems[_random.nextInt(allMagicItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
      allMagicItems.remove(item); // Don't add the same item twice
    }
  }
  
  /// Add multiple random heal items
  void _addRandomHealItems(int count) {
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
    
    // Add random items from what we found
    for (var i = 0; i < count && allHealItems.isNotEmpty; i++) {
      var item = allHealItems[_random.nextInt(allHealItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
      allHealItems.remove(item); // Don't add the same item twice
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
}
