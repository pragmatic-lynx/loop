// lib/src/engine/action/action_mapping.dart

import '../core/game.dart';
import '../hero/hero.dart';
import '../loop/smart_combat.dart';

/// Maps simplified loop input controls to context-aware action labels
/// Provides dynamic button labeling based on SmartCombat analysis
class ActionMapping {
  final String action1Label;
  final String action2Label;
  final String action3Label;

  ActionMapping({
    required this.action1Label,
    required this.action2Label,
    required this.action3Label,
  });

  /// Creates dynamic action mapping using SmartCombat analysis
  factory ActionMapping.fromSmartCombat(SmartCombat smartCombat) {
    var action1Info = smartCombat.getPrimaryActionInfo();
    var action2Info = smartCombat.getSecondaryActionInfo();
    var action3Info = smartCombat.getHealActionInfo();

    return ActionMapping(
      action1Label: action1Info.displayText,
      action2Label: action2Info.displayText,
      action3Label: action3Info.displayText,
    );
  }

  /// Legacy method for backwards compatibility
  factory ActionMapping.fromHero(Hero hero, Game game) {
    var smartCombat = SmartCombat(game);
    return ActionMapping.fromSmartCombat(smartCombat);
  }
}
