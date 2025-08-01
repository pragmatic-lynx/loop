// lib/src/engine/loop/action_queues.dart

import '../core/game.dart';
import '../hero/hero.dart';
import '../items/item.dart';
import '../items/inventory.dart';

/// Queue item representing a single action option
class QueueItem {
  final String name;
  final String? count;
  final int? healAmount;
  final bool isAvailable;
  final Item? item;
  
  QueueItem({
    required this.name,
    this.count,
    this.healAmount,
    this.isAvailable = true,
    this.item,
  });
  
  String get displayText {
    var text = name;
    if (healAmount != null) {
      text += ' +$healAmount';
    }
    if (count != null) {
      text += ' $count';
    }
    return text;
  }
}

/// Manages queues for different action types
class ActionQueues {
  final Game game;
  final Hero hero;
  
  // Current queue being cycled (1=ranged, 2=magic, 3=heal)
  int _currentQueue = 1;
  
  // Queue positions for each action
  int _rangedQueueIndex = 0;
  int _magicQueueIndex = 0;
  int _healQueueIndex = 0;
  
  ActionQueues(this.game) : hero = game.hero;
  
  /// Get the current ranged weapon option
  QueueItem getRangedQueueItem() {
    var rangedWeapons = _getRangedWeapons();
    if (rangedWeapons.isEmpty) {
      return QueueItem(name: "No Ranged", isAvailable: false);
    }
    
    var index = _rangedQueueIndex % rangedWeapons.length;
    var weapon = rangedWeapons[index];
    var damage = weapon.attack?.createHit().averageDamage.round() ?? 0;
    return QueueItem(
      name: weapon.type.name,
      count: "($damage dmg)",
      item: weapon,
    );
  }
  
  /// Get the current magic queue item
  QueueItem getMagicQueueItem() {
    var magicItems = _getMagicItems();
    if (magicItems.isEmpty) {
      return QueueItem(name: "No Magic", isAvailable: false);
    }
    
    var index = _magicQueueIndex % magicItems.length;
    var item = magicItems[index];
    return QueueItem(
      name: item.type.name,
      count: item.count > 1 ? "(${item.count})" : null,
      item: item,
    );
  }
  
  /// Get the current heal queue item
  QueueItem getHealQueueItem() {
    var healItems = _getHealItems();
    if (healItems.isEmpty) {
      var currentHP = hero.health;
      var maxHP = hero.maxHealth;
      return QueueItem(
        name: "Healthy",
        count: "($currentHP/$maxHP HP)",
        isAvailable: false,
      );
    }
    
    var index = _healQueueIndex % healItems.length;
    var item = healItems[index];
    var healAmount = _getHealAmount(item);
    var currentHP = hero.health;
    var maxHP = hero.maxHealth;
    
    return QueueItem(
      name: item.type.name,
      count: "($currentHP/$maxHP HP)",
      healAmount: healAmount,
      item: item,
    );
  }
  
  /// Get next items in queue for tooltips
  List<QueueItem> getNextMagicItems([int count = 3]) {
    var magicItems = _getMagicItems();
    if (magicItems.isEmpty) return [];
    
    var result = <QueueItem>[];
    for (var i = 1; i <= count && i < magicItems.length; i++) {
      var index = (_magicQueueIndex + i) % magicItems.length;
      var item = magicItems[index];
      result.add(QueueItem(
        name: item.type.name,
        count: item.count > 1 ? "(${item.count})" : null,
        item: item,
      ));
    }
    return result;
  }
  
  /// Get next items in heal queue for tooltips
  List<QueueItem> getNextHealItems([int count = 3]) {
    var healItems = _getHealItems();
    if (healItems.isEmpty) return [];
    
    var result = <QueueItem>[];
    for (var i = 1; i <= count && i < healItems.length; i++) {
      var index = (_healQueueIndex + i) % healItems.length;
      var item = healItems[index];
      var healAmount = _getHealAmount(item);
      result.add(QueueItem(
        name: item.type.name,
        healAmount: healAmount,
        item: item,
      ));
    }
    return result;
  }
  
  /// Cycle the current queue forward
  void cycleCurrentQueue() {
    switch (_currentQueue) {
      case 1: // Ranged
        var rangedWeapons = _getRangedWeapons();
        if (rangedWeapons.isNotEmpty) {
          _rangedQueueIndex = (_rangedQueueIndex + 1) % rangedWeapons.length;
        }
        break;
      case 2: // Magic
        var magicItems = _getMagicItems();
        if (magicItems.isNotEmpty) {
          _magicQueueIndex = (_magicQueueIndex + 1) % magicItems.length;
        }
        break;
      case 3: // Heal
        var healItems = _getHealItems();
        if (healItems.isNotEmpty) {
          _healQueueIndex = (_healQueueIndex + 1) % healItems.length;
        }
        break;
    }
  }
  
