// lib/src/engine/action/slam.dart

import 'package:piecemeal/piecemeal.dart';

import '../core/actor.dart';
import '../core/combat.dart';
import '../stage/sound.dart';
import 'action.dart';

/// Powerful AOE melee attack for warrior-type characters
/// Creates a cleaving effect that hits all adjacent enemies
/// Always available with 5-move cooldown
class SlamAction extends Action {
  /// The damage multiplier for the slam attack (60% of weapon damage)
  static const double damageMultiplier = 0.6;
  
  /// How many moves the warrior must make before they can slam again
  static const int cooldownMoves = 5;
  
  /// Track moves made since last slam
  static int _movesSinceLastSlam = cooldownMoves; // Start ready
  
  /// All positions that will be affected by the slam
  final List<Vec> _targetPositions = [];
  
  /// Enemies that will be hit by the slam
  final List<Actor> _targets = [];
  
  var _frame = 0;
  static const int _animationFrames = 3;

  @override
  bool get isImmediate => false;

  @override
  ActionResult onPerform() {
    // Check cooldown
    if (!canUseSlam()) {
      var remaining = remainingSlamCooldown();
      return fail("Slam not ready. Move $remaining more times.");
    }
    
    // Initialize targets on first frame
    if (_frame == 0) {
      _findTargets();
      
      // Reset slam cooldown
      _resetSlamCounter();
      
      // If no targets, still allow the slam (it might hit something by the time animation finishes)
      if (_targets.isEmpty) {
        game.log.message("{1} slam[s] the ground powerfully!", actor);
      }
    }

    // Animate the slam over multiple frames for visual effect
    _frame++;
    
    if (_frame <= _animationFrames) {
      // Add visual effect for the slam
      for (var pos in _targetPositions) {
        // addEvent(EventType.slash, actor: actor, pos: pos); // TODO: Fix event system
      }
      
      // Deal damage on the final animation frame
      if (_frame == _animationFrames) {
        _dealDamage();
      }
      
      if (_frame < _animationFrames) {
        return ActionResult.notDone;
      }
    }

    if (_targets.isNotEmpty) {
      return succeed("{1} unleash[es] a devastating slam!", actor);
    } else {
      return succeed("{1} slam[s] with great force!", actor);
    }
  }

  /// Check if the warrior can use slam ability
  static bool canUseSlam() {
    return _movesSinceLastSlam >= cooldownMoves;
  }
  
  /// Get remaining moves until slam is available
  static int remainingSlamCooldown() {
    return (cooldownMoves - _movesSinceLastSlam).clamp(0, cooldownMoves);
  }
  
  /// Reset slam counter (called when slam is used)
  static void _resetSlamCounter() {
    _movesSinceLastSlam = 0;
  }
  
  /// Record a move (called when warrior moves)
  static void recordMove() {
    if (_movesSinceLastSlam < cooldownMoves) {
      _movesSinceLastSlam++;
    }
  }
  
  /// Find all adjacent enemies to target
  void _findTargets() {
    var heroPos = actor!.pos;
    
    // Check all 8 adjacent directions
    for (var direction in Direction.all) {
      var targetPos = heroPos + direction;
      
      // Skip if out of bounds
      if (!game.stage.bounds.contains(targetPos)) continue;
      
      _targetPositions.add(targetPos);
      
      // Check for actors at this position
      var targetActor = game.stage.actorAt(targetPos);
      if (targetActor != null && targetActor != actor && targetActor.isAlive) {
        _targets.add(targetActor);
      }
    }
  }

  /// Deal enhanced damage to all targets
  void _dealDamage() {
    for (var target in _targets) {
      if (!target.isAlive) continue;
      
      // Create enhanced melee hits
      var hits = actor!.createMeleeHits(target);
      
      for (var hit in hits) {
        // Increase damage for slam attack
        hit.scaleDamage(damageMultiplier);
        hit.perform(this, actor, target);
        
        if (!target.isAlive) break;
      }
    }
  }

  @override
  double get noise => Sound.attackNoise * 1.5; // Louder than normal attack

  @override
  String toString() => '$actor performs a devastating slam';
}
