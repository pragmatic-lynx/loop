// lib/src/engine/action/action_mapping.dart

import '../core/game.dart';
import '../hero/hero.dart';
import '../loop/action_queues.dart';

/// Maps simplified loop input controls to context-aware action labels
/// Provides dynamic button labeling based on queue system
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

  /// Creates dynamic action mapping using ActionQueues
  factory ActionMapping.fromQueues(ActionQueues queues) {
    var rangedItem = queues.getRangedQueueItem();
    var magicItem = queues.getMagicQueueItem();
    var healItem = queues.getHealQueueItem();
    var stealthItem = queues.getResistanceQueueItem(); // Still using same method name for compatibility

    return ActionMapping(
      action1Label: rangedItem.displayText,
      action2Label: magicItem.displayText,
      action3Label: healItem.displayText,
      action4Label: stealthItem.displayText,
    );
  }

  /// Legacy method for backwards compatibility
  factory ActionMapping.fromHero(Hero hero, Game game) {
    var queues = ActionQueues(game);
    return ActionMapping.fromQueues(queues);
  }
}
