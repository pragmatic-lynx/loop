// lib/src/engine/action/action_mapping.dart

import '../core/game.dart';
import '../hero/hero.dart';
import '../loop/action_queues.dart';

/// Maps simplified loop input controls to context-aware action labels
/// Provides dynamic button labeling for the new control scheme
class ActionMapping {
  final String attackLabel;
  final String utilityLabel;
  final String healLabel;
  final String categoryLabel;

  ActionMapping({
    required this.attackLabel,
    required this.utilityLabel,
    required this.healLabel,
    required this.categoryLabel,
  });

  /// Creates dynamic action mapping using ActionQueues
  factory ActionMapping.fromQueues(ActionQueues queues) {
    var utilityItem = queues.getUtilityQueueItem();
    var healItem = queues.getHealQueueItem();
    var categoryName = queues.getCategoryName();

    return ActionMapping(
      attackLabel: _getAttackLabel(queues.game, queues.hero),
      utilityLabel: utilityItem.displayText,
      healLabel: healItem.displayText,
      categoryLabel: "[$categoryName]",
    );
  }

  /// Get context-aware attack label
  static String _getAttackLabel(Game game, Hero hero) {
    // Check if warrior class and has adjacent enemies -> slam
    if (hero.save.heroClass.name.toLowerCase() == 'warrior') {
      if (_hasAdjacentEnemies(game, hero)) {
        return "Slam Attack";
      }
    }
    
    // Check for adjacent enemies -> melee
    if (_hasAdjacentEnemies(game, hero)) {
      return "Melee Attack";
    }
    
    // Check for bow equipped and line of sight -> bolt
    if (_hasBowEquipped(hero) && _hasRangedTarget(game, hero)) {
      return "Bow Attack";
    }
    
    // Check for spell equipped -> cast spell
    if (_hasSpellEquipped(hero)) {
      return "Cast Spell";
    }
    
    return "Attack";
  }
  
  /// Check if hero has adjacent enemies
  static bool _hasAdjacentEnemies(Game game, Hero hero) {
    for (var direction in Direction.all) {
      var pos = hero.pos + direction;
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor != hero && actor.isAlive) {
        return true;
      }
    }
    return false;
  }
  
  /// Check if hero has bow equipped
  static bool _hasBowEquipped(Hero hero) {
    for (var item in hero.equipment) {
      var name = item.type.name.toLowerCase();
      if (name.contains('bow') || name.contains('crossbow')) {
        return true;
      }
    }
    return false;
  }
  
  /// Check if hero has ranged target
  static bool _hasRangedTarget(Game game, Hero hero) {
    for (var actor in game.stage.actors) {
      if (actor == hero || !actor.isAlive) continue;
      if (game.heroCanPerceive(actor)) {
        return true;
      }
    }
    return false;
  }
  
  /// Check if hero has spell equipped
  static bool _hasSpellEquipped(Hero hero) {
    for (var item in hero.inventory) {
      var name = item.type.name.toLowerCase();
      if (name.contains('scroll') && item.use != null) {
        return true;
      }
    }
    return false;
  }

  /// Legacy method for backwards compatibility
  factory ActionMapping.fromHero(Hero hero, Game game) {
    var queues = ActionQueues(game);
    return ActionMapping.fromQueues(queues);
  }
  
  // Legacy properties for compatibility
  String get action1Label => attackLabel;
  String get action2Label => utilityLabel;
  String get action3Label => healLabel;
  String get action4Label => categoryLabel;
}
