// lib/src/engine/loop/loop_reward.dart

import 'dart:convert';
import 'dart:math' as math;
import '../hero/hero_save.dart';
import '../core/content.dart';
import '../items/item.dart';
import '../hero/stat.dart';
import '../hero/skill.dart';
import '../../content/skill/skills.dart';
// TODO: Re-enable when build issues are resolved
// import 'item/loop_item_config.dart';
// import 'item/loop_item_manager.dart';
// import 'item/item_category.dart';

/// Manages the 5-step reward cycle: Weapon -> Stats -> Armor -> Stats -> Weapon
class RewardCycleManager {
  static const List<RewardType> _cycle = [
    RewardType.weapon,  // 0
    RewardType.stats,   // 1  
    RewardType.armor,   // 2
    RewardType.stats,   // 3
    RewardType.weapon,  // 4
  ];
  
  /// Gets the reward type for the given loop number (1-based)
  static RewardType getRewardType(int loopNumber) {
    var cyclePosition = (loopNumber - 1) % _cycle.length;
    return _cycle[cyclePosition];
  }
  
  /// Gets a descriptive name for the current cycle position
  static String getCycleName(int loopNumber) {
    var type = getRewardType(loopNumber);
    var cyclePosition = (loopNumber - 1) % _cycle.length;
    
    switch (type) {
      case RewardType.weapon:
        return cyclePosition == 0 ? "Primary Weapon" : "Secondary Weapon";
      case RewardType.stats:
        return cyclePosition == 1 ? "Combat Stats" : "Core Stats";
      case RewardType.armor:
        return "Protective Gear";
    }
  }
}

