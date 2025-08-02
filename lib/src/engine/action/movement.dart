// lib/src/engine/action/movement.dart

import 'package:piecemeal/piecemeal.dart';

import 'action.dart';
import '../../content/action/teleport.dart';

/// Movement action that mimics Flee spell effect with cooldown
/// Hero can use this every 5 moves for tactical repositioning
class MovementAction extends Action {
  /// How many moves the hero must make before they can use movement again
  static const int cooldownMoves = 5;
  
  /// The teleport range (same as Flee spell)
  static const int range = 8;
  
  /// Track moves made since last movement ability use
  static int _movesSinceLastMovement = cooldownMoves; // Start ready

  @override
  ActionResult onPerform() {
    // Check cooldown
    if (!canUseMovement()) {
      var remaining = remainingCooldown();
      return fail("Movement not ready. Move $remaining more times.");
    }
    
    // Reset the movement counter
    _resetMovementCounter();
    
    // Use the same teleport logic as the Flee spell
    var teleportAction = TeleportAction(range);
    teleportAction.bind(game, actor);
    
    var result = teleportAction.onPerform();
    
    if (result == ActionResult.success) {
      return succeed("{1} dash[es] away swiftly!", actor);
    } else {
      return result;
    }
  }

  /// Check if the hero can use movement ability
  static bool canUseMovement() {
    return _movesSinceLastMovement >= cooldownMoves;
  }
  
  /// Get remaining moves until movement is available
  static int remainingCooldown() {
    return (cooldownMoves - _movesSinceLastMovement).clamp(0, cooldownMoves);
  }
  
  /// Reset movement counter (called when movement is used)
  static void _resetMovementCounter() {
    _movesSinceLastMovement = 0;
  }
  
  /// Record a move (called when hero moves)
  static void recordMove() {
    if (_movesSinceLastMovement < cooldownMoves) {
      _movesSinceLastMovement++;
    }
  }

  @override
  String toString() => '$actor uses movement ability';
}
