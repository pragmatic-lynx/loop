// lib/src/ui/loop_input.dart

/// Simplified input system for roguelite loop mode
/// Only movement + 3 smart action buttons for ADHD-friendly gameplay
enum LoopInput {
  // Movement (keep these intuitive)
  n, e, s, w, ne, nw, se, sw, wait,

  // Smart action buttons (1,2,3)
  action1,  // 🗡️ Primary Attack/Interact (Bow for Rangers, Spells for Mages)
  action2,  // ⚡ Magic/Secondary Ability
  action3,  // ❤️ Heal/Consumable

  // Spell management
  cycleSpell, // Q - cycle active spell
  
  // Queue management
  cycleQueue, // Tab - cycle current queue

  // Equipment and staircase interaction
  equip,    // E - equip items or interact with staircases

  // Debug functionality
  debug,    // Z - debug hotkey

  // Minimal essential controls
  cancel,   // ESC - pause/menu
  info,     // TAB - show info
}
