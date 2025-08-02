// lib/src/ui/input_converter.dart

import 'input.dart';
import 'loop_input.dart';

/// Converts between standard Input and simplified LoopInput
/// Allows loop mode to use a simplified control scheme while
/// maintaining compatibility with existing infrastructure
class InputConverter {
  /// Convert standard Input to LoopInput for loop mode
  static LoopInput? convertToLoopInput(Input input) {
    switch (input) {
      // Movement mappings (keep these consistent)
      case Input.n:
        return LoopInput.n;
      case Input.ne:
        return LoopInput.ne;
      case Input.e:
        return LoopInput.e;
      case Input.se:
        return LoopInput.se;
      case Input.s:
        return LoopInput.s;
      case Input.sw:
        return LoopInput.sw;
      case Input.nw:
        return LoopInput.nw;
      case Input.ok:
        return LoopInput.wait;
      
      // New control scheme mappings
      case Input.selectSkill:  // Mapped to '1' key
        return LoopInput.attack;
      case Input.use:          // Mapped to '2' key  
        return LoopInput.utility;
      case Input.drop:         // Mapped to '3' key
        return LoopInput.heal;
      case Input.w:            // W key for movement (Flee effect)
        return LoopInput.movement;
      case Input.operate:      // E key for interact
        return LoopInput.interact;
      case Input.cycleQueue:   // Q key for cycling categories
        return LoopInput.cycle;
      
      // Debug functionality
      case Input.debug:        // Mapped to 'Z' key
        return LoopInput.debug;
      
      // Essential controls
      case Input.cancel:
        return LoopInput.cancel;
      case Input.inventory:
        return LoopInput.inventory;
      
      // All other inputs are ignored in loop mode
      default:
        return null;
    }
  }
  
  /// Get description of what the numbered keys do in loop mode
  static String getActionDescription(int actionNumber) {
    switch (actionNumber) {
      case 1:
        return "🗡️ Attack WITH CLASS WEAPON";
      case 2:
        return "⚡ Utility (Scrolls/Buffs/CC)";
      case 3:
        return "❤️ Heal (From Inventory)";
      default:
        return "Unknown Action";
    }
  }
  
  /// Get a friendly name for action buttons
  static String getActionName(int actionNumber) {
    switch (actionNumber) {
      case 1:
        return "Attack";
      case 2:
        return "Utility";
      case 3:
        return "Heal";
      default:
        return "Action $actionNumber";
    }
  }
}
