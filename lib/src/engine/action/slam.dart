// lib/src/engine/action/slam.dart

import 'package:piecemeal/piecemeal.dart';

import '../core/actor.dart';
import '../core/combat.dart';
import '../stage/sound.dart';
import 'action.dart';

/// Powerful AOE melee attack for warrior-type characters
/// Creates a cleaving effect that hits all adjacent enemies
class SlamAction extends Action {
  /// The damage multiplier for the slam attack
  static const double damageMultiplier = 1.5;
  
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
    // Initialize targets on first frame
    if (_frame == 0) {
      _findTargets();
      if (_targets.isEmpty) {
        return fail("{1} slam[s] but hit[s] nothing!", actor);
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

    return succeed("{1} unleash[es] a devastating slam!", actor);
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
