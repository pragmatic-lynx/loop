// lib/src/ui/loop_input.dart

/// Simplified input system for roguelite loop mode
/// Streamlined controls for ADHD-friendly gameplay
enum LoopInput {
  // Movement (keep these intuitive)
  n, e, s, ne, nw, se, sw, wait,

  // New control scheme
  attack,       // 1 - Attack WITH CLASS WEAPON (context-aware)
  utility,      // 2 - Utility (non-healing consumables, scrolls, buffs, CC)
  heal,         // 3 - Heal (healing items from inventory)
  movement,     // W - Movement (Flee spell effect with cooldown)
  interact,     // E - Interact (stays the same)
  cycle,        // Q - Cycle through Spells/Utility/Healing categories
  cycleCategory, // Tab - Cycle between categories (alternative to Q)

  // Debug functionality
  debug,        // Z - debug hotkey

  // Minimal essential controls
  cancel,       // ESC - pause/menu
  inventory,    // I - inventory
}
