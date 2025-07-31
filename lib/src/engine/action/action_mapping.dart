// lib/src/engine/action/action_mapping.dart

import '../core/game.dart';
import '../hero/hero.dart';

/// Maps simplified loop input controls to context-aware action labels
/// Provides dynamic button labeling based on hero's current state and abilities
class ActionMapping {
  final String action1Label;
  final String action2Label;
  final String action3Label;
  final String action4Label;

  ActionMapping({
    required this.action1Label,
    required this.action2Label,
    required this.action3Label,
    required this.action4Label,
  });

  /// Creates action mapping based on hero's current state and equipment
  factory ActionMapping.fromHero(Hero hero, Game game) {
    // Action 1: Primary attack/interact
    String action1 = "Attack";
    var weapons = hero.equipment.weapons;
    if (weapons.isNotEmpty) {
      action1 = "Use ${weapons.first.nounText}";
    }

    // Action 2: Secondary action (spells, special abilities)
    String action2 = "Cast";
    // TODO: Check for available spells/abilities

    // Action 3: Healing/consumables
    String action3 = "Heal";
    // TODO: Check for healing items in inventory

    // Action 4: Escape/defensive action
    String action4 = "Escape";

    return ActionMapping(
      action1Label: action1,
      action2Label: action2,
      action3Label: action3,
      action4Label: action4,
    );
  }
}
