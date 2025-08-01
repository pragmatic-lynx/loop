// lib/src/engine/loop/item/loop_item_manager.dart

import 'dart:math';
import '../../core/content.dart';
import '../../hero/hero_save.dart';
import '../../items/item.dart';
import 'item_category.dart';
import 'loop_item_config.dart';

/// Manages item progression and assignment across loops
class LoopItemManager {
  final Content content;
  final LoopItemConfig config;
  
  LoopItemManager(this.content, {LoopItemConfig? config}) 
    : config = config ?? LoopItemConfig.getDefault();
    
  /// Create a LoopItemManager with config loaded from file
  static Future<LoopItemManager> fromFile(Content content, String configPath) async {
    final config = await LoopItemConfig.loadFromFile(configPath);
    return LoopItemManager(content, config: config);
  }
  
  /// Apply loop-based starting items to a hero
  void applyLoopStartingItems(HeroSave hero, int loop) {
    print('Applying loop $loop starting items to ${hero.name}');
    
    // Get items for each category
    final primaryItems = config.getStartingItemsForLoop(loop, category: ItemCategory.primary);
    final secondaryItems = config.getStartingItemsForLoop(loop, category: ItemCategory.secondary);
    final healingItems = config.getStartingItemsForLoop(loop, category: ItemCategory.healing);
    final armorItems = config.getStartingItemsForLoop(loop, category: ItemCategory.armor);
    
    // Select and apply items
    _applyItemsFromConfig(hero, primaryItems, 1); // One primary weapon
    _applyItemsFromConfig(hero, secondaryItems, 1); // One secondary item
    _applyItemsFromConfig(hero, healingItems, 1); // One type of healing item
    _applyItemsFromConfig(hero, armorItems, 2); // Up to 2 armor pieces
    
    print('Applied loop starting items to ${hero.name}');
  }
  
  /// Get reward options for current loop
  List<LoopItemReward> generateItemRewards(int loop, int count) {
    final rewards = <LoopItemReward>[];
    
    // Generate rewards for each major category
    final categories = [ItemCategory.primary, ItemCategory.secondary, ItemCategory.healing, ItemCategory.armor];
    
    for (var category in categories) {
      final availableItems = config.getRewardItemsForLoop(loop, category: category);
      if (availableItems.isNotEmpty) {
        final selectedItems = config.selectRandomItems(availableItems, 1);
        if (selectedItems.isNotEmpty) {
          rewards.add(LoopItemReward(selectedItems.first, content));
        }
      }
    }
    
    // Add some treasure rewards
    final treasureItems = config.getRewardItemsForLoop(loop, category: ItemCategory.treasure);
    final selectedTreasure = config.selectRandomItems(treasureItems, 2);
    for (var treasureConfig in selectedTreasure) {
      rewards.add(LoopItemReward(treasureConfig, content));
    }
    
    // Shuffle and take the requested count
    rewards.shuffle();
    return rewards.take(count).toList();
  }
  
  /// Apply items from config entries to hero
  void _applyItemsFromConfig(HeroSave hero, List<LoopItemConfigEntry> configItems, int maxItems) {
    if (configItems.isEmpty) return;
    
    final selectedConfigs = config.selectRandomItems(configItems, maxItems);
    
    for (var itemConfig in selectedConfigs) {
      _addItemToHero(hero, itemConfig);
    }
  }
  
  /// Add a specific item to hero based on config
  void _addItemToHero(HeroSave hero, LoopItemConfigEntry itemConfig) {
    final itemType = content.tryFindItem(itemConfig.itemName);
    if (itemType == null) {
      print('Warning: Could not find item type: ${itemConfig.itemName}');
      return;
    }
    
    final item = Item(itemType, itemConfig.quantity);
    
    // Try to equip if it's equippable and we don't already have one
    if (hero.equipment.canEquip(item)) {
      // Check if we already have this type equipped
      final existingEquipped = _hasEquippedInCategory(hero, itemConfig.category);
      if (!existingEquipped || itemConfig.category == ItemCategory.armor) {
        // Armor can have multiple pieces, others replace
        final unequippedItems = hero.equipment.equip(item);
        if (unequippedItems.isNotEmpty) {
          // Add unequipped items to inventory
          for (var unequippedItem in unequippedItems) {
            hero.inventory.tryAdd(unequippedItem);
          }
        }
        print('Equipped ${item.nounText} on ${hero.name}');
        return;
      }
    }
    
    // Add to inventory if can't equip or already have equipped
    final result = hero.inventory.tryAdd(item);
    if (result.added > 0) {
      print('Added ${item.clone(result.added).nounText} to ${hero.name}\'s inventory');
    } else {
      print('Warning: Could not add ${item.nounText} to ${hero.name}\'s inventory (full?)');
    }
  }
  
