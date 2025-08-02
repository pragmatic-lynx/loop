import 'dart:convert';
import 'dart:math' as math;

import 'package:piecemeal/piecemeal.dart';

import '../action/action.dart';
import '../core/actor.dart';
import '../core/combat.dart';
import '../core/constants.dart';
import '../core/element.dart';
import '../core/energy.dart';
import '../core/game.dart';
import '../core/log.dart';
import '../core/option.dart';
import '../items/equipment.dart';
import '../items/inventory.dart';
import '../items/item.dart';
import '../monster/monster.dart';
import '../stage/tile.dart';
import 'achievement_tracker.dart';
import 'behavior.dart';
import 'hero_save.dart';
import 'lore.dart';
import 'skill.dart';
import 'stat.dart';

/// The main player-controlled [Actor]. The player's avatar in the game world.
class Hero extends Actor {
  /// The highest level the hero can reach.
  static const maxLevel = 50;

  final HeroSave save;

  /// Monsters the hero has already seen. Makes sure we don't double count them.
  final Set<Monster> _seenMonsters = {};

  /// XP curve table loaded from assets or defaults
  List<int> xpTable = GameConstants.defaultXpCurve;

  Behavior? _behavior;

  /// Damage scale for wielded weapons based on strength, their combined heft,
  /// skills, etc.
  final Property<double> _heftDamageScale = Property();
  double get heftDamageScale => _heftDamageScale.value;

  /// How full the hero is.
  ///
  /// The hero raises this by eating food. It reduces constantly. The hero can
  /// only rest while its non-zero.
  ///
  /// It starts half-full, presumably the hero had a nice meal before heading
  /// off to adventure.
  // TODO: This should be in HeroSave.
  int get stomach => _stomach;

  set stomach(int value) => _stomach = value.clamp(0, Option.heroMaxStomach);
  int _stomach = Option.heroMaxStomach ~/ 2;

  /// How calm and centered the hero is. Mental skills like spells spend focus.
  int get focus => _focus;
  int _focus = 0;

  /// How enraged the hero is.
  ///
  /// Each level increases the damage multiplier for melee damage.
  int get fury => _fury;
  int _fury = 0;

  /// The number of hero turns since they last took a hit that caused them to
  /// lose focus.
  int _turnsSinceLostFocus = 0;

  /// The number of hero turns since they last dealt damage to a monster.
  int _turnsSinceGaveDamage = 100;

  /// How much noise the Hero's last action made.
  double get lastNoise => _lastNoise;
  double _lastNoise = 0.0;

  @override
  String get nounText => 'you';

  @override
  Pronoun get pronoun => Pronoun.you;

  Inventory get inventory => save.inventory;

  Equipment get equipment => save.equipment;

  int get experience => save.experience;

  set experience(int value) => save.experience = value;

  SkillSet get skills => save.skills;

  int get gold => save.gold;

  set gold(int value) => save.gold = value;

  Lore get lore => save.lore;

  @override
  int get maxHealth => fortitude.maxHealth;

  Strength get strength => save.strength;

  Agility get agility => save.agility;

  Fortitude get fortitude => save.fortitude;

  Intellect get intellect => save.intellect;

  Will get will => save.will;

  // TODO: Equipment and items that let the hero swim, fly, etc.
  @override
  Motility get motility => Motility.doorAndWalk;

  @override
  int get emanationLevel => save.emanationLevel;

  /// All [Skill]s in the game.
  final Iterable<Skill> _allSkills;

  Hero(Vec pos, this.save, this._allSkills) : super(pos.x, pos.y) {
    // Give the hero energy so they can act before all of the monsters.
    energy.energy = Energy.actionCost;

    // Try to load XP curve from assets
    _loadXpCurve();

    refreshProperties();

    // Set the meters now that we know the stats.
    health = maxHealth;
    _focus = intellect.maxFocus;
  }

  // TODO: Hackish.
  @override
  Object get appearance => 'hero';

  @override
  bool needsInput(Game game) {
    if (_behavior != null && !_behavior!.canPerform(game, this)) {
      waitForInput();
    }

    return _behavior == null;
  }

