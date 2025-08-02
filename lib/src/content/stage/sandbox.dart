// lib/src/content/stage/sandbox.dart
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../tiles.dart';
import 'architect.dart';
import 'painter.dart';

/// Creates a simple sandbox room with all items on the floor for testing.
class SandboxArchitecture extends Architecture {
  @override
  PaintStyle get paintStyle => PaintStyle.flagstone;

  @override
  Iterable<String> build() sync* {
    print("🏗️ SANDBOX ARCHITECTURE IS BUILDING!");
    yield "🎮 Creating SANDBOX room - this should be obvious!";
    
    // Create a simple rectangular room that fills most of the map
    var margin = 2;
    var roomWidth = width - (margin * 2);
    var roomHeight = height - (margin * 2);
    
    // Ensure we have a minimum viable room size
    if (roomWidth < 10 || roomHeight < 10) {
      roomWidth = width - 2;
      roomHeight = height - 2;
      margin = 1;
    }
    
    // Safety check to ensure positive dimensions
    if (roomWidth <= 0) roomWidth = width - 2;
    if (roomHeight <= 0) roomHeight = height - 2;
    if (margin < 1) margin = 1;
    
    print("🎮 Sandbox room size: ${roomWidth}x${roomHeight} with margin ${margin}");
    
    // Carve out the room
    var tileCount = 0;
    for (var x = margin; x < margin + roomWidth && x < width - 1; x++) {
      for (var y = margin; y < margin + roomHeight && y < height - 1; y++) {
        carve(x, y);
        tileCount++;
      }
    }
    
    print("🎮 Sandbox carved ${tileCount} tiles!");
    yield "🎮 Sandbox room created with ${tileCount} open tiles - items should spawn here!";
  }
  
  @override
  bool spawnMonsters(Painter painter) {
    print("🎮 Sandbox: NOT spawning any monsters (clean room mode)");
    // No monsters in the basic sandbox - just a clean room with items
    return true; // We handled monster spawning (by not spawning any)
  }
}
