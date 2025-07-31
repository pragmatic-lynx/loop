// lib/src/ui/loop_input.dart

/// Simplified input system for roguelite loop mode
/// Only movement + 4 action buttons for ADHD-friendly gameplay
class LoopInput {
  // Movement (keep these intuitive)
  static const n = LoopInput("n");
  static const e = LoopInput("e");
  static const s = LoopInput("s");
  static const w = LoopInput("w");
  static const ne = LoopInput("ne");
  static const nw = LoopInput("nw");
  static const se = LoopInput("se");
  static const sw = LoopInput("sw");
  static const wait = LoopInput("wait");

  // Core action buttons (1,2,3,4)
  static const action1 = LoopInput("action1");  // Primary Attack/Interact
  static const action2 = LoopInput("action2");  // Secondary Attack/Ability
  static const action3 = LoopInput("action3");  // Consumable/Heal
  static const action4 = LoopInput("action4");  // Special/Escape

  // Minimal essential controls
  static const cancel = LoopInput("cancel");    // ESC - pause/menu
  static const info = LoopInput("info");        // TAB - show info

  final String name;
  const LoopInput(this.name);

  @override
  String toString() => "LoopInput($name)";
}

/// Maps the current hero's capabilities to the 4 action buttons
class ActionMapping {
  final String action1Label;
  final String action1Description;
  final String action2Label;
  final String action2Description;
  final String action3Label;
  final String action3Description;
  final String action4Label;
  final String action4Description;

  const ActionMapping({
    required this.action1Label,
    required this.action1Description,
    required this.action2Label,
    required this.action2Description,
    required this.action3Label,
    required this.action3Description,
    required this.action4Label,
    required this.action4Description,
  });

  /// Generate action mapping based on hero's current state
  factory ActionMapping.fromHero(dynamic hero, dynamic game) {
    // Primary weapon/attack
    var primaryWeapon = _getPrimaryWeapon(hero);
    var action1Label = primaryWeapon ?? "Punch";
    
    // Best available spell/skill
    var bestSpell = _getBestSpell(hero);
    var action2Label = bestSpell ?? "Focus";
    
    // Best healing item
    var healingItem = _getBestHealing(hero);
    var action3Label = healingItem ?? "Rest";
    
    // Movement/escape ability
    var escapeAbility = _getEscapeAbility(hero);
    var action4Label = escapeAbility ?? "Dash";
    
    return ActionMapping(
      action1Label: action1Label,
      action1Description: "Attack with your weapon",
      action2Label: action2Label,
      action2Description: "Cast your best spell",
      action3Label: action3Label,
      action3Description: "Heal yourself",
      action4Label: action4Label,
      action4Description: "Move quickly or escape",
    );
  }

  static String? _getPrimaryWeapon(dynamic hero) {
    var weapon = hero.equipment.weapon;
    if (weapon != null) {
      return weapon.type.name;
    }
    return null;
  }

  static String? _getBestSpell(dynamic hero) {
    // Find the highest level offensive spell
    var spells = hero.skills.discovered.where((skill) => 
      skill.toString().contains('Spell') && 
      !skill.toString().contains('Heal')).toList();
    
    if (spells.isNotEmpty) {
      return spells.first.name;
    }
    return null;
  }

  static String? _getBestHealing(dynamic hero) {
    // Check for healing potions first
    for (var item in hero.inventory) {
      if (item.type.name.toLowerCase().contains('healing')) {
        return item.type.name;
      }
    }
    
    // Check for healing spells
    var healSpells = hero.skills.discovered.where((skill) => 
      skill.name.toLowerCase().contains('heal')).toList();
    
    if (healSpells.isNotEmpty) {
      return healSpells.first.name;
    }
    
    return null;
  }

  static String? _getEscapeAbility(dynamic hero) {
    // Check for movement abilities
    var moveSkills = hero.skills.discovered.where((skill) => 
      skill.name.toLowerCase().contains('step') ||
      skill.name.toLowerCase().contains('dash') ||
      skill.name.toLowerCase().contains('blink')).toList();
    
    if (moveSkills.isNotEmpty) {
      return moveSkills.first.name;
    }
    
    return null;
  }
}
