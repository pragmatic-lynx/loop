import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';

/// Fires a bolt, a straight line of an elemental attack that stops at the
/// first [Actor] is hits or opaque tile.
class BoltAction extends LosAction {
  final Hit _hit;
  final bool _canMiss;
  final int? _range;

  @override
  int get range => _range ?? _hit.range;

  BoltAction(super.target, this._hit, {bool canMiss = false, int? range})
      : _canMiss = canMiss,
        _range = range;

  @override
  ActionResult onPerform() {
    // Play spell cast sound when the bolt action starts
    if (actor == game.hero) {
      AudioManager.i.play(SfxId.playerMagicCast);
    }
    
    return super.onPerform();
  }

  @override
  void onStep(Vec previous, Vec pos) {
    addEvent(EventType.bolt,
        element: _hit.element,
        pos: pos,
        dir: (pos - previous).nearestDirection);
  }

  @override
  bool onHitActor(Vec pos, Actor target) {
    // Play spell hit sound when bolt hits an actor
    if (actor == game.hero) {
      AudioManager.i.play(SfxId.playerMagicHit, pitchVar: 0.1);
    }

    // TODO: Should range increase odds of missing? If so, do that here. Also
    // need to tweak enemy AI then since they shouldn't always try to maximize
    // distance.
    _hit.perform(this, actor, target, canMiss: _canMiss);
    return true;
  }
}
