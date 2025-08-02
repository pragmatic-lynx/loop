import '../engine.dart';
import 'item/drops.dart';
import 'skill/discipline/mastery.dart';
import 'skill/skills.dart';
import 'skill/spell/spell.dart';

class Classes {
  // TODO: Tune battle-hardening.
  // TODO: Better starting items?
  static final ranger = _class("Ranger", parseDrop("item"),
      masteries: 0.5,
      spells: 0.2,
      description:
          "Rangers are skilled wilderness survivors who have learned to thrive "
          "in the untamed lands beyond civilization. Through years of "
          "experience in the wild, they have developed keen instincts, "
          "adaptability, and a deep understanding of nature's ways. Rangers "
          "are versatile fighters who can track prey, navigate treacherous "
          "terrain, and survive where others would perish.");

  static final warrior = _class("Warrior", parseDrop("weapon"),
      masteries: 1.0,
      spells: 0.0,
      description: "It's not that warriors are "
          "stupid. Many are, in fact, quite intelligent. It's just that they "
          "tend to apply most of that intelligence towards deciding which "
          "weapon is best suited for splitting a monster's head open.\n\n"
          "Warriors rely on the might of their bodies and the reassuring heft "
          "of their equipment. While they aren't above using a little magic "
          "here and there, they're most comfortable when those supernatural "
          "forces are safely ensconced in a piece of familiar gear.");

  // TODO: Different book for generalist mage versus sorceror?
  static final mage = _class(
      "Mage", parseDrop("Spellbook \"Elemental Primer\""),
      masteries: 0.2,
      spells: 1.0,
      description:
          "Where others rightly fear the awesome power and unpredictability of "
          "magic, mages see it as a source of personal power and glory. Magic "
          "demands great sacrifices of anyone who dares to wield it directly. "
          "Mages who have devoted their lives to it have little time to master "
          "other arts and skills. But the rewards in return can be great for "
          "anyone willing to dance with the raw forces of nature (as well as "
          "some less natural forces).");

  // TODO: Add these once their skill types are working.
  //  static final rogue = new HeroClass("Rogue", "TODO");
  //  static final priest = new HeroClass("Priest", "TODO");

  // TODO: Specialist subclasses.

  /// All of the known classes.
  static final List<HeroClass> all = [ranger, warrior, mage];
}

HeroClass _class(String name, Drop startingItems,
    {required double masteries,
    required double spells,
    required String description}) {
  var proficiencies = <Skill, double>{};

  for (var skill in Skills.all) {
    var proficiency = 1.0;
    if (skill is MasteryDiscipline) proficiency *= masteries;
    if (skill is Spell) proficiency *= spells;

    proficiencies[skill] = proficiency;
  }

  return HeroClass(name, description, proficiencies, startingItems);
}
