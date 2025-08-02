// lib/src/content/stage/sandbox_decorator.dart
import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../item/items.dart';
import '../item/drops.dart';
import 'architect.dart';
import 'decorator.dart';
import 'sandbox.dart';

/// Custom decorator for sandbox maps that places all item types in the central area
class SandboxDecorator extends Decorator {
  SandboxDecorator(super.architect);

  @override
  Iterable<String> decorate() sync* {
    // Do normal decoration first (doorways, painting, etc.)
    yield* super.decorate();
    
    // Then add our custom item placement
    yield* _placeAllItems();
  }

  /// Places one of every item type in the central area
  Iterable<String> _placeAllItems() sync* {
    // Find the sandbox architecture
    SandboxArchitecture? sandbox;
    for (var entry in super._tilesByArchitecture.entries) {
      if (entry.key is SandboxArchitecture) {
        sandbox = entry.key as SandboxArchitecture;
        break;
      }
    }
    
    if (sandbox == null) {
      yield "No sandbox architecture found";
      return;
    }
    
    var centralTiles = sandbox.centralTiles.toList();
    rng.shuffle(centralTiles);
    
    var tileIndex = 0;
    
    // Place all item types from different categories
    yield* _placeItemsByTag("equipment/weapon", centralTiles, tileIndex);
    tileIndex += 20; // Space out items
    
    yield* _placeItemsByTag("equipment/armor", centralTiles, tileIndex);
    tileIndex += 20;
    
    yield* _placeItemsByTag("magic", centralTiles, tileIndex);
    tileIndex += 15;
    
    yield* _placeItemsByTag("potion", centralTiles, tileIndex);
    tileIndex += 10;
    
    yield* _placeItemsByTag("scroll", centralTiles, tileIndex);
    tileIndex += 10;
    
    yield* _placeItemsByTag("food", centralTiles, tileIndex);
    tileIndex += 10;
    
    yield* _placeItemsByTag("treasure", centralTiles, tileIndex);
    tileIndex += 10;
    
    yield* _placeItemsByTag("light", centralTiles, tileIndex);
    
    yield "Finished placing sandbox items";
  }
  
  /// Places items from a specific tag category
  Iterable<String> _placeItemsByTag(String tag, List<Vec> tiles, int startIndex) sync* {
    var itemTypes = Items.types.all.where((item) => 
      item.tags.any((itemTag) => itemTag.contains(tag))
    ).toList();
    
    for (var i = 0; i < itemTypes.length && (startIndex + i) < tiles.length; i++) {
      var itemType = itemTypes[i];
      var pos = tiles[startIndex + i];
      
      // Create and place the item
      var item = Item(itemType, 1);
      super._stage.addItem(item, pos);
      
      yield "Placed ${itemType.name}";
    }
  }
}