  /// The hero's experience level.
  int get level => _level.value;
  final _level = Property<int>();

  @override
  int get armor => save.armor;

  /// The total weight of all equipment.
  int get weight => save.weight;

  // TODO: Not currently used since skills are not explicitly learned in the
  // UI. Re-enable when we add rogue skills?
  /*
  /// Updates the hero's skill levels to [skills] and apply any other changes
  /// caused by that.
  void updateSkills(SkillSet skills) {
    // Update anything affected.
    this.skills.update(skills);
  }
  */

  // TODO: The set of skills discovered from items should probably be stored in
  // lore. Then the skill levels can be stored using Property and refreshed
  // like other properties.
  /// Discover or acquire any skills associated with [item].
  void _gainItemSkills(Game game, Item item) {
    for (var skill in item.type.skills) {
      if (save.heroClass.proficiency(skill) != 0.0 && skills.discover(skill)) {
        // See if the hero can immediately use it.
        var level = skill.calculateLevel(save);
        if (skills.gain(skill, level)) {
          game.log.gain(skill.gainMessage(level), this);
        } else {
          game.log.gain(skill.discoverMessage, this);
        }
      }
    }
  }

  @override
  int get baseSpeed => Energy.normalSpeed;

  @override
  int get baseDodge => 20 + agility.dodgeBonus;

  @override
  Iterable<Defense> onGetDefenses() sync* {
    for (var item in equipment) {
      var defense = item.defense;
      if (defense != null) yield defense;
    }

    for (var skill in skills.acquired) {
      var defense = skill.getDefense(this, skills.level(skill));
      if (defense != null) yield defense;
    }

    // TODO: Temporary bonuses, etc.
  }

  @override
  Action onGetAction(Game game) => _behavior!.getAction(this);

  @override
  List<Hit> onCreateMeleeHits(Actor? defender) {
    var hits = <Hit>[];

    // See if any melee weapons are equipped.
    var weapons = equipment.weapons.toList();
    for (var i = 0; i < weapons.length; i++) {
      var weapon = weapons[i];
      if (weapon.attack!.isRanged) continue;

      var hit = weapon.attack!.createHit();

      weapon.modifyHit(hit);

      // Take heft and strength into account.
      hit.scaleDamage(_heftDamageScale.value);
      hits.add(hit);
    }

    // If not, punch it.
    if (hits.isEmpty) {
      hits.add(Attack(this, 'punch[es]', Option.heroPunchDamage).createHit());
    }

    for (var hit in hits) {
      hit.addStrike(agility.strikeBonus);

      for (var skill in skills.acquired) {
        skill.modifyAttack(
            this, defender as Monster?, hit, skills.level(skill));
      }

      // Scale damage by fury.
      hit.scaleDamage(strength.furyScale(fury));
    }

    return hits;
  }

  Hit createRangedHit() {
    var weapons = equipment.weapons.toList();
    var i = weapons.indexWhere((weapon) => weapon.attack!.isRanged);
    assert(i != -1, "Should have ranged weapon equipped.");

    var hit = weapons[i].attack!.createHit();

    // Take heft and strength into account.
    hit.scaleDamage(_heftDamageScale.value);

    modifyHit(hit, HitType.ranged);
    return hit;
  }

  /// Applies the hero-specific modifications to [hit].
  @override
  void onModifyHit(Hit hit, HitType type) {
    // TODO: Use agility to affect strike.

    switch (type) {
      case HitType.melee:
        break;

      case HitType.ranged:
        // TODO: Use strength to affect range.
        // TODO: Take heft into account.
        break;

      case HitType.toss:
        hit.scaleRange(strength.tossRangeScale);
    }

    // Let armor modify it. We don't worry about weapons here since the weapon
    // modified it when the hit was created. This ensures that when
    // dual-wielding, that one weapon's modifiers don't affect the other.
    for (var item in equipment) {
      if (item.type.weaponType == null) item.modifyHit(hit);
    }

    // TODO: Apply skills.
  }