  /// Check if hero already has item equipped in category
  bool _hasEquippedInCategory(HeroSave hero, ItemCategory category) {
    switch (category) {
      case ItemCategory.primary:
        return hero.equipment.weapons.isNotEmpty;
      case ItemCategory.secondary:
        return hero.equipment.weapons.length > 1; // Secondary weapon
      case ItemCategory.armor:
        // Check if any armor slots are filled (body, cloak, helm, gloves, boots, ring, necklace)
        return hero.equipment.any((item) => _isArmorItem(item));
      case ItemCategory.healing:
      case ItemCategory.utility:
      case ItemCategory.treasure:
        return false; // These don't get equipped
    }
  }
  
  /// Update smart combat system with current equipment categories
  void updateSmartCombatCategories(HeroSave hero) {
    // This will be called to help SmartCombat understand what items are available
    // Implementation depends on how we want to integrate with SmartCombat
  }
  
  /// Check if an item is armor based on its category
  bool _isArmorItem(Item item) {
    final category = ItemCategorizer.categorizeByName(item.type.name);
    return category == ItemCategory.armor;
  }
}

/// Reward that gives actual items instead of temporary bonuses
class LoopItemReward {
  final LoopItemConfigEntry config;
  final Content content;
  
  LoopItemReward(this.config, this.content);
  
  String get name => '${config.category.icon} ${config.category.displayName}';
  
  String get description {
    if (config.quantity > 1) {
      return '${config.itemName} (×${config.quantity})';
    }
    return config.itemName;
  }
  
  String get flavorText {
    switch (config.category) {
      case ItemCategory.primary:
        return 'A weapon to aid your primary attacks';
      case ItemCategory.secondary:
        return 'Tools for tactical advantages';
      case ItemCategory.healing:
        return 'Sustenance for the battles ahead';
      case ItemCategory.armor:
        return 'Protection against the growing darkness';
      case ItemCategory.utility:
        return 'Useful tools for exploration';
      case ItemCategory.treasure:
        return 'Riches to fund your expeditions';
    }
  }
  
  /// Apply this reward to the hero
  void apply(HeroSave hero) {
    final itemType = content.tryFindItem(config.itemName);
    if (itemType == null) {
      print('Warning: Could not find item type: ${config.itemName}');
      return;
    }
    
    final item = Item(itemType, config.quantity);
    
    // Handle special case for gold
    if (config.category == ItemCategory.treasure && config.itemName.toLowerCase() == 'gold') {
      hero.gold += config.quantity;
      print('Added ${config.quantity} gold to ${hero.name} (now has ${hero.gold})');
      return;
    }
    
    // Try to equip if appropriate
    if (hero.equipment.canEquip(item) && _shouldAutoEquip(config.category)) {
      final unequippedItems = hero.equipment.equip(item);
      print('Equipped ${item.nounText} on ${hero.name}');
      
      // Add any unequipped items to inventory
      for (var unequippedItem in unequippedItems) {
        hero.inventory.tryAdd(unequippedItem);
      }
    } else {
      // Add to inventory
      final result = hero.inventory.tryAdd(item);
      if (result.added > 0) {
        print('Added ${item.clone(result.added).nounText} to ${hero.name}\'s inventory');
      }
    }
  }
  
  /// Check if items of this category should be auto-equipped
  bool _shouldAutoEquip(ItemCategory category) {
    switch (category) {
      case ItemCategory.primary:
      case ItemCategory.secondary:
      case ItemCategory.armor:
        return true;
      case ItemCategory.healing:
      case ItemCategory.utility:
      case ItemCategory.treasure:
        return false;
    }
  }
}
