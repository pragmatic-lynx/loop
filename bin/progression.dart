import 'package:loop_rpg/src/content.dart';
import 'package:loop_rpg/src/engine.dart';

/// Tracks what level the hero reaches if they kill every monster in every
/// generated dungeon going down.
void main() {
  var content = createContent();
  var save = content.createHero("Fred",
      race: content.races[4], heroClass: content.classes[1]);
  for (var level = 1; level <= Option.maxDepth; level++) {
    var game = Game(content, level, save);
    for (var _ in game.generate()) {}

    var hero = game.hero;
    for (var actor in game.stage.actors) {
      if (actor is Monster) {
        var attack = AttackAction(actor);
        attack.bind(game, hero);
        hero.seeMonster(actor);
        hero.onKilled(attack, actor);
      }
    }

    var bar = "*" * hero.level;
    print("${level.toString().padLeft(3)} "
        "${hero.level.toString().padLeft(3)} $bar");
  }
}