  // TODO: If class or race can affect this, add it in.
  @override
  int onGetResistance(Element element) => save.equipmentResistance(element);

  @override
  void onGiveDamage(Action action, Actor defender, int damage) {
    // Hitting starts or continues the fury chain.
    _turnsSinceGaveDamage = 0;
  }

  @override
  void onTakeDamage(Action action, Actor? attacker, int damage) {
    // Getting hit loses focus.
    // TODO: Lose less focus for ranged attacks?
    var focus = (damage / maxHealth * will.damageFocusScale).ceil();
    _focus = (_focus - focus).clamp(0, intellect.maxFocus);

    _turnsSinceLostFocus = 0;

    // TODO: Would be better to do skills.discovered, but right now this also
    // discovers BattleHardening.
    for (var skill in _allSkills) {
      skill.takeDamage(this, damage);
    }
  }

  @override
  void onKilled(Action action, Actor defender) {
    var monster = defender as Monster;

    // Killing starts or continues the fury chain.
    _turnsSinceGaveDamage = 0;

    // It only counts if the hero's seen the monster at least once.
    if (!_seenMonsters.contains(monster)) return;

    lore.slay(monster.breed);

    // Track enemy kill globally for achievements
    AchievementTracker.trackEnemySlain(monster.breed);

    for (var skill in skills.discovered) {
      skill.killMonster(this, action, monster);
    }

    gainExperience(monster.experience);
  }

  @override
  void onDied(Action action, Noun attackNoun) {
    action.log("{1} [were|was] slain by {2}.", this, attackNoun);
  }

  @override
  void onFinishTurn(Action action) {
    // Make some noise.
    _lastNoise = action.noise;

    // Update fury.
    if (_turnsSinceGaveDamage == 0) {
      // Every turn the hero harmed a monster increases fury.
      _fury++;
    } else if (_turnsSinceGaveDamage > 1) {
      // Otherwise, it decays, with a one turn grace period.
      // TODO: Maybe have higher will slow the decay rate.
      _fury -= _turnsSinceGaveDamage - 1;
    }

    _fury = _fury.clamp(0, strength.maxFury);

    _turnsSinceGaveDamage++;
    _turnsSinceLostFocus++;

    // TODO: Passive skills?
  }

  @override
  void onChangePosition(Game game, Vec from, Vec to) {
    game.stage.heroVisibilityChanged();
  }

  void waitForInput() {
    _behavior = null;
  }

  void setNextAction(Action action) {
    _behavior = ActionBehavior(action);
  }

  /// Starts resting, if the hero has eaten and is able to regenerate.
  bool rest() {
    if (poison.isActive) {
      save.log
          .error("You cannot rest while poison courses through your veins!");
      return false;
    }

    if (health == maxHealth) {
      save.log.message("You are fully rested.");
      return false;
    }

    if (stomach == 0) {
      save.log.error("You are too hungry to rest.");
      return false;
    }

    _behavior = RestBehavior();
    return true;
  }

  void run(Direction direction) {
    _behavior = RunBehavior(direction);
  }

  void disturb() {
    if (_behavior is! ActionBehavior) waitForInput();
  }

  void seeMonster(Monster monster) {
    // TODO: Blindness and dazzle.

    if (_seenMonsters.add(monster)) {
      // TODO: If we want to give the hero experience for seeing a monster too,
      // (so that sneak play-style still lets the player gain levels), do that
      // here.
      lore.seeBreed(monster.breed);

      // If this is the first time we've seen this breed, see if that unlocks
      // a slaying skill for it.
      if (lore.seenBreed(monster.breed) == 1) {
        for (var skill in _allSkills) {
          skill.seeBreed(this, monster.breed);
        }
      }
    }
  }

  /// Spends focus on some useful action.
  ///
  /// Does not reset [_turnsSinceLostFocus].
  void spendFocus(int focus) {
    assert(_focus >= focus);

    _focus -= focus;
  }

