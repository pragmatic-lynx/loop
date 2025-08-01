import '../core/element.dart';
import '../core/log.dart';
import '../core/option.dart';
import '../items/equipment.dart';
import '../items/inventory.dart';
import '../items/shop.dart';
import 'hero.dart';
import 'hero_class.dart';
import 'lore.dart';
import 'race.dart';
import 'skill.dart';
import 'stat.dart';

/// When the player is playing the game inside a dungeon, he is using a [Hero].
/// When outside of the dungeon on the menu screens, though, only a subset of
/// the hero's data persists (for example, there is no position when not in a
/// dungeon). This class stores that state.
// TODO: This is no longer true with the town. Now that the game plays more like
// a classic roguelike, it's weird that some hero state (hunger, log,
// conditions) evaporates when the hero leaves and enters the dungeon. Need to
// figure out what gets saved and what doesn't now.
class HeroSave {
  final String name;
  final RaceStats race;
  final HeroClass heroClass;

  /// If `true`, then the hero is deleted from storage when they die.
  final bool permadeath;

  /// Number of level-ups pending to be displayed at end of loop
  int pendingLevels = 0;

  int get level => experienceLevel(experience);

  var _inventory = Inventory(ItemLocation.inventory, Option.inventoryCapacity);

  Inventory get inventory => _inventory;

  var _equipment = Equipment();

  Equipment get equipment => _equipment;

  /// Items in the hero's home.
  Inventory get home => _home;
  var _home = Inventory(ItemLocation.home, Option.homeCapacity);

  /// Items in the hero's crucible.
  Inventory get crucible => _crucible;
  var _crucible = Inventory(ItemLocation.crucible, Option.crucibleCapacity);

  /// The current inventories of all the shops.
  final Map<Shop, Inventory> shops;

  int experience = 0;

  SkillSet skills;

  /// How much gold the hero has.
  int gold = Option.heroGoldStart;

  /// The lowest depth that the hero has successfully explored and exited.
  int maxDepth = 0;

  final Log log;

  final Lore lore;

  final strength = Strength();
  final agility = Agility();
  final fortitude = Fortitude();
  final intellect = Intellect();
  final will = Will();

  int get emanationLevel {
    var level = 0;

    // Add the emanation of all equipment.
    for (var item in equipment) {
      level += item.emanationLevel;
    }

    return level;
  }

  int get armor {
    var total = 0;
    for (var item in equipment) {
      total += item.armor;
    }

    for (var skill in skills.acquired) {
      total = skill.modifyArmor(this, skills.level(skill), total);
    }

    return total;
  }

  /// The total weight of all equipment.
  int get weight {
    var total = 0;
    for (var item in equipment) {
      total += item.weight;
    }

    return total;
  }

  HeroSave.create(this.name, Race race, this.heroClass,
      {this.permadeath = false})
      : race = race.rollStats(),
        shops = {},
        skills = SkillSet(),
        log = Log(),
        lore = Lore() {
    strength.refresh(this);
    agility.refresh(this);
    fortitude.refresh(this);
    intellect.refresh(this);
    will.refresh(this);
  }

  HeroSave(
      this.name,
      this.race,
      this.heroClass,
      this.permadeath,
      this._inventory,
      this._equipment,
      this._home,
      this._crucible,
      this.shops,
      this.experience,
      this.skills,
      this.log,
      this.lore,
      this.gold,
      this.maxDepth) {
    strength.refresh(this);
    agility.refresh(this);
    fortitude.refresh(this);
    intellect.refresh(this);
    will.refresh(this);
  }

  HeroSave clone() => HeroSave(
      name,
      race,
      heroClass,
      permadeath,
      inventory.clone(),
      equipment.clone(),
      // TODO: Assumes home doesn't change in game.
      home,
      // TODO: Assumes home doesn't change in game.
      crucible,
      // TODO: Assumes shops don't change in game.
      shops,
      experience,
      skills.clone(),
      // Don't clone the log. The log is persistent even when the Hero dies in
      // the dungeon, so all HeroSaves share the same object.
      log,
      lore.clone(),
      gold,
      maxDepth);

  /// Gets the total permament resistance provided by all equipment.
  int equipmentResistance(Element element) {
    // TODO: If class or race can affect this, add it in.
    var resistance = 0;

    for (var item in equipment) {
      resistance += item.resistance(element);
    }

    // TODO: Unify this with onDefend().

    return resistance;
  }

  /// Gets the total modifiers to [stat] provided by all equipment.
  int statBonus(Stat stat) {
    var bonus = 0;

    // Let equipment modify it.
    for (var item in equipment) {
      for (var affix in item.affixes) {
        bonus += affix.statBonus(stat);
      }
    }

    return bonus;
  }
}
