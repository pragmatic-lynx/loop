// lib/src/engine/loop/smart_combat.dart

import '../action/action.dart';
import '../action/walk.dart';
import '../action/attack.dart';
import '../action/item.dart';
import '../core/actor.dart';
import '../core/game.dart';
import '../hero/hero.dart';
import '../stage/stage.dart';
import '../stage/tile.dart';
import '../items/item.dart';
import '../items/inventory.dart';
import '../../content/skill/skills.dart';
import 'package:piecemeal/piecemeal.dart';

/// Handles smart, automated combat decisions for roguelite loop mode
/// Takes the complexity out of skill/spell management for ADHD players
class SmartCombat {
  final Game game;
  final Hero hero;
  
  SmartCombat(this.game) : hero = game.hero;
  
  /// Handle action1 - Primary Attack/Interact
  Action? handlePrimaryAction() {
    // First check for adjacent enemies to attack
    var target = _findAdjacentEnemy();
    if (target != null) {
      return AttackAction(target);
    }
    
    // Check for items to pick up at current position
    var items = game.stage.itemsAt(hero.pos);
    if (items.isNotEmpty) {
      return PickUpAction(items.first);
    }
    
    // Check for doors/objects to operate
    var operablePos = _findOperableAdjacent();
    if (operablePos != null) {
      return game.stage[operablePos].type.onOperate!(operablePos);
    }
    
    // If nothing else, move toward nearest enemy
    var nearestEnemy = _findNearestEnemy();
    if (nearestEnemy != null) {
      var direction = _getDirectionToward(nearestEnemy.pos);
      if (direction != Direction.none) {
        return WalkAction(direction);
      }
    }
    
    return null;
  }
  
  /// Handle action2 - Secondary Attack/Spell
  Action? handleSecondaryAction() {
    // Try to cast the best offensive spell at nearest enemy
    var target = _findBestSpellTarget();
    if (target != null) {
      var spell = _getBestOffensiveSpell();
      if (spell != null) {
        return _createSpellAction(spell, target.pos);
      }
    }
    
    // If no spells, try ranged attack
    var rangedTarget = _findRangedTarget();
    if (rangedTarget != null && _hasRangedWeapon()) {
      return _createRangedAttack(rangedTarget.pos);
    }
    
    // Fall back to melee attack
    return handlePrimaryAction();
  }
  
  /// Handle action3 - Heal/Consumable
  Action? handleHealAction() {
    // Only heal if we're hurt
    if (hero.health >= hero.maxHealth * 0.8) {
      return null;
    }
    
    // Try healing potion first
    var healingPotion = _findBestHealingItem();
    if (healingPotion != null) {
      return UseAction(ItemLocation.inventory, healingPotion);
    }
    
    // Try healing spell
    var healingSpell = _getBestHealingSpell();
    if (healingSpell != null) {
      return _createSpellAction(healingSpell, hero.pos);
    }
    
    // Fall back to resting - the hero.rest() method handles this
    if (hero.rest()) {
      // rest() sets up the behavior, we don't need to return an action
      return null;
    }
    
    return null;
  }
  
  /// Handle action4 - Movement/Escape
  Action? handleEscapeAction() {
    // If we're in danger (low health, surrounded), try to escape
    if (_isInDanger()) {
      var escapeDirection = _findEscapeDirection();
      if (escapeDirection != Direction.none) {
        // Try a movement skill first
        var moveSkill = _getBestMovementSkill();
        if (moveSkill != null) {
          return _createDirectionalSpellAction(moveSkill, escapeDirection);
        }
        
        // Fall back to running
        hero.run(escapeDirection);
        return null;
      }
    }
    
    // If not in danger, use this as a positioning move
    var tacticalDirection = _findTacticalDirection();
    if (tacticalDirection != Direction.none) {
      return WalkAction(tacticalDirection);
    }
    
    return null;
  }
  