  void regenerateFocus(int focus) {
    // The longer the hero goes without losing focus, the more quickly it
    // regenerates.
    var scale = (_turnsSinceLostFocus + 1).clamp(1, 8) / 4;
    _focus = (_focus + focus * scale).ceil().clamp(0, intellect.maxFocus);
  }

  /// Loads XP curve from assets or falls back to defaults
  void _loadXpCurve() {
    // Try to load from assets/xp_curve.json
    try {
      // In a web environment, we'd need to use HTTP requests to load assets
      // For now, use the default curve as fallback
      // TODO: Implement proper asset loading for web deployment
      xpTable = GameConstants.defaultXpCurve;
      
      // Log that we're using default curve
      print('Using default XP curve (${xpTable.length} levels)');
    } catch (e) {
      // Fallback to default curve if loading fails
      xpTable = GameConstants.defaultXpCurve;
      print('Failed to load XP curve from assets, using defaults: $e');
    }
  }

  /// Gains experience and handles immediate level-ups
  void gainExperience(int amount) {
    if (amount <= 0) return;
    
    var oldLevel = level;
    experience += amount;
    var newLevel = _calculateLevel(experience);
    
    if (newLevel > oldLevel) {
      save.pendingLevels += newLevel - oldLevel;
      
      // Show quick toast notification for level-up
      save.log.gain('You reached level $newLevel!');
      
      // TODO: Play level-up sound effect (levelup.ogg)
    }
    
    refreshProperties();
  }
  
  /// Calculate level from experience using XP table
  int _calculateLevel(int exp) {
    for (var level = 1; level < xpTable.length; level++) {
      if (exp < xpTable[level]) return level - 1;
    }
    return xpTable.length - 1;
  }

  /// Refreshes all hero state whose change should be logged.
  ///
  /// For example, if the hero equips a helm that increases intellect, we want
  /// to log that. Likewise, if they level up and their strength increases. Or
  /// maybe a ghost drains their experience, which lowers their level, which
  /// reduces dexterity.
  ///
  /// To track that, any calculated property whose change should be noted is
  /// wrapped in a [Property] and updated here. Note that order that these are
  /// updated matters. Properties must be updated after the properties they
  /// depend on.
  void refreshProperties() {
    var level = experienceLevel(experience);
    _level.update(level, (previous) {
      save.log.gain('You have reached level $level.');
      // TODO: Different message if level went down.
    });

    strength.refresh(save);
    agility.refresh(save);
    fortitude.refresh(save);
    intellect.refresh(save);
    will.refresh(save);

    // Refresh the heft scales.
    var weapons = equipment.weapons.toList();

    if (weapons.length > 1) {
      // Discover the dual-wield skill.
      // TODO: This is a really specific method to put on Skill. Is there a
      // cleaner way to handle this?
      for (var skill in _allSkills) {
        skill.dualWield(this);
      }
    }

    var heftModifier = 1.0;
    for (var skill in skills.acquired) {
      heftModifier = skill.modifyHeft(this, skills.level(skill), heftModifier);
    }

    // When dual-wielding, it's as if each weapon has an individual heft that
    // is the total of both of them.
    var totalHeft = 0;
    for (var weapon in weapons) {
      totalHeft += weapon.heft;
    }

    var heftScale = strength.heftScale((totalHeft * heftModifier).round());
    _heftDamageScale.update(heftScale, (previous) {
      // No longer show messages about being too weak to wield weapons
      // All weapons are now effectively wieldable
    });

    // See if any skills changed. (Gaining intellect learns spells.)
    _refreshSkills();

    // Keep other stats in bounds.
    health = health.clamp(0, maxHealth);
    _focus = _focus.clamp(0, intellect.maxFocus);
    _fury = _fury.clamp(0, strength.maxFury);
  }

  /// Called when the hero holds an item.
  ///
  /// This can be in response to picking it up, or equipping or using it
  /// straight from the ground.
  void pickUp(Game game, Item item) {
    // TODO: If the user repeatedly picks up and drops the same item, it gets
    // counted every time. Maybe want to put a (serialized) flag on items for
    // whether they have been picked up or not.
    lore.findItem(item);

    // Track item globally for achievements
    AchievementTracker.trackItemFound(item);

    _gainItemSkills(game, item);
    
    // Try to auto-equip the item if it's equipment
    _tryAutoEquip(game, item);
    
    refreshProperties();
  }

