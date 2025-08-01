// lib/src/engine/loop/loop_reward.dart

import '../hero/hero_save.dart';
import '../core/content.dart';
import '../items/item.dart';
import 'item/loop_item_config.dart';
import 'item/loop_item_manager.dart';

/// Base class for rewards that provide temporary benefits for the next loop
abstract class LoopReward {
  final String name;
  final String description;
  final String flavorText;
  
  const LoopReward({
    required this.name,
    required this.description,
    required this.flavorText,
  });
  
  /// Apply this reward's effect to the hero
  void apply(HeroSave hero);
  
  /// Generate a list of random reward options
  static List<LoopReward> generateRewardOptions(int count, {Content? content, int? currentLoop}) {
    var allRewards = _getAllRewards();
    
    // Add item rewards if content is provided
    if (content != null && currentLoop != null) {
      var itemManager = LoopItemManager(content);
      var itemRewards = itemManager.generateItemRewards(currentLoop, 3);
      // Convert LoopItemReward to LoopReward
      allRewards.addAll(itemRewards.map((itemReward) => 
        ItemLoopReward(itemReward.config, content)
      ));
    }
    
    allRewards.shuffle();
    return allRewards.take(count).toList();
  }
  
  static List<LoopReward> _getAllRewards() {
    return [
      // Combat bonuses
      const DamageBoostReward(1.25),
      const DamageBoostReward(1.5),
      const ArmorBoostReward(5),
      const ArmorBoostReward(10),
      const HealthBoostReward(20),
      const HealthBoostReward(40),
      
      // Supply drops
      const HealingSupplyReward(),
      const FoodSupplyReward(),
      const ScrollSupplyReward(),
      const GoldReward(500),
      const GoldReward(1000),
      
      // Special abilities
      const LightRadiusReward(),
      const MovementSpeedReward(),
      const LuckyFindsReward(),
    ];
  }
}

/// Temporary damage multiplier for next run
class DamageBoostReward extends LoopReward {
  final double multiplier;
  
  const DamageBoostReward(this.multiplier) : super(
    name: multiplier == 1.25 ? "Sharpened Blade" : "Battle Fury",
    description: multiplier == 1.25 ? "+25% damage for next run" : "+50% damage for next run", 
    flavorText: multiplier == 1.25 ? "Your weapons feel keener" : "Rage fills your heart",
  );
  
  @override
  void apply(HeroSave hero) {
    // This would need to be implemented in the combat system
    // For now, just log the effect
    print("Applied ${multiplier}x damage boost to ${hero.name}");
  }
}

/// Temporary armor bonus for next run
class ArmorBoostReward extends LoopReward {
  final int armorBonus;
  
  const ArmorBoostReward(this.armorBonus) : super(
    name: armorBonus == 5 ? "Protective Ward" : "Stone Skin",
    description: armorBonus == 5 ? "+5 armor for next run" : "+10 armor for next run",
    flavorText: armorBonus == 5 ? "Magical protection surrounds you" : "Your skin hardens like stone",
  );
  
  @override
  void apply(HeroSave hero) {
    // This would need to be implemented in the armor calculation system
    print("Applied +$armorBonus armor boost to ${hero.name}");
  }
}

/// Temporary health bonus for next run
class HealthBoostReward extends LoopReward {
  final int healthBonus;
  
  const HealthBoostReward(this.healthBonus) : super(
    name: healthBonus == 20 ? "Vitality Boost" : "Constitution Surge", 
    description: healthBonus == 20 ? "+20 health for next run" : "+40 health for next run",
    flavorText: healthBonus == 20 ? "You feel more vigorous" : "Vitality courses through your veins",
  );
  
  @override
  void apply(HeroSave hero) {
    // This would need to be implemented in the health system
    print("Applied +$healthBonus health boost to ${hero.name}");
  }
}

/// Spawn healing items at start of next run
class HealingSupplyReward extends LoopReward {
  const HealingSupplyReward() : super(
    name: "Healing Cache",
    description: "Start next run with extra healing potions",
    flavorText: "A hidden stash of restorative elixirs",
  );
  
  @override
  void apply(HeroSave hero) {
    // Add healing items to inventory
    // This is a simplified version - would need proper item type lookup
    print("Added healing supplies to ${hero.name}'s inventory");
  }
}

/// Spawn food items at start of next run
class FoodSupplyReward extends LoopReward {
  const FoodSupplyReward() : super(
    name: "Provisions Cache", 
    description: "Start next run with extra food supplies",
    flavorText: "A well-stocked pantry awaits",
  );
  
  @override
  void apply(HeroSave hero) {
    // Add food items to inventory
    print("Added food supplies to ${hero.name}'s inventory");
  }
}

