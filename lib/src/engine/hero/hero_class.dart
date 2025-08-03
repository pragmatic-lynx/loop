import '../items/item_type.dart';
import 'skill.dart';
import 'hero_save.dart';
import '../../content/skill/spell/spell.dart';

/// The hero's class.
class HeroClass {
  final String name;

  final String description;

  final Map<Skill, double> _proficiency;

  /// Generates items a hero of this class should start with.
  final Drop startingItems;

  HeroClass(this.name, this.description, this._proficiency, this.startingItems);

  /// How adept heroes of this class are at a given skill.
  ///
  /// A proficiency of 1.0 is normal. Zero means "can't acquire at all". Numbers
  /// larger than 1.0 make the skill easier to acquire or more powerful.
  double proficiency(Skill skill) => _proficiency[skill] ?? 1.0;
  
  /// Dynamic proficiency check that considers learned spells for mages
  double dynamicProficiency(Skill skill, HeroSave? hero) {
    // For mages and spells, check if they've learned the spell
    if (name == "Mage" && skill is Spell && hero != null) {
      // Check base proficiency first
      var baseProficiency = _proficiency[skill] ?? 1.0;
      if (baseProficiency > 0.0) {
        return baseProficiency; // They have base proficiency
      }
      
      // Check if they've learned this spell through rewards
      if (hero.hasLearnedSpell(skill.name)) {
        return 1.0; // Full proficiency for learned spells
      }
      
      return 0.0; // No proficiency
    }
    
    // For non-mages or non-spells, use standard proficiency
    return proficiency(skill);
  }
}
