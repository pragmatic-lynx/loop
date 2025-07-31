// lib/src/ui/loop_input.dart

/// Simplified input system for roguelite loop mode
/// Only movement + 4 action buttons for ADHD-friendly gameplay
enum LoopInput {
  // Movement (keep these intuitive)
  n, e, s, w, ne, nw, se, sw, wait,

  // Core action buttons (1,2,3,4)
  action1,  // Primary Attack/Interact
  action2,  // Secondary Attack/Ability
  action3,  // Consumable/Heal
  action4,  // Special/Escape

  // Minimal essential controls
  cancel,   // ESC - pause/menu
  info,     // TAB - show info
}
