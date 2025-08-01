// lib/src/engine/loop/item/loop_item_config.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'item_category.dart';

/// Configuration entry for items that can be awarded at specific loop ranges
class LoopItemConfigEntry {
  final String itemName;
  final ItemCategory category;
  final int minLoop;
  final int maxLoop;
  final int weight; // Higher weight = more likely to appear
  final int quantity;
  
  const LoopItemConfigEntry({
    required this.itemName,
    required this.category,
    required this.minLoop,
    required this.maxLoop,
    this.weight = 10,
    this.quantity = 1,
  });
  
  factory LoopItemConfigEntry.fromMap(Map<String, dynamic> map) {
    return LoopItemConfigEntry(
      itemName: map['itemName'] ?? '',
      category: ItemCategory.values.firstWhere(
        (c) => c.toString().split('.').last == map['category'],
        orElse: () => ItemCategory.utility,
      ),
      minLoop: map['minLoop'] ?? 1,
      maxLoop: map['maxLoop'] ?? 999,
      weight: map['weight'] ?? 10,
      quantity: map['quantity'] ?? 1,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'itemName': itemName,
      'category': category.toString().split('.').last,
      'minLoop': minLoop,
      'maxLoop': maxLoop,
      'weight': weight,
      'quantity': quantity,
    };
  }
  
  /// Check if this item can appear at the given loop
  bool isAvailableAtLoop(int loop) {
    return loop >= minLoop && loop <= maxLoop;
  }
}

/// Configuration for what items can appear as rewards across different loops
class LoopItemConfig {
  final List<LoopItemConfigEntry> startingItems;
  final List<LoopItemConfigEntry> rewardItems;
  
  const LoopItemConfig({
    required this.startingItems,
    required this.rewardItems,
  });
  