/// Types of rewards in the cycle
enum RewardType {
  weapon,
  stats, 
  armor,
}

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
  
  /// Generate a list of random reward options based on the current loop cycle
  static List<LoopReward> generateRewardOptions(int count, int loopNumber, Content content, String heroClass) {
    var rewardType = RewardCycleManager.getRewardType(loopNumber);
    var rewards = <LoopReward>[];
    
    switch (rewardType) {
      case RewardType.weapon:
        rewards.addAll(_generateWeaponRewards(content, heroClass, loopNumber));
        break;
      case RewardType.stats:
        rewards.addAll(_generateStatRewards(loopNumber));
        break;
      case RewardType.armor:
        rewards.addAll(_generateArmorRewards(content, heroClass, loopNumber));
        break;
    }
    
    rewards.shuffle();
    return rewards.take(count).toList();
  }
  
  /// Generate weapon rewards for the current loop
  static List<LoopReward> _generateWeaponRewards(Content content, String heroClass, int loopNumber) {
    // Determine tier based on loop number (every 5 loops increases tier)
    var tier = math.min(3, (loopNumber / 5).ceil());
    
    // Mages get spell rewards instead of weapon rewards
    if (heroClass.toLowerCase() == 'mage') {
      return SpellReward.generateOptions(content, tier);
    }
    
    return WeaponReward.generateOptions(content, heroClass, tier);
  }
  
  /// Generate stat rewards
  static List<LoopReward> _generateStatRewards(int loopNumber) {
    return [
      StatReward(Stat.strength, 1),
      StatReward(Stat.agility, 1),
      StatReward(Stat.fortitude, 1),
      StatReward(Stat.intellect, 1),
      StatReward(Stat.will, 1),
    ];
  }
  
  /// Generate armor rewards for the current loop
  static List<LoopReward> _generateArmorRewards(Content content, String heroClass, int loopNumber) {
    // Determine tier based on loop number
    var tier = math.min(3, (loopNumber / 5).ceil());
    return ArmorReward.generateOptions(content, heroClass, tier);
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
      
      // Summoner rewards
      const SummonReward(),
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

/// Grant summoning scrolls for next run
class SummonReward extends LoopReward {
  const SummonReward() : super(
    name: "Summon Scrolls",
    description: "Start next run with monster-summoning scrolls",
    flavorText: "Ancient pacts allow you to call forth allies",
  );
  
  @override
  void apply(HeroSave hero) {
    // Add summoning scrolls to inventory
    // In a full implementation, this would search through Items.types
    // for items with "Summon" in the name and add random ones
    print("Added summoning scrolls to ${hero.name}'s inventory");
    
    // Example implementation would be:
    // var summonScrolls = Items.types.where((type) => 
    //   type.name.toLowerCase().contains('summon')).toList();
    // if (summonScrolls.isNotEmpty) {
    //   var randomScroll = summonScrolls[Random().nextInt(summonScrolls.length)];
    //   var item = Item(randomScroll, 3); // Give 3 scrolls
    //   hero.inventory.tryAdd(item);
    // }
  }
}

/// Permanent stat bonus reward
class StatReward extends LoopReward {
  final Stat stat;
  final int bonus;
  
  StatReward(this.stat, this.bonus) : super(
    name: "${stat.name} Training",
    description: "+$bonus permanent ${stat.name.toLowerCase()}",
    flavorText: "Your ${stat.name.toLowerCase()} improves through training",
  );
  
  @override
  void apply(HeroSave hero) {
    hero.addPermanentStatBonus(stat, bonus);
    print("Applied +$bonus permanent ${stat.name} to ${hero.name}");
  }
}

/// Weapon reward that gives actual weapons
class WeaponReward extends LoopReward {
  final String weaponName;
  final Content content;
  
  WeaponReward(this.weaponName, this.content) : super(
    name: weaponName,
    description: "Equip $weaponName",
    flavorText: "A fine weapon for your journey",
  );
  
  @override
  void apply(HeroSave hero) {
    var weaponType = content.tryFindItem(weaponName);
    if (weaponType != null) {
      var weapon = Item(weaponType, 1);
      var unequipped = hero.equipment.equip(weapon);
      
      // Add any unequipped items to inventory
      for (var unequippedItem in unequipped) {
        hero.inventory.tryAdd(unequippedItem);
      }
      
      print("Equipped $weaponName on ${hero.name}");
    } else {
      print("Warning: Could not find weapon type: $weaponName");
    }
  }
  
  /// Generate weapon reward options for a class and tier
  static List<WeaponReward> generateOptions(Content content, String heroClass, int tier) {
    // Load weapon tiers from the weapon data
    var weaponOptions = _getWeaponsForClassAndTier(heroClass, tier);
    return weaponOptions.map((weapon) => WeaponReward(weapon, content)).toList();
  }
  
  static List<String> _getWeaponsForClassAndTier(String heroClass, int tier) {
    // From weapon_tiers.json structure
    switch (heroClass.toLowerCase()) {
      case 'warrior':
        switch (tier) {
          case 1: return ["Stick", "Cudgel", "Hatchet"];
          case 2: return ["Shortsword", "Morningstar", "Spear"];
          case 3: return ["Mattock", "Battleaxe", "War Hammer"];
        }
        break;
      case 'ranger':
        switch (tier) {
          case 1: return ["Short Bow", "Knife", "Dirk"];
          case 2: return ["Longbow", "Dagger", "Stiletto"];
          case 3: return ["Crossbow", "Rondel", "Baselard"];
        }
        break;
      case 'mage':
        // Mages get spell rewards instead of weapon rewards
        switch (tier) {
          case 1: return ["Brilliant Beam", "Windstorm", "Fire Barrier"];
          case 2: return ["Tidal Wave", "Brilliant Beam", "Fire Barrier"];
          case 3: return ["Tidal Wave", "Windstorm", "Fire Barrier"];
        }
        break;
    }
    return ["Stick"]; // Fallback
  }
}

/// Spell reward that discovers new spells for mages
class SpellReward extends LoopReward {
  final String spellName;
  final Content content;
  
  SpellReward(this.spellName, this.content) : super(
    name: spellName,
    description: "Learn the $spellName spell",
    flavorText: "Ancient magical knowledge becomes yours",
  );
  
  @override
  void apply(HeroSave hero) {
    try {
      // Find the spell skill by name using Skills.find()
      var spell = Skills.find(spellName);
      
      // Mark the spell as learned for mages
      if (hero.heroClass.name == "Mage") {
        hero.learnSpell(spellName);
        print("${hero.name} earned the ability to cast: $spellName");
      }
      
      // Discover the spell
      if (hero.skills.discover(spell)) {
        print("${hero.name} discovered the spell: $spellName");
        
        // Immediately gain the spell (spells are always level 1 once discovered)
        if (hero.skills.gain(spell, 1)) {
          print("${hero.name} learned the spell: $spellName");
        }
      } else {
        print("${hero.name} already knows the spell: $spellName");
      }
    } catch (e) {
      print("Warning: Could not find spell: $spellName - $e");
    }
  }
  
  /// Generate spell reward options for a tier
  static List<SpellReward> generateOptions(Content content, int tier) {
    var spellOptions = _getSpellsForTier(tier);
    return spellOptions.map((spell) => SpellReward(spell, content)).toList();
  }
  
  static List<String> _getSpellsForTier(int tier) {
    // From weapon_tiers.json mage entries
    switch (tier) {
      case 1: return ["Brilliant Beam", "Windstorm", "Fire Barrier"];
      case 2: return ["Tidal Wave", "Brilliant Beam", "Fire Barrier"];
      case 3: return ["Tidal Wave", "Windstorm", "Fire Barrier"];
    }
    return ["Brilliant Beam"]; // Fallback
  }
}

/// Armor reward that gives actual armor pieces
class ArmorReward extends LoopReward {
  final String armorName;
  final Content content;
  
  ArmorReward(this.armorName, this.content) : super(
    name: armorName,
    description: "Equip $armorName",
    flavorText: "Protection for the dangers ahead",
  );
  
  @override
  void apply(HeroSave hero) {
    var armorType = content.tryFindItem(armorName);
    if (armorType != null) {
      var armor = Item(armorType, 1);
      var unequipped = hero.equipment.equip(armor);
      
      // Add any unequipped items to inventory
      for (var unequippedItem in unequipped) {
        hero.inventory.tryAdd(unequippedItem);
      }
      
      print("Equipped $armorName on ${hero.name}");
    } else {
      print("Warning: Could not find armor type: $armorName");
    }
  }
  
  /// Generate armor reward options for a class and tier
  static List<ArmorReward> generateOptions(Content content, String heroClass, int tier) {
    var armorOptions = _getArmorForClassAndTier(heroClass, tier);
    return armorOptions.map((armor) => ArmorReward(armor, content)).toList();
  }
  
  static List<String> _getArmorForClassAndTier(String heroClass, int tier) {
    // From weapon_tiers.json armorTiers structure
    switch (heroClass.toLowerCase()) {
      case 'warrior':
        switch (tier) {
          case 1: return ["Leather Cap", "Leather Shirt"];
          case 2: return ["Chainmail Coif", "Leather Armor"];
          case 3: return ["Steel Cap", "Mail Hauberk"];
        }
        break;
      case 'ranger':
        switch (tier) {
          case 1: return ["Cloth Shirt", "Cloak"];
          case 2: return ["Jerkin", "Fur Cloak", "Pair of Boots"];
          case 3: return ["Studded Armor", "Set of Bracers", "Pair of Plated Boots"];
        }
        break;
      case 'mage':
        switch (tier) {
          case 1: return ["Robe", "Pair of Sandals"];
          case 2: return ["Fur-lined Robe", "Pair of Shoes", "Pair of Gloves"];
          case 3: return ["Spidersilk Cloak", "Pair of Greaves"];
        }
        break;
    }
    return ["Robe"]; // Fallback
  }
}

// TODO: Re-enable when build issues are resolved
/*
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
*/
