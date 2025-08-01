// lib/src/engine/loop/item/item_category.dart

/// Categories for smart item management in loop mode
enum ItemCategory {
  primary,      // Primary weapons for action1
  secondary,    // Secondary weapons/tools for action2  
  healing,      // Healing items for action3
  armor,        // Armor upgrades
  utility,      // General utility items
  treasure,     // Gold and valuable items
}

extension ItemCategoryExtension on ItemCategory {
  String get displayName {
    switch (this) {
      case ItemCategory.primary:
        return 'Primary Weapon';
      case ItemCategory.secondary:
        return 'Secondary';
      case ItemCategory.healing:
        return 'Healing';
      case ItemCategory.armor:
        return 'Armor';
      case ItemCategory.utility:
        return 'Utility';
      case ItemCategory.treasure:
        return 'Treasure';
    }
  }
  
  String get description {
    switch (this) {
      case ItemCategory.primary:
        return 'Weapons for your main attack';
      case ItemCategory.secondary:
        return 'Ranged weapons, spells, and tools';
      case ItemCategory.healing:
        return 'Potions and healing items';
      case ItemCategory.armor:
        return 'Protective equipment';
      case ItemCategory.utility:
        return 'General utility items';
      case ItemCategory.treasure:
        return 'Gold and valuable items';
    }
  }
  
  String get icon {
    switch (this) {
      case ItemCategory.primary:
        return '🗡️';
      case ItemCategory.secondary:
        return '⚡';
      case ItemCategory.healing:
        return '❤️';
      case ItemCategory.armor:
        return '🛡️';
      case ItemCategory.utility:
        return '🔧';
      case ItemCategory.treasure:
        return '💰';
    }
  }
}

/// Helper class to categorize items based on their names/types
class ItemCategorizer {
  /// Categorize an item by its name
  static ItemCategory categorizeByName(String itemName) {
    var name = itemName.toLowerCase();
    
    // Primary weapons
    if (_isPrimaryWeapon(name)) {
      return ItemCategory.primary;
    }
    
    // Secondary weapons and magic items
    if (_isSecondaryWeapon(name) || _isMagicItem(name)) {
      return ItemCategory.secondary;
    }
    
    // Healing items
    if (_isHealingItem(name)) {
      return ItemCategory.healing;
    }
    
    // Armor
    if (_isArmor(name)) {
      return ItemCategory.armor;
    }
    
    // Treasure
    if (_isTreasure(name)) {
      return ItemCategory.treasure;
    }
    
    // Default to utility
    return ItemCategory.utility;
  }
  
  static bool _isPrimaryWeapon(String name) {
    return name.contains('sword') ||
           name.contains('axe') ||
           name.contains('mace') ||
           name.contains('hammer') ||
           name.contains('spear') ||
           name.contains('staff') ||
           name.contains('club') ||
           name.contains('blade') ||
           name.contains('rapier') ||
           name.contains('scimitar') ||
           name.contains('katana');
  }
  
  static bool _isSecondaryWeapon(String name) {
    return name.contains('bow') ||
           name.contains('crossbow') ||
           name.contains('dart') ||
           name.contains('sling') ||
           name.contains('javelin') ||
           name.contains('throwing') ||
           name.contains('dagger');
  }
  
  static bool _isMagicItem(String name) {
    return name.contains('scroll') ||
           name.contains('wand') ||
           name.contains('spell') ||
           name.contains('tome') ||
           name.contains('book') ||
           name.contains('orb');
  }
  
  static bool _isHealingItem(String name) {
    return name.contains('healing') ||
           name.contains('potion') ||
           name.contains('elixir') ||
           name.contains('balm') ||
           name.contains('salve') ||
           name.contains('medicine') ||
           name.contains('cure') ||
           name.contains('antidote') ||
           name.contains('herb') ||
           (name.contains('bread') || name.contains('food'));
  }
  
  static bool _isArmor(String name) {
    return name.contains('armor') ||
           name.contains('mail') ||
           name.contains('plate') ||
           name.contains('leather') ||
           name.contains('robe') ||
           name.contains('cloak') ||
           name.contains('shield') ||
           name.contains('helmet') ||
           name.contains('helm') ||
           name.contains('cap') ||
           name.contains('boots') ||
           name.contains('gloves') ||
           name.contains('gauntlets') ||
           name.contains('ring') ||
           name.contains('amulet');
  }
  
  static bool _isTreasure(String name) {
    return name.contains('gold') ||
           name.contains('coin') ||
           name.contains('treasure') ||
           name.contains('gem') ||
           name.contains('jewel') ||
           name.contains('diamond') ||
           name.contains('ruby') ||
           name.contains('emerald') ||
           name.contains('sapphire');
  }
}
