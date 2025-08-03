import 'package:piecemeal/piecemeal.dart';

import '../../../engine.dart';

/// Spells are the primary skill for mages.
///
/// Spells do not need to be explicitly trained or learned. As soon as one is
/// discovered, as long as it's not too complex, the hero can use it.
abstract class Spell extends Skill with UsableSkill {
  @override
  String gainMessage(int level) => '{1} have learned the spell $name.';

  @override
  String get discoverMessage => '{1} have learned the spell $name.';

  /// Spells are not leveled.
  @override
  int get maxLevel => 1;

  /// The base focus cost to cast the spell.
  int get baseFocusCost;

  /// The amount of [Intellect] the hero must possess to use this spell
  /// effectively, ignoring class proficiency.
  int get baseComplexity;

  /// The base damage of the spell, or 0 if not relevant.
  int get damage => 0;

  /// The range of the spell, or 0 if not relevant.
  int get range => 0;

  @override
  int onCalculateLevel(HeroSave hero, int points) {
    if (hero.heroClass.dynamicProficiency(this, hero) == 0.0) return 0;

    // Spells are always available once discovered.
    return 1;
  }

  @override
  int focusCost(HeroSave hero, int level) {
    var cost = baseFocusCost.toDouble();

    // Intellect makes spells cheaper, relative to their complexity.
    cost *= hero.intellect.spellFocusScale(complexity(hero.heroClass, hero: hero));

    // Spell proficiency lowers cost.
    var proficiency = hero.heroClass.dynamicProficiency(this, hero);
    if (proficiency > 0.0) {
      cost /= proficiency;
    }

    // Round up so that it always costs at least 1.
    return cost.ceil();
  }

  int complexity(HeroClass heroClass, {HeroSave? hero}) {
    var proficiency = hero != null 
        ? heroClass.dynamicProficiency(this, hero)
        : heroClass.proficiency(this);
    if (proficiency <= 0.0) proficiency = 1.0; // Prevent division by zero
    return ((baseComplexity - 9) / proficiency).round() + 9;
  }

  int getRange(Game game) => range;
}

class ActionSpell extends Spell with ActionSkill {
  @override
  final String name;

  @override
  final String description;

  @override
  final int baseComplexity;

  @override
  final int baseFocusCost;

  @override
  final int damage;

  @override
  final int range;

  final Action Function(ActionSpell spell, Game game, int level) _getAction;

  ActionSpell(this.name, this._getAction,
      {required this.description,
      required int complexity,
      required int focus,
      this.damage = 0,
      this.range = 0})
      : baseComplexity = complexity,
        baseFocusCost = focus;

  @override
  Action onGetAction(Game game, int level) => _getAction(this, game, level);
}

class TargetSpell extends Spell with TargetSkill {
  @override
  final String name;

  @override
  final String description;

  @override
  final int baseComplexity;

  @override
  final int baseFocusCost;

  @override
  final int damage;

  @override
  final int range;

  final Action Function(TargetSpell spell, Game game, int level, Vec target)
      _getAction;

  TargetSpell(this.name, this._getAction,
      {required this.description,
      required int complexity,
      required int focus,
      required this.damage,
      required this.range})
      : baseComplexity = complexity,
        baseFocusCost = focus;

  @override
  Action onGetTargetAction(Game game, int level, Vec target) =>
      _getAction(this, game, level, target);
}
