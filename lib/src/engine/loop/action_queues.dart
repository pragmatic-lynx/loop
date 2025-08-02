// lib/src/engine/loop/action_queues.dart

import '../core/actor.dart';
import '../core/game.dart';
import '../hero/hero.dart';
import '../items/item.dart';
import '../items/inventory.dart';
import '../action/item.dart';

import '../../content/skill/skills.dart';
import '../hero/skill.dart';
import 'debug_helper.dart';

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

/// Manages action categories for the new control scheme
/// 1 = Attack (context-aware)
/// 2 = Utility (changes based on active category: spells/utility/healing)
/// 3 = Heal (always healing items)
/// Q = Cycle categories (spells/utility/healing)
class ActionQueues {
  final Game game;
  final Hero hero;
  late final DebugHelper _debugHelper;
  
  // Active category for button 2 (1=spells, 2=utility, 3=healing)
  int _activeCategory = 2; // Start with utility
  
  // Queue positions for each category
  int _spellQueueIndex = 0;
  int _utilityQueueIndex = 0;
  int _healQueueIndex = 0;
  
  ActionQueues(this.game) : hero = game.hero {
    _debugHelper = DebugHelper(game);
  }
  
  /// Get current category name for display
  String getCategoryName() {
    switch (_activeCategory) {
      case 1:
        return "Spells";
      case 2:
        return "Utility";
      case 3:
        return "Healing";
      default:
        return "Unknown";
    }
  }
  
  /// Cycle between categories (1=spells, 2=utility, 3=healing)
  void cycleCategory() {
    _activeCategory = (_activeCategory % 3) + 1;
  }
  
  /// Get current active category
  int get activeCategory => _activeCategory;
  
  /// Get item for button 2 based on active category
  QueueItem getUtilityQueueItem() {
    switch (_activeCategory) {
      case 1: // Spells
        return _getSpellQueueItem();
      case 2: // Utility  
        return _getUtilityItem();
      case 3: // Healing items
        return _getUtilityItem(); // Show utility even when healing category is active
      default:
        return _getUtilityItem();
    }
  }
  
