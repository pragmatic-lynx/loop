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
    yield "Creating simple sandbox room...";
    
    // Create a simple rectangular room that fills most of the map
    var margin = 3;
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
    
    // Carve out the room
    for (var x = margin; x < margin + roomWidth && x < width - 1; x++) {
      for (var y = margin; y < margin + roomHeight && y < height - 1; y++) {
        carve(x, y);
      }
    }
    
    yield "Sandbox room created";
  }
  
  @override
  bool spawnMonsters(Painter painter) {
    // No monsters in the basic sandbox - just a clean room with items
    return true; // We handled monster spawning (by not spawning any)
  }
}