  /// Set which queue is currently being cycled
  void setCurrentQueue(int queueNumber) {
    _currentQueue = queueNumber;
  }
  
  /// Get current queue number
  int get currentQueue => _currentQueue;
  
  /// Auto-equip ranged weapon if needed
  bool autoEquipRangedWeapon() {
    // Check if we already have a ranged weapon equipped
    for (var weapon in hero.equipment.weapons) {
      if (_isRangedWeapon(weapon)) {
        return true; // Already equipped
      }
    }
    
    // Find ranged weapon in inventory
    for (var item in hero.inventory) {
      if (_isRangedWeapon(item)) {
        // Try to equip it (equip returns list of unequipped items)
        var unequipped = hero.equipment.equip(item);
        hero.inventory.remove(item);
        // Add any unequipped items back to inventory
        for (var unequippedItem in unequipped) {
          hero.inventory.tryAdd(unequippedItem);
        }
        game.log.message('Equipped ${item.type.name}.');
        return true;
      }
    }
    
    return false; // No ranged weapon available
  }
  
  /// Get all available ranged weapons (equipped + inventory)
  List<Item> _getRangedWeapons() {
    var weapons = <Item>[];
    
    // Add equipped ranged weapons
    for (var weapon in hero.equipment.weapons) {
      if (_isRangedWeapon(weapon)) {
        weapons.add(weapon);
      }
    }
    
    // Add ranged weapons from inventory
    for (var item in hero.inventory) {
      if (_isRangedWeapon(item)) {
        weapons.add(item);
      }
    }
    
    return weapons;
  }
  
  /// Get all magic items from inventory
  List<Item> _getMagicItems() {
    var items = <Item>[];
    for (var item in hero.inventory) {
      if (_isMagicItem(item)) {
        items.add(item);
      }
    }
    return items;
  }
  
  /// Get all heal items from inventory
  List<Item> _getHealItems() {
    var items = <Item>[];
    for (var item in hero.inventory) {
      if (_isHealItem(item)) {
        items.add(item);
      }
    }
    return items;
  }
  
  /// Check if item is a ranged weapon
  bool _isRangedWeapon(Item item) {
    var name = item.type.name.toLowerCase();
    return name.contains('bow') ||
           name.contains('crossbow') ||
           name.contains('dart') ||
           name.contains('sling') ||
           name.contains('javelin') ||
           name.contains('throwing');
  }
  
  /// Check if item is a magic item
  bool _isMagicItem(Item item) {
    var name = item.type.name.toLowerCase();
    return name.contains('scroll') ||
           name.contains('wand') ||
           name.contains('spell') ||
           name.contains('tome') ||
           name.contains('book') ||
           name.contains('orb') ||
           name.contains('bottled') ||
           (name.contains('scroll') && (
             name.contains('lightning') ||
             name.contains('fireball') ||
             name.contains('ice') ||
             name.contains('teleport') ||
             name.contains('magic') ||
             name.contains('bolt') ||
             name.contains('frost') ||
             name.contains('fire') ||
             name.contains('wind') ||
             name.contains('earth') ||
             name.contains('water')
           ));
  }
  
  /// Check if item is a healing item
  bool _isHealItem(Item item) {
    var name = item.type.name.toLowerCase();
    return name.contains('healing') ||
           name.contains('potion') ||
           name.contains('elixir') ||
           name.contains('balm') ||
           name.contains('salve') ||
           name.contains('mending') ||
           name.contains('soothing') ||
           name.contains('amelioration') ||
           name.contains('rejuvenation') ||
           name.contains('antidote');
  }
  
  /// Get approximate heal amount for item
  int _getHealAmount(Item item) {
    var name = item.type.name.toLowerCase();
    
    // These are rough estimates based on the magic.dart file
    if (name.contains('soothing balm')) return 36;
    if (name.contains('mending salve')) return 64;
    if (name.contains('healing poultice')) return 120;
    if (name.contains('amelioration')) return 200;
    if (name.contains('rejuvenation')) return 1000;
    if (name.contains('antidote')) return 0; // Just cures poison
    
    // Generic estimates
    if (name.contains('healing') || name.contains('potion')) return 50;
    if (name.contains('salve') || name.contains('balm')) return 40;
    if (name.contains('elixir')) return 80;
    
    return 25; // Default estimate
  }
}