  factory LoopItemConfig.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return LoopItemConfig.fromMap(map);
  }
  
  factory LoopItemConfig.fromMap(Map<String, dynamic> map) {
    return LoopItemConfig(
      startingItems: (map['startingItems'] as List<dynamic>?)
          ?.map((item) => LoopItemConfigEntry.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      rewardItems: (map['rewardItems'] as List<dynamic>?)
          ?.map((item) => LoopItemConfigEntry.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
  
  String toJson() {
    return jsonEncode(toMap());
  }
  
  Map<String, dynamic> toMap() {
    return {
      'startingItems': startingItems.map((item) => item.toMap()).toList(),
      'rewardItems': rewardItems.map((item) => item.toMap()).toList(),
    };
  }
  
  /// Get available starting items for a specific loop and category
  List<LoopItemConfigEntry> getStartingItemsForLoop(int loop, {ItemCategory? category}) {
    return startingItems.where((item) {
      if (!item.isAvailableAtLoop(loop)) return false;
      if (category != null && item.category != category) return false;
      return true;
    }).toList();
  }
  
  /// Get available reward items for a specific loop and category
  List<LoopItemConfigEntry> getRewardItemsForLoop(int loop, {ItemCategory? category}) {
    return rewardItems.where((item) {
      if (!item.isAvailableAtLoop(loop)) return false;
      if (category != null && item.category != category) return false;
      return true;
    }).toList();
  }
  
  /// Select random items from available options using weighted selection
  List<LoopItemConfigEntry> selectRandomItems(List<LoopItemConfigEntry> available, int count) {
    if (available.isEmpty) return [];
    
    final selected = <LoopItemConfigEntry>[];
    final random = Random();
    
    for (var i = 0; i < count && available.isNotEmpty; i++) {
      final totalWeight = available.fold(0, (sum, item) => sum + item.weight);
      final randomValue = random.nextInt(totalWeight);
      
      var currentWeight = 0;
      for (var item in available) {
        currentWeight += item.weight;
        if (randomValue < currentWeight) {
          selected.add(item);
          // Remove from available to avoid duplicates (optional)
          available = available.where((a) => a != item).toList();
          break;
        }
      }
    }
    
    return selected;
  }
  
  /// Load configuration from file, falling back to default if file doesn't exist
  static Future<LoopItemConfig> loadFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        return LoopItemConfig.fromJson(jsonString);
      }
    } catch (e) {
      print('Warning: Could not load loop item config from $filePath: $e');
      print('Using default configuration instead.');
    }
    return getDefault();
  }
  
  /// Save configuration to file
  Future<void> saveToFile(String filePath) async {
    try {
      final file = File(filePath);
      await file.writeAsString(toJson());
      print('Saved loop item config to $filePath');
    } catch (e) {
      print('Error saving loop item config to $filePath: $e');
    }
  }
  
  /// Get the default configuration
  static LoopItemConfig getDefault() {
    return LoopItemConfig(
      startingItems: [
        // Early game starting items (loops 1-3)
        LoopItemConfigEntry(
          itemName: 'Dagger',
          category: ItemCategory.primary,
          minLoop: 1,
          maxLoop: 3,
          weight: 15,
        ),
        LoopItemConfigEntry(
          itemName: 'Club',
          category: ItemCategory.primary,
          minLoop: 1,
          maxLoop: 5,
          weight: 12,
        ),
        LoopItemConfigEntry(
          itemName: 'Healing Potion',
          category: ItemCategory.healing,
          minLoop: 1,
          maxLoop: 999,
          weight: 20,
          quantity: 3,
        ),
        
        // Mid game starting items (loops 4-10)
        LoopItemConfigEntry(
          itemName: 'Sword',
          category: ItemCategory.primary,
          minLoop: 4,
          maxLoop: 10,
          weight: 15,
        ),
        LoopItemConfigEntry(
          itemName: 'Bow',
          category: ItemCategory.secondary,
          minLoop: 3,
          maxLoop: 15,
          weight: 12,
        ),
        LoopItemConfigEntry(
          itemName: 'Leather Armor',
          category: ItemCategory.armor,
          minLoop: 2,
          maxLoop: 8,
          weight: 10,
        ),
        
        // Late game starting items (loops 10+)
        LoopItemConfigEntry(
          itemName: 'Falchion',
          category: ItemCategory.primary,
          minLoop: 8,
          maxLoop: 999,
          weight: 12,
        ),
        LoopItemConfigEntry(
          itemName: 'Scale Mail',
          category: ItemCategory.armor,
          minLoop: 6,
          maxLoop: 999,
          weight: 8,
        ),
      ],
      rewardItems: [
        // Weapon rewards
        LoopItemConfigEntry(
          itemName: 'Sword',
          category: ItemCategory.primary,
          minLoop: 1,
          maxLoop: 5,
          weight: 15,
        ),
        LoopItemConfigEntry(
          itemName: 'Falchion',
          category: ItemCategory.primary,
          minLoop: 3,
          maxLoop: 8,
          weight: 12,
        ),
        LoopItemConfigEntry(
          itemName: 'Scimitar',
          category: ItemCategory.primary,
          minLoop: 5,
          maxLoop: 12,
          weight: 10,
        ),
        LoopItemConfigEntry(
          itemName: 'Rapier',
          category: ItemCategory.primary,
          minLoop: 6,
          maxLoop: 999,
          weight: 8,
        ),
        
        // Secondary weapon rewards
        LoopItemConfigEntry(
          itemName: 'Bow',
          category: ItemCategory.secondary,
          minLoop: 1,
          maxLoop: 999,
          weight: 12,
        ),
        LoopItemConfigEntry(
          itemName: 'Scroll of Lightning Bolt',
          category: ItemCategory.secondary,
          minLoop: 2,
          maxLoop: 999,
          weight: 10,
          quantity: 3,
        ),
        LoopItemConfigEntry(
          itemName: 'Scroll of Teleportation',
          category: ItemCategory.secondary,
          minLoop: 3,
          maxLoop: 999,
          weight: 8,
          quantity: 2,
        ),
        
        // Healing rewards
        LoopItemConfigEntry(
          itemName: 'Healing Potion',
          category: ItemCategory.healing,
          minLoop: 1,
          maxLoop: 999,
          weight: 20,
          quantity: 5,
        ),
        LoopItemConfigEntry(
          itemName: 'Scroll of Heal',
          category: ItemCategory.healing,
          minLoop: 2,
          maxLoop: 999,
          weight: 12,
          quantity: 3,
        ),
        
        // Armor rewards
        LoopItemConfigEntry(
          itemName: 'Leather Armor',
          category: ItemCategory.armor,
          minLoop: 1,
          maxLoop: 5,
          weight: 12,
        ),
        LoopItemConfigEntry(
          itemName: 'Scale Mail',
          category: ItemCategory.armor,
          minLoop: 3,
          maxLoop: 8,
          weight: 10,
        ),
        LoopItemConfigEntry(
          itemName: 'Chain Mail',
          category: ItemCategory.armor,
          minLoop: 5,
          maxLoop: 12,
          weight: 8,
        ),
        LoopItemConfigEntry(
          itemName: 'Leather Cap',
          category: ItemCategory.armor,
          minLoop: 1,
          maxLoop: 999,
          weight: 8,
        ),
        
        // Treasure rewards
        LoopItemConfigEntry(
          itemName: 'Gold',
          category: ItemCategory.treasure,
          minLoop: 1,
          maxLoop: 999,
          weight: 15,
          quantity: 500,
        ),
      ],
    );
  }
}
