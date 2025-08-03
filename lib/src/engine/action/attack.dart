import '../core/actor.dart';
import '../stage/sound.dart';
import '../audio_manager.dart';
import '../sfx_id.dart';
import 'action.dart';

/// [Action] for a melee attack from one [Actor] to another.
class AttackAction extends Action {
  final Actor defender;

  AttackAction(this.defender);

  @override
  ActionResult onPerform() {
    // Play attack sound based on weapon type
    if (actor == game.hero) {
      // TODO: Check weapon type for different sounds
      // For now, use a generic magic hit sound for player attacks
      AudioManager.i.play(SfxId.playerMagicHit, pitchVar: 0.1);
    }

    var wasAlive = defender.isAlive;
    
    for (var hit in actor!.createMeleeHits(defender)) {
      hit.perform(this, actor, defender);
      if (!defender.isAlive) break;
    }

    // Play death sound if defender died
    if (wasAlive && !defender.isAlive) {
      AudioManager.i.play(SfxId.enemyDeath);
    }

    return ActionResult.success;
  }

  @override
  double get noise => Sound.attackNoise;

  @override
  String toString() => '$actor attacks $defender';
}