  /// Find the closest adjacent enemy
  Actor? _findAdjacentEnemy() {
    for (var direction in Direction.all) {
      var pos = hero.pos + direction;
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor != hero && actor.isAlive) {
        return actor;
      }
    }
    return null;
  }
  
  /// Find the nearest visible enemy
  Actor? _findNearestEnemy() {
    Actor? nearest;
    var nearestDistance = 999;
    
    for (var actor in game.stage.actors) {
      if (actor == hero || !actor.isAlive) continue;
      if (!game.heroCanPerceive(actor)) continue;
      
      var distance = (actor.pos - hero.pos).rookLength;
      if (distance < nearestDistance) {
        nearest = actor;
        nearestDistance = distance;
      }
    }
    
    return nearest;
  }
  
  /// Get direction toward a target position
  Direction _getDirectionToward(Vec target) {
    var diff = target - hero.pos;
    if (diff.x == 0 && diff.y == 0) return Direction.none;
    
    var dx = diff.x.sign;
    var dy = diff.y.sign;
    
    for (var direction in Direction.all) {
      if (direction.x == dx && direction.y == dy) {
        return direction;
      }
    }
    
    return Direction.none;
  }
  
  /// Check if position has something we can operate
  Vec? _findOperableAdjacent() {
    for (var direction in Direction.all) {
      var pos = hero.pos + direction;
      if (game.stage[pos].type.canOperate) {
        return pos;
      }
    }
    return null;
  }
  
  /// Find best target for offensive spells
  Actor? _findBestSpellTarget() {
    return _findNearestEnemy();
  }
  
  /// Find best target for ranged attacks
  Actor? _findRangedTarget() {
    return _findNearestEnemy();
  }
  
  /// Get the best offensive spell available
  dynamic _getBestOffensiveSpell() {
    // This is a simplified version - in full implementation,
    // would check hero.skills for actual available spells
    return null; // TODO: Implement based on actual skill system
  }
  
  /// Get the best healing spell available
  dynamic _getBestHealingSpell() {
    // TODO: Implement based on actual skill system
    return null;
  }
  
  /// Get the best movement skill available
  dynamic _getBestMovementSkill() {
    // TODO: Implement based on actual skill system
    return null;
  }
  
  /// Find the best healing item in inventory
  Item? _findBestHealingItem() {
    for (var item in hero.inventory) {
      if (item.type.name.toLowerCase().contains('healing') ||
          item.type.name.toLowerCase().contains('potion')) {
        return item;
      }
    }
    return null;
  }
  
  /// Check if we have a ranged weapon equipped
  bool _hasRangedWeapon() {
    var weapon = hero.equipment.weapon;
    if (weapon == null) return false;
    
    return weapon.type.name.toLowerCase().contains('bow') ||
           weapon.type.name.toLowerCase().contains('dart') ||
           weapon.type.name.toLowerCase().contains('sling');
  }
  
  /// Check if hero is in immediate danger
  bool _isInDanger() {
    // Low health
    if (hero.health < hero.maxHealth * 0.3) return true;
    
    // Surrounded by enemies
    var adjacentEnemies = 0;
    for (var direction in Direction.all) {
      var pos = hero.pos + direction;
      var actor = game.stage.actorAt(pos);
      if (actor != null && actor != hero && actor.isAlive) {
        adjacentEnemies++;
      }
    }
    
    return adjacentEnemies >= 3;
  }
  
  /// Find direction to escape danger
  Direction _findEscapeDirection() {
    // Try to move away from enemies
    var enemyPositions = <Vec>[];
    for (var actor in game.stage.actors) {
      if (actor != hero && actor.isAlive && game.heroCanPerceive(actor)) {
        enemyPositions.add(actor.pos);
      }
    }
    
    if (enemyPositions.isEmpty) return Direction.none;
    
    // Find direction that maximizes distance from enemies
    Direction bestDirection = Direction.none;
    var bestScore = -999;
    
    for (var direction in Direction.all) {
      var newPos = hero.pos + direction;
      if (!game.stage[newPos].canEnter(Motility.walk)) continue;
      
      var totalDistance = 0;
      for (var enemyPos in enemyPositions) {
        totalDistance += (newPos - enemyPos).rookLength;
      }
      
      if (totalDistance > bestScore) {
        bestScore = totalDistance;
        bestDirection = direction;
      }
    }
    
    return bestDirection;
  }
  
  /// Find direction for tactical positioning
  Direction _findTacticalDirection() {
    // Move toward combat if no immediate threats
    var nearestEnemy = _findNearestEnemy();
    if (nearestEnemy != null) {
      return _getDirectionToward(nearestEnemy.pos);
    }
    
    return Direction.none;
  }
  
  /// Create spell action (placeholder - needs actual skill system integration)
  Action? _createSpellAction(dynamic spell, Vec target) {
    // TODO: Integrate with actual skill system
    return null;
  }
  
  /// Create directional spell action (placeholder)
  Action? _createDirectionalSpellAction(dynamic spell, Direction direction) {
    // TODO: Integrate with actual skill system
    return null;
  }
  
  /// Create ranged attack action
  Action? _createRangedAttack(Vec target) {
    // Find the actor at the target position
    var targetActor = game.stage.actorAt(target);
    if (targetActor != null && targetActor != hero && targetActor.isAlive) {
      return AttackAction(targetActor);
    }
    return null;
  }
}
