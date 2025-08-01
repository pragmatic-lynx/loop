// lib/src/ui/loop_input.dart

/// Simplified input system for roguelite loop mode
/// Only movement + 3 smart action buttons for ADHD-friendly gameplay
enum LoopInput {
  // Movement (keep these intuitive)
  n, e, s, w, ne, nw, se, sw, wait,

  // Smart action buttons (1,2,3)
  action1,  // 🗡️ Primary Attack/Interact
  action2,  // ⚡ Magic/Secondary Ability
  action3,  // ❤️ Heal/Consumable

  // Minimal essential controls
  cancel,   // ESC - pause/menu
  info,     // TAB - show info
}