  /// Get item for button 3 (always healing)
  QueueItem getHealQueueItem() {
    var healItems = _getHealItems();
    if (healItems.isEmpty) {
      var currentHP = hero.health;
      var maxHP = hero.maxHealth;
      return QueueItem(
        name: "Max HP",
        count: "",
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
  
  /// Get spell item when spell category is active
  QueueItem _getSpellQueueItem() {
    var spellItems = _getSpellItems();
    if (spellItems.isEmpty) {
      return QueueItem(name: "No Spells", isAvailable: false);
    }
    
    var index = _spellQueueIndex % spellItems.length;
    var item = spellItems[index];
    return QueueItem(
      name: item.type.name,
      count: item.count > 1 ? "(${item.count})" : null,
      item: item,
    );
  }
  
  /// Get utility item when utility category is active
  QueueItem _getUtilityItem() {
    var utilityItems = _getUtilityItems();
    if (utilityItems.isEmpty) {
      return QueueItem(name: "No Utility", isAvailable: false);
    }
    
    var index = _utilityQueueIndex % utilityItems.length;
    var item = utilityItems[index];
    return QueueItem(
      name: item.type.name,
      count: item.count > 1 ? "(${item.count})" : null,
      item: item,
    );
  }
  
  /// Use the current category item
  bool useCurrentCategoryItem() {
    QueueItem item = getUtilityQueueItem();
    
    if (!item.isAvailable || item.item == null) {
      return false;
    }
    
    // Try to use the item
    var useAction = UseAction(ItemLocation.inventory, item.item!);
    useAction.bind(game, hero);
    
    var result = useAction.onPerform();
    if (result == ActionResult.success) {
      // Replace the used item
      replaceUsedItem(item.item!);
      return true;
    }
    
    return false;
  }
  
  /// Use healing item from button 3
  bool useHealItem() {
    var item = getHealQueueItem();
    
    if (!item.isAvailable || item.item == null) {
      return false;
    }
    
    // Try to use the item
    var useAction = UseAction(ItemLocation.inventory, item.item!);
    useAction.bind(game, hero);
    
    var result = useAction.onPerform();
    if (result == ActionResult.success) {
      // Replace the used item
      replaceUsedItem(item.item!);
      return true;
    }
    
    return false;
  }
  
  /// Cycle items within the current active category
  void cycleWithinCategory() {
    switch (_activeCategory) {
      case 1: // Spells
        var spellItems = _getSpellItems();
        if (spellItems.isNotEmpty) {
          _spellQueueIndex = (_spellQueueIndex + 1) % spellItems.length;
        }
        break;
      case 2: // Utility
        var utilityItems = _getUtilityItems();
        if (utilityItems.isNotEmpty) {
          _utilityQueueIndex = (_utilityQueueIndex + 1) % utilityItems.length;
        }
        break;
      case 3: // Healing
        var healItems = _getHealItems();
        if (healItems.isNotEmpty) {
          _healQueueIndex = (_healQueueIndex + 1) % healItems.length;
        }
        break;
    }
  }
  
  /// Get spell items from inventory
  List<Item> _getSpellItems() {
    var spells = <Item>[];
    
    for (var item in hero.inventory) {
      if (_isSpellItem(item)) {
        spells.add(item);
      }
    }
    
    return spells;
  }
  
  /// Check if item is a spell
  bool _isSpellItem(Item item) {
    var name = item.type.name.toLowerCase();
    return name.contains('scroll') && (
      name.contains('lightning') ||
      name.contains('fireball') ||
      name.contains('ice') ||
      name.contains('teleport') ||
      name.contains('summon') ||
      name.contains('magic') ||
      name.contains('bolt') ||
      name.contains('frost') ||
      name.contains('fire')
    );
  }
  
  /// Get utility items from inventory (non-healing consumables, scrolls, buffs, CC)
  List<Item> _getUtilityItems() {
    var utilityItems = <Item>[];
    
    for (var item in hero.inventory) {
      if (_isUtilityItem(item)) {
        utilityItems.add(item);
      }
    }
    
    return utilityItems;
  }
  
  /// Check if item is a utility item (non-healing consumable)
  bool _isUtilityItem(Item item) {
    var name = item.type.name.toLowerCase();
    
    // Include scrolls, but exclude healing scrolls and spell scrolls
    if (name.contains('scroll')) {
      // Exclude healing scrolls
      if (name.contains('heal') || name.contains('cure') || name.contains('restore')) {
        return false;
      }
      // Exclude spell scrolls (those are in spell category)
      if (_isSpellItem(item)) {
        return false;
      }
      // Include utility scrolls
      return true;
    }
    
    if (name.contains('potion')) {
      // Include buff/utility potions, exclude healing
      return !name.contains('heal') && !name.contains('cure') && !name.contains('restore') &&
             (name.contains('speed') || name.contains('strength') || name.contains('resist') ||
              name.contains('protection') || name.contains('invisibility') || name.contains('levitation'));
    }
    
    // Include other utility items like wands, tools, etc.
    return name.contains('wand') || name.contains('rod') || name.contains('orb');
  }
  
  /// Get healing items from inventory
  List<Item> _getHealItems() {
    var healingItems = <Item>[];
    
    for (var item in hero.inventory) {
      if (_isHealingItem(item)) {
        healingItems.add(item);
      }
    }
    
    return healingItems;
  }
  
  /// Check if item is healing
  bool _isHealingItem(Item item) {
    var name = item.type.name.toLowerCase();
    return name.contains('heal') || 
           name.contains('cure') || 
           name.contains('restore') ||
           name.contains('potion') && (name.contains('health') || name.contains('life'));
  }
  
  /// Calculate healing amount for an item
  int _getHealAmount(Item item) {
    // Simple heuristic based on item name and level
    var name = item.type.name.toLowerCase();
    if (name.contains('minor')) return 20;
    if (name.contains('lesser')) return 35;
    if (name.contains('major')) return 50;
    if (name.contains('greater')) return 75;
    if (name.contains('full')) return 100;
    return 30; // default
  }
  
  /// Replace used item with next available one
  void replaceUsedItem(Item usedItem) {
    // The item will naturally be removed/decremented by the use action
    // No additional logic needed here for now
  }
  
  // Legacy methods for compatibility with existing LoopGameScreen code
  
  /// Legacy method - redirect to utility for compatibility
  QueueItem getRangedQueueItem() {
    return QueueItem(name: "Use Attack Button", isAvailable: false);
  }
  
  /// Legacy method - redirect to utility for compatibility  
  QueueItem getMagicQueueItem() {
    return getUtilityQueueItem();
  }
  
  /// Legacy method - redirect to utility for compatibility
  QueueItem getResistanceQueueItem() {
    return getUtilityQueueItem();
  }
  
  /// Legacy method for compatibility
  void setCurrentQueue(int queue) {
    // No longer used with new system
  }
  
  /// Legacy method for compatibility
  int get currentQueue => _activeCategory;
  
  /// Legacy method for compatibility
  void cycleCurrentQueue() {
    cycleWithinCategory();
  }
  
  /// Legacy method for compatibility
  bool castCurrentStealthSpell() {
    return useCurrentCategoryItem();
  }
  
  /// Legacy method for compatibility
  bool autoEquipRangedWeapon() {
    return false; // Not used in new control scheme
  }
}
