// lib/src/engine/loop/loop_reward.dart

import 'dart:math' as math;
import '../hero/hero_save.dart';
import '../items/item.dart';
import '../core/content.dart';

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
  static List<LoopReward> generateRewardOptions(int count) {
    var allRewards = _getAllRewards();
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
