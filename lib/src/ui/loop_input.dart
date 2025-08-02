// lib/src/ui/loop_input.dart

/// Simplified input system for roguelite loop mode
/// Only movement + 3 smart action buttons for ADHD-friendly gameplay
enum LoopInput {
  // Movement (keep these intuitive)
  n, e, s, w, ne, nw, se, sw, wait,

  // Smart action buttons (1,2,3,4)
  action1,  // 🗡️ Primary Attack/Interact
  action2,  // ⚡ Magic/Secondary Ability
  action3,  // ❤️ Heal/Consumable
  action4,  // 🔮 Cast Spell

  // Spell management
  cycleSpell, // Q - cycle active spell
  
  // Queue management
  cycleQueue, // Tab - cycle current queue

  // Equipment and staircase interaction
  equip,    // E - equip items or interact with staircases

  // Minimal essential controls
  cancel,   // ESC - pause/menu
  info,     // TAB - show info
  
  // Debug/cheat controls
  giveConsumables,  // G - give one-time set of consumables
}
