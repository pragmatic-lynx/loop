// lib/src/engine/loop/loop_item_manager.dart

import 'dart:convert';
import 'dart:math';

import '../core/content.dart';
import '../items/item.dart';

/// Configuration entry for an item in the loop item system
class LoopItemConfig {
  final String itemName;
  final List<String> tags;
  final int weight;
  final int quantity;
  
  LoopItemConfig({
    required this.itemName,
    required this.tags, 
    required this.weight,
    required this.quantity,
  });
  
  factory LoopItemConfig.fromJson(Map<String, dynamic> json) {
    return LoopItemConfig(
      itemName: json['itemName'] as String,
      tags: List<String>.from(json['tags'] as List),
      weight: json['weight'] as int,
      quantity: json['quantity'] as int,
    );
  }
}

/// Difficulty tier for item selection
enum ItemDifficulty {
  start,
  easy, 
  mid,
  hard,
}

/// Manages item selection based on loop progression and difficulty
class LoopItemManager {
  final Content content;
  final Map<ItemDifficulty, List<LoopItemConfig>> _itemPools = {};
  final Random _random = Random();
  
  LoopItemManager(this.content);
  
  /// Load item configuration from JSON string
  void loadConfiguration(String jsonString) {
    final config = jsonDecode(jsonString) as Map<String, dynamic>;
    
    for (var difficulty in ItemDifficulty.values) {
      final difficultyName = difficulty.name;
      if (config.containsKey(difficultyName)) {
        final difficultyConfig = config[difficultyName] as Map<String, dynamic>;
        final items = difficultyConfig['items'] as List;
        
        _itemPools[difficulty] = items
            .map((item) => LoopItemConfig.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    }
  }
  
  /// Determine difficulty tier based on loop number
  ItemDifficulty getDifficultyForLoop(int loopNumber) {
    if (loopNumber <= 3) return ItemDifficulty.start;
    if (loopNumber <= 8) return ItemDifficulty.easy;
    if (loopNumber <= 15) return ItemDifficulty.mid;
    return ItemDifficulty.hard;
  }
  
  /// Get all items available for a specific difficulty tier
  List<LoopItemConfig> getItemsForDifficulty(ItemDifficulty difficulty) {
    return _itemPools[difficulty] ?? [];
  }
  
  /// Select a random item based on loop number and weighted selection
  LoopItemConfig? selectRandomItem(int loopNumber) {
    final difficulty = getDifficultyForLoop(loopNumber);
    final availableItems = getItemsForDifficulty(difficulty);
    
    if (availableItems.isEmpty) return null;
    
    // Calculate total weight
    final totalWeight = availableItems.fold<int>(0, (sum, item) => sum + item.weight);
    if (totalWeight == 0) return null;
    
    // Select random item based on weight
    final randomValue = _random.nextInt(totalWeight);
    var currentWeight = 0;
    
    for (var item in availableItems) {
      currentWeight += item.weight;
      if (randomValue < currentWeight) {
        return item;
      }
    }
    
    // Fallback to last item
    return availableItems.last;
  }
  
  /// Generate multiple random items for rewards
  List<LoopItemConfig> generateRewardItems(int loopNumber, int count) {
    final items = <LoopItemConfig>[];
    
    for (var i = 0; i < count; i++) {
      final item = selectRandomItem(loopNumber);
      if (item != null) {
        items.add(item);
      }
    }
    
    return items;
  }
  
  /// Get items matching specific tags
  List<LoopItemConfig> getItemsByTag(String tag, {ItemDifficulty? difficulty}) {
    List<LoopItemConfig> searchPool;
    
    if (difficulty != null) {
      searchPool = getItemsForDifficulty(difficulty);
    } else {
      // Search all pools
      searchPool = _itemPools.values.expand((pool) => pool).toList();
    }
    
    return searchPool.where((item) => item.tags.contains(tag)).toList();
  }
  
  /// Get summoning items specifically
  List<LoopItemConfig> getSummonItems() {
    return getItemsByTag('scroll/summon');
  }
  
  /// Create actual Item instance from config
  Item? createItemFromConfig(LoopItemConfig config) {
    final itemType = content.tryFindItem(config.itemName);
    if (itemType == null) return null;
    
    return Item(itemType, config.quantity);
  }
  
  /// Get configuration info as string for debugging
  String getConfigurationInfo() {
    final buffer = StringBuffer();
    
    for (var difficulty in ItemDifficulty.values) {
      final items = _itemPools[difficulty] ?? [];
      buffer.writeln('${difficulty.name}: ${items.length} items');
      
      for (var item in items) {
        buffer.writeln('  - ${item.itemName} (${item.tags.join(', ')}) weight: ${item.weight}');
      }
    }
    
    return buffer.toString();
  }
}