  /// Tries to auto-equip an item if it's better than what's currently equipped.
  void _tryAutoEquip(Game game, Item item) {
    print('[AUTO-EQUIP] Checking item: ${item.nounText}');
    
    // Only try to auto-equip equippable items
    if (!item.canEquip) {
      print('[AUTO-EQUIP] Item cannot be equipped, skipping');
      return;
    }
    
    if (!equipment.canEquip(item)) {
      print('[AUTO-EQUIP] Equipment cannot equip this item type, skipping');
      return;
    }
    
    var equipSlot = item.equipSlot!;
    print('[AUTO-EQUIP] Item equip slot: $equipSlot, item type: ${_getItemType(item)}');
    
    // Find current item in this slot
    Item? currentItem;
    for (var i = 0; i < equipment.slotTypes.length; i++) {
      if (equipment.slotTypes[i] == equipSlot && equipment.slots[i] != null) {
        currentItem = equipment.slots[i];
        break;
      }
    }
    
    if (currentItem == null) {
      // Empty slot - always equip
      print('[AUTO-EQUIP] Empty slot found, equipping item');
      _autoEquipItem(game, item);
      return;
    }
    
    print('[AUTO-EQUIP] Current item in slot: ${currentItem.nounText}, type: ${_getItemType(currentItem)}');
    
    // Compare items to see if new one is better
    if (_isItemBetter(item, currentItem)) {
      print('[AUTO-EQUIP] New item is better, auto-equipping');
      _autoEquipItem(game, item);
    } else {
      print('[AUTO-EQUIP] Current item is better, keeping it equipped');
    }
  }
  
  /// Determine the general type of an item for debugging.
  String _getItemType(Item item) {
    if (item.attack != null) return 'weapon';
    if (item.baseArmor > 0) return 'armor';
    return 'other';
  }
  
  /// Determines if the new item is better than the current item.
  bool _isItemBetter(Item newItem, Item currentItem) {
    // For weapons, compare damage potential and attributes
    if (newItem.attack != null || currentItem.attack != null) {
      return _compareWeapons(newItem, currentItem);
    }
    
    // For armor items, prioritize armor value
    if (newItem.baseArmor > 0 || currentItem.baseArmor > 0) {
      return _compareArmor(newItem, currentItem);
    }
    
    // For other equipment (rings, necklaces, etc.), use price as primary comparison
    print('[AUTO-EQUIP] Other equipment, comparing price: new=${newItem.price} vs current=${currentItem.price}');
    if (newItem.price != currentItem.price) {
      return newItem.price > currentItem.price;
    }
    
    // If price is equal, prefer lighter items
    print('[AUTO-EQUIP] Price equal, comparing weight: new=${newItem.weight} vs current=${currentItem.weight}');
    return newItem.weight < currentItem.weight;
  }
  
  /// Compare two weapons to determine which is better.
  bool _compareWeapons(Item newWeapon, Item currentWeapon) {
    // Calculate base damage potential
    var newDamage = newWeapon.attack?.damage ?? 0;
    var currentDamage = currentWeapon.attack?.damage ?? 0;
    
    print('[AUTO-EQUIP] Comparing weapons - new damage: $newDamage, current damage: $currentDamage');
    
    if (newDamage != currentDamage) {
      return newDamage > currentDamage;
    }
    
    // If damage is equal, compare price (accounts for affixes and quality)
    if (newWeapon.price != currentWeapon.price) {
      print('[AUTO-EQUIP] Weapon damage equal, comparing price: new=${newWeapon.price} vs current=${currentWeapon.price}');
      return newWeapon.price > currentWeapon.price;
    }
    
    // If price is equal, prefer lighter weapons
    print('[AUTO-EQUIP] Weapon damage and price equal, comparing weight: new=${newWeapon.weight} vs current=${currentWeapon.weight}');
    return newWeapon.weight < currentWeapon.weight;
  }
  
