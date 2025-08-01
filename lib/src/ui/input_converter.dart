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
      case Input.w:
        return LoopInput.w;
      case Input.nw:
        return LoopInput.nw;
      case Input.ok:
        return LoopInput.wait;
      
      // Action button mappings (1,2,3) - Smart UI system
      case Input.selectSkill:  // Mapped to '1' key
        return LoopInput.action1;
      case Input.use:          // Mapped to '2' key  
        return LoopInput.action2;
      case Input.drop:         // Mapped to '3' key
        return LoopInput.action3;
      
      // Equipment and staircase interaction
      case Input.equip:        // Mapped to 'E' key
        return LoopInput.equip;
      
      // Essential controls
      case Input.cancel:
        return LoopInput.cancel;
      
      // Map hero info to our info display
      case Input.heroInfo:
        return LoopInput.info;
      
      // All other inputs are ignored in loop mode
      default:
        return null;
    }
  }
  
  /// Get description of what the numbered keys do in loop mode
  static String getActionDescription(int actionNumber) {
    switch (actionNumber) {
      case 1:
        return "🗡️ Primary Attack/Interact";
      case 2:
        return "⚡ Magic/Secondary Ability";
      case 3:
        return "❤️ Heal/Consumable";
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
        return "Magic";
      case 3:
        return "Heal";
      default:
        return "Action $actionNumber";
    }
  }
}
