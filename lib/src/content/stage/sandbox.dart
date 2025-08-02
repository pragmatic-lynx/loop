// lib/src/content/stage/sandbox.dart
import 'package:piecemeal/piecemeal.dart';

import '../monster/monsters.dart';
import 'architect.dart';
import 'painter.dart';

/// Creates a sandbox map with all items and monsters for testing/experimentation.
class SandboxArchitecture extends Architecture {
  late List<Vec> _centralTiles;
  

  
  @override
  PaintStyle get paintStyle => PaintStyle.flagstone;

  @override
  Iterable<String> build() sync* {
    yield "Creating sandbox layout...";
    
    // Create a large central area for items (60% of map)
    var centerWidth = (width * 0.6).round();
    var centerHeight = (height * 0.6).round();
    var centerX = (width - centerWidth) ~/ 2;
    var centerY = (height - centerHeight) ~/ 2;
    
    // Carve out the central area and store tiles for item placement
    _centralTiles = [];
    for (var x = centerX; x < centerX + centerWidth; x++) {
      for (var y = centerY; y < centerY + centerHeight; y++) {
        carve(x, y);
        _centralTiles.add(Vec(x, y));
      }
    }
    
    yield "Creating monster rooms...";
    
    // Create monster rooms around the edges
    _createMonsterRooms();
    
    yield "Connecting areas...";
    
    // Create passages connecting all areas
    _createPassages(centerX, centerY, centerWidth, centerHeight);
  }
  
  void _createMonsterRooms() {
    // Define room positions around the central area
    var roomSize = 8;
    var rooms = <Rect>[
      // Top row
      Rect(5, 5, roomSize, roomSize),
      Rect(width ~/ 2 - roomSize ~/ 2, 5, roomSize, roomSize),
      Rect(width - roomSize - 5, 5, roomSize, roomSize),
      
      // Bottom row  
      Rect(5, height - roomSize - 5, roomSize, roomSize),
      Rect(width ~/ 2 - roomSize ~/ 2, height - roomSize - 5, roomSize, roomSize),
      Rect(width - roomSize - 5, height - roomSize - 5, roomSize, roomSize),
      
      // Side rooms
      Rect(5, height ~/ 2 - roomSize ~/ 2, roomSize, roomSize),
      Rect(width - roomSize - 5, height ~/ 2 - roomSize ~/ 2, roomSize, roomSize),
    ];
    
    // Carve out each room
    for (var room in rooms) {
      for (var pos in room) {
        if (canCarve(pos)) {
          carve(pos.x, pos.y);
        }
      }
    }
  }
  
  void _createPassages(int centerX, int centerY, int centerWidth, int centerHeight) {
    // Create passages from center to each room
    var centerPos = Vec(centerX + centerWidth ~/ 2, centerY + centerHeight ~/ 2);
    
    // Horizontal passages
    for (var x = centerX - 1; x >= 1; x--) {
      if (canCarve(Vec(x, centerPos.y))) {
        carve(x, centerPos.y);
      }
    }
    for (var x = centerX + centerWidth; x < width - 1; x++) {
      if (canCarve(Vec(x, centerPos.y))) {
        carve(x, centerPos.y);
      }
    }
    
    // Vertical passages
    for (var y = centerY - 1; y >= 1; y--) {
      if (canCarve(Vec(centerPos.x, y))) {
        carve(centerPos.x, y);
      }
    }
    for (var y = centerY + centerHeight; y < height - 1; y++) {
      if (canCarve(Vec(centerPos.x, y))) {
        carve(centerPos.x, y);
      }
    }
  }
  
  /// Returns the central tiles where items should be placed
  List<Vec> get centralTiles => _centralTiles;
  

  
  @override
  bool spawnMonsters(Painter painter) {
    // Custom monster spawning - place one of each breed in separate rooms
    var roomPositions = [
      Vec(8, 8),           // Top-left
      Vec(width ~/ 2, 8),  // Top-center
      Vec(width - 8, 8),   // Top-right
      Vec(8, height - 8),  // Bottom-left
      Vec(width ~/ 2, height - 8), // Bottom-center
      Vec(width - 8, height - 8),  // Bottom-right
      Vec(8, height ~/ 2), // Middle-left
      Vec(width - 8, height ~/ 2), // Middle-right
    ];
    
    var roomIndex = 0;
    var breedsPerRoom = 8; // Limit breeds per room to avoid overcrowding
    var breedCount = 0;
    
    for (var breed in Monsters.breeds.all) {
      if (roomIndex >= roomPositions.length) break;
      
      var roomPos = roomPositions[roomIndex];
      
      // Find a nearby open tile in this room  
      var spawnPos = _findNearbyOpenTile(roomPos);
      if (spawnPos != null) {
        painter.spawnMonster(spawnPos, breed);
        breedCount++;
        
        // Move to next room after placing several breeds
        if (breedCount >= breedsPerRoom) {
          roomIndex++;
          breedCount = 0;
        }
      }
    }
    
    return true; // We handled monster spawning
  }
  
  Vec? _findNearbyOpenTile(Vec center) {
    // Search in expanding circles for an open tile
    // We'll just return the center for now since we can't easily access the stage
    // The painter will handle placement validation
    return center;
  }
}