  /// Compare two armor items to determine which is better.
  bool _compareArmor(Item newArmor, Item currentArmor) {
    var newArmorValue = newArmor.armor;
    var currentArmorValue = currentArmor.armor;
    
    print('[AUTO-EQUIP] Comparing armor: new=$newArmorValue vs current=$currentArmorValue');
    
    if (newArmorValue != currentArmorValue) {
      return newArmorValue > currentArmorValue;
    }
    
    // If armor is equal, prefer lighter items
    if (newArmor.weight != currentArmor.weight) {
      print('[AUTO-EQUIP] Armor equal, comparing weight: new=${newArmor.weight} vs current=${currentArmor.weight}');
      return newArmor.weight < currentArmor.weight;
    }
    
    // If armor and weight are equal, prefer more expensive items (better affixes)
    print('[AUTO-EQUIP] Armor and weight equal, comparing price: new=${newArmor.price} vs current=${currentArmor.price}');
    return newArmor.price > currentArmor.price;
  }
  
  /// Actually equips the item and handles any unequipped items.
  void _autoEquipItem(Game game, Item item) {
    try {
      // Create a single-count item for equipping if this is a stack
      Item itemToEquip;
      if (item.count > 1) {
        print('[AUTO-EQUIP] Splitting stack to equip single item');
        itemToEquip = item.splitStack(1);
        inventory.countChanged();
      } else {
        // Remove the item from inventory first (it should be there from pickup)
        var foundInInventory = false;
        for (var i = 0; i < inventory.length; i++) {
          if (inventory[i] == item) {
            inventory.removeAt(i);
            foundInInventory = true;
            break;
          }
        }
        
        if (!foundInInventory) {
          print('[AUTO-EQUIP] Warning: Item not found in inventory, still attempting to equip');
        }
        
        itemToEquip = item;
      }
      
      // Equip the item
      var unequippedItems = equipment.equip(itemToEquip);
      
      // Handle any unequipped items
      for (var unequippedItem in unequippedItems) {
        var result = inventory.tryAdd(unequippedItem, wasUnequipped: true);
        if (result.remaining == 0) {
          game.log.message('${unequippedItem.nounText} was unequipped.');
        } else {
          // No room in inventory, drop it
          game.stage.addItem(unequippedItem, pos);
          game.log.message('${unequippedItem.nounText} was unequipped and dropped to the ground.');
        }
      }
      
      game.log.message('You auto-equipped ${itemToEquip.nounText}.');
      print('[AUTO-EQUIP] Successfully equipped: ${itemToEquip.nounText}');
      
      // Update emanation if needed
      if (itemToEquip.emanationLevel > 0) {
        game.stage.actorEmanationChanged();
      }
      
    } catch (e) {
      print('[AUTO-EQUIP] Error during auto-equip: $e');
      game.log.error('Failed to auto-equip ${item.nounText}.');
    }
  }

  /// See if any known skills have leveled up.
  void _refreshSkills() {
    skills.discovered.forEach(refreshSkill);
  }

  /// Ensures the hero has discovered [skill] and logs if it is the first time
  /// it's been seen.
  void discoverSkill(Skill skill) {
    if (save.heroClass.proficiency(skill) == 0.0) return;

    if (!skills.discover(skill)) return;

    save.log.gain(skill.discoverMessage, this);
  }

  void refreshSkill(Skill skill) {
    var level = skill.calculateLevel(save);
    if (skills.gain(skill, level)) {
      save.log.gain(skill.gainMessage(level), this);
    }
  }
}

int experienceLevel(int experience) {
  // Use default curve for backwards compatibility
  var curve = GameConstants.defaultXpCurve;
  for (var level = 1; level < curve.length; level++) {
    if (experience < curve[level]) return level - 1;
  }
  return curve.length - 1;
}

/// Returns how much experience is needed to reach [level].
int experienceLevelCost(int level) {
  var curve = GameConstants.defaultXpCurve;
  if (level >= curve.length) return curve.last;
  return curve[level];
}
