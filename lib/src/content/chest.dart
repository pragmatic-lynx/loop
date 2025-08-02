// lib/src/content/chest.dart

import 'package:piecemeal/piecemeal.dart';
import '../engine.dart';
import '../engine/loop/item/item_category.dart';
import 'rarity.dart';
import 'item/drops.dart';

/// Represents different types of chests with varying loot quality
class ChestType {
  final String name;
  final Rarity rarity;
  final int minGold;
  final int maxGold;
  
  /// Drop weights per category (% chance per category)
  final Map<ItemCategory, double> dropWeights;

  const ChestType(
    this.name,
    this.rarity, 
    this.minGold,
    this.maxGold,
    this.dropWeights,
  );

  /// Pre-defined chest types
  static const wooden = ChestType(
    "wooden chest",
    Rarity.common,
    10, 50,
    {
      ItemCategory.primary: 0.3,
      ItemCategory.armor: 0.2,
      ItemCategory.healing: 0.4,
      ItemCategory.utility: 0.1,
    },
  );

  static const ornate = ChestType(
    "ornate chest", 
    Rarity.rare,
    40, 120,
    {
      ItemCategory.primary: 0.4,
      ItemCategory.secondary: 0.2,
      ItemCategory.armor: 0.3,
      ItemCategory.healing: 0.2,
      ItemCategory.utility: 0.1,
    },
  );

  static const mythic = ChestType(
    "mythic chest",
    Rarity.legendary, 
    100, 300,
    {
      ItemCategory.primary: 0.5,
      ItemCategory.secondary: 0.3,
      ItemCategory.armor: 0.4,
      ItemCategory.healing: 0.1,
      ItemCategory.utility: 0.2,
    },
  );

  /// Get chest type for a given depth
  static ChestType forDepth(int depth) {
    if (depth <= 3) {
      return wooden;
    } else if (depth <= 6) {
      // 80% wooden, 20% ornate
      return rng.percent(20) ? ornate : wooden;
    } else {
      // 70% ornate, 30% mythic
      return rng.percent(30) ? mythic : ornate;
    }
  }
}

/// Represents the loot contained in a chest
class ChestLoot {
  final int gold;
  final List<Item> items;

  ChestLoot(this.gold, this.items);
}

/// Chest logic for opening and generating loot
class Chest {
  final ChestType type;
  final int depth;

  Chest(this.type, this.depth);

  /// Opens the chest and generates loot
  ChestLoot open() {
    final gold = rng.range(type.minGold, type.maxGold);
    final items = <Item>[];

    // Generate items based on drop weights
    for (final entry in type.dropWeights.entries) {
      if (rng.percent((entry.value * 100).round())) {
        final item = _generateItemForCategory(entry.key);
        if (item != null) items.add(item);
      }
    }

    // Guarantee at least one item
    if (items.isEmpty) {
      final categories = type.dropWeights.keys.toList();
      final category = rng.item(categories);
      final item = _generateItemForCategory(category);
      if (item != null) items.add(item);
    }

    return ChestLoot(gold, items);
  }

  Item? _generateItemForCategory(ItemCategory category) {
    final dropName = _getDropNameForCategory(category);
    final drop = parseDrop(dropName, depth: depth);
    
    Item? generatedItem;
    drop.dropItem(null, depth, (item) {
      // Only accept items with rarity <= chest rarity
      if (item.type.rarity.index <= type.rarity.index) {
        generatedItem = item;
      }
    });
    
    return generatedItem;
  }

  String _getDropNameForCategory(ItemCategory category) {
    switch (category) {
      case ItemCategory.primary:
        return "equipment";
      case ItemCategory.secondary:
        return "magic";
      case ItemCategory.armor:
        return "equipment";
      case ItemCategory.healing:
        return "food"; // Includes healing potions
      case ItemCategory.utility:
        return "magic";
      case ItemCategory.treasure:
        return "treasure";
    }
  }
}