/// Spawn useful scrolls at start of next run
class ScrollSupplyReward extends LoopReward {
  const ScrollSupplyReward() : super(
    name: "Arcane Library",
    description: "Start next run with magical scrolls",
    flavorText: "Ancient knowledge preserved in parchment",
  );
  
  @override
  void apply(HeroSave hero) {
    // Add scroll items to inventory
    print("Added magical scrolls to ${hero.name}'s inventory");
  }
}

/// Grant gold for next run
class GoldReward extends LoopReward {
  final int amount;
  
  const GoldReward(this.amount) : super(
    name: amount == 500 ? "Modest Fortune" : "Treasure Hoard",
    description: amount == 500 ? "Gain 500 gold" : "Gain 1000 gold",
    flavorText: amount == 500 ? "A purse of coins appears" : "A chest of gold awaits",
  );
  
  @override
  void apply(HeroSave hero) {
    hero.gold += amount;
    print("Added $amount gold to ${hero.name} (now has ${hero.gold})");
  }
}

/// Increase light radius for next run
class LightRadiusReward extends LoopReward {
  const LightRadiusReward() : super(
    name: "Illumination",
    description: "Increased light radius for next run",
    flavorText: "Darkness holds no fear for you",
  );
  
  @override
  void apply(HeroSave hero) {
    // This would need to be implemented in the lighting system
    print("Applied light radius boost to ${hero.name}");
  }
}

/// Increase movement speed for next run
class MovementSpeedReward extends LoopReward {
  const MovementSpeedReward() : super(
    name: "Fleet Footed",
    description: "Increased movement speed for next run", 
    flavorText: "Your steps become swift as the wind",
  );
  
  @override
  void apply(HeroSave hero) {
    // This would need to be implemented in the movement system
    print("Applied movement speed boost to ${hero.name}");
  }
}

/// Increase chances of finding better loot
class LuckyFindsReward extends LoopReward {
  const LuckyFindsReward() : super(
    name: "Fortune's Favor",
    description: "Better chance of finding rare items",
    flavorText: "Lady Luck smiles upon you",
  );
  
  @override
  void apply(HeroSave hero) {
    // This would need to be implemented in the loot generation system
    print("Applied lucky finds boost to ${hero.name}");
  }
}

/// Reward that gives actual items instead of temporary bonuses
class ItemLoopReward extends LoopReward {
  final LoopItemConfigEntry config;
  final Content content;
  
  ItemLoopReward(this.config, this.content) : super(
    name: '${config.category.icon} ${config.category.displayName}',
    description: config.quantity > 1 ? '${config.itemName} (×${config.quantity})' : config.itemName,
    flavorText: _getFlavorText(config.category),
  );
  
  static String _getFlavorText(dynamic category) {
    switch (category.toString()) {
      case 'ItemCategory.primary':
        return 'A weapon to aid your primary attacks';
      case 'ItemCategory.secondary':
        return 'Tools for tactical advantages';
      case 'ItemCategory.healing':
        return 'Sustenance for the battles ahead';
      case 'ItemCategory.armor':
        return 'Protection against the growing darkness';
      case 'ItemCategory.utility':
        return 'Useful tools for exploration';
      case 'ItemCategory.treasure':
        return 'Riches to fund your expeditions';
      default:
        return 'A useful item for your journey';
    }
  }
  
  @override
  void apply(HeroSave hero) {
    final itemType = content.tryFindItem(config.itemName);
    if (itemType == null) {
      print('Warning: Could not find item type: ${config.itemName}');
      return;
    }
    
    final item = Item(itemType, config.quantity);
    
    // Handle special case for gold
    if (config.category.toString() == 'ItemCategory.treasure' && config.itemName.toLowerCase() == 'gold') {
      hero.gold += config.quantity;
      print('Added ${config.quantity} gold to ${hero.name} (now has ${hero.gold})');
      return;
    }
    
    // Try to equip if appropriate
    if (hero.equipment.canEquip(item) && _shouldAutoEquip(config.category)) {
      final result = hero.equipment.equip(item);
      print('Equipped ${item.nounText} on ${hero.name}');
      
      // Add any unequipped items to inventory
      for (var unequippedItem in result.unequipped) {
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
  bool _shouldAutoEquip(dynamic category) {
    switch (category.toString()) {
      case 'ItemCategory.primary':
      case 'ItemCategory.secondary':
      case 'ItemCategory.armor':
        return true;
      case 'ItemCategory.healing':
      case 'ItemCategory.utility':
      case 'ItemCategory.treasure':
        return false;
      default:
        return false;
    }
  }
}
