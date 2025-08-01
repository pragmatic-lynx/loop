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
  
  // Sample items for testing - these would normally come from content
  static const List<String> _sampleRangedWeapons = [
    'bow',
    'crossbow',
    'dart',
    'sling'
  ];
  
  static const List<String> _sampleMagicItems = [
    'scroll',
    'lightning',
    'fireball',
    'ice',
    'teleportation',
    'bottled'
  ];
  
  static const List<String> _sampleHealItems = [
    'healing',
    'potion',
    'balm',
    'salve',
    'elixir'
  ];
  
  DebugHelper(this.game) : hero = game.hero;
  
  /// Add random items for testing queues
  void addRandomTestItems() {
    _addRandomRangedWeapon();
    _addRandomMagicItem();
    _addRandomHealItem();
    
    game.log.message('Debug: Added random test items!');
  }
  
  /// Add a random ranged weapon
  void _addRandomRangedWeapon() {
    var rangedWeapons = _findItemsInContent(_sampleRangedWeapons);
    if (rangedWeapons.isNotEmpty) {
      var weapon = rangedWeapons[_random.nextInt(rangedWeapons.length)];
      var result = hero.inventory.tryAdd(weapon);
      if (result.added > 0) {
        game.log.message('Debug: Added ${weapon.type.name}');
      }
    }
  }
  
  /// Add a random magic item
  void _addRandomMagicItem() {
    var magicItems = _findItemsInContent(_sampleMagicItems);
    if (magicItems.isNotEmpty) {
      var item = magicItems[_random.nextInt(magicItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
    }
  }
  
  /// Add a random heal item
  void _addRandomHealItem() {
    var healItems = _findItemsInContent(_sampleHealItems);
    if (healItems.isNotEmpty) {
      var item = healItems[_random.nextInt(healItems.length)];
      var result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        game.log.message('Debug: Added ${item.type.name}');
      }
    }
  }
  
  /// Try to find actual items from game content by name similarity
  List<Item> _findItemsInContent(List<String> targetNames) {
    var foundItems = <Item>[];
    
    // Try to find items from the game's content
    for (var targetName in targetNames) {
      var item = _findItemByName(targetName);
      if (item != null) {
        foundItems.add(item);
      }
    }
    
    return foundItems;
  }
  
  /// Find an item by name from game content
  Item? _findItemByName(String targetName) {
    var lowerTarget = targetName.toLowerCase();
    
    // Try to find from existing items in the game world
    for (var itemType in game.content.items) {
      var itemName = itemType.name.toLowerCase();
      if (itemName.contains(lowerTarget) || lowerTarget.contains(itemName)) {
        return Item(itemType, 1);
      }
    }
    
    return null;
  }
}
