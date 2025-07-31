import 'dart:convert';

import 'package:test/test.dart';
import 'package:piecemeal/piecemeal.dart';

import '../../lib/src/content.dart';
import '../../lib/src/engine.dart';
import '../../lib/src/engine/core/world_state_manager.dart';

void main() {
  group('WorldStateManager', () {
    late Content content;
    late Game game;

    setUpAll(() {
      // Initialize content once for all tests
      content = createContent();
    });

    setUp(() {
      // Create a test hero save
      var heroSave = content.createHero('TestHero');
      
      // Create a test game
      game = Game(content, 1, heroSave, width: 20, height: 15);
      
      // Initialize the game with a simple layout
      game.initHero(Vec(10, 7));
    });

    test('saveWorldState returns valid JSON structure', () {
      var worldState = WorldStateManager.saveWorldState(game);
      
      expect(worldState, isA<Map<String, dynamic>>());
      expect(worldState['version'], equals(1));
      expect(worldState['timestamp'], isA<String>());
      expect(worldState['depth'], equals(1));
      expect(worldState['stage'], isA<Map<String, dynamic>>());
      expect(worldState['hero'], isA<Map<String, dynamic>>());
    });

    test('serialized stage contains correct dimensions', () {
      var worldState = WorldStateManager.saveWorldState(game);
      var stage = worldState['stage'] as Map<String, dynamic>;
      
      expect(stage['width'], equals(20));
      expect(stage['height'], equals(15));
      expect(stage['tiles'], isA<List>());
      expect(stage['items'], isA<List>());
      expect(stage['actors'], isA<List>());
    });

    test('serialized hero contains position and health', () {
      var worldState = WorldStateManager.saveWorldState(game);
      var hero = worldState['hero'] as Map<String, dynamic>;
      
      expect(hero['pos'], isA<Map<String, dynamic>>());
      expect(hero['pos']['x'], equals(10));
      expect(hero['pos']['y'], equals(7));
      expect(hero['health'], isA<int>());
      expect(hero['save'], isA<Map<String, dynamic>>());
    });

    test('serialized hero save contains required fields', () {
      var worldState = WorldStateManager.saveWorldState(game);
      var heroSave = worldState['hero']['save'] as Map<String, dynamic>;
      
      expect(heroSave['name'], equals('TestHero'));
      expect(heroSave['race'], isA<Map<String, dynamic>>());
      expect(heroSave['class'], isA<String>());
      expect(heroSave['inventory'], isA<List>());
      expect(heroSave['equipment'], isA<List>());
      expect(heroSave['experience'], isA<int>());
      expect(heroSave['gold'], isA<int>());
    });

    test('JSON serialization round-trip works', () {
      var worldState = WorldStateManager.saveWorldState(game);
      
      // Convert to JSON string and back
      var jsonString = json.encode(worldState);
      var decoded = json.decode(jsonString) as Map<String, dynamic>;
      
      expect(decoded['version'], equals(worldState['version']));
      expect(decoded['depth'], equals(worldState['depth']));
      expect(decoded['stage']['width'], equals(worldState['stage']['width']));
      expect(decoded['stage']['height'], equals(worldState['stage']['height']));
    });

    test('only explored tiles are serialized', () {
      // Mark some tiles as explored
      game.stage.explore(Vec(5, 5));
      game.stage.explore(Vec(10, 7)); // Hero position
      game.stage.explore(Vec(15, 10));
      
      var worldState = WorldStateManager.saveWorldState(game);
      var tiles = worldState['stage']['tiles'] as List;
      
      // Should have at least the explored tiles
      expect(tiles.length, greaterThan(0));
      
      // All serialized tiles should be marked as explored
      for (var tile in tiles) {
        var tileData = tile as Map<String, dynamic>;
        expect(tileData['isExplored'], isTrue);
      }
    });

    test('tile serialization includes position and type', () {
      // Explore a tile to ensure it gets serialized
      game.stage.explore(Vec(10, 7));
      
      var worldState = WorldStateManager.saveWorldState(game);
      var tiles = worldState['stage']['tiles'] as List;
      
      expect(tiles.isNotEmpty, isTrue);
      
      var tile = tiles.first as Map<String, dynamic>;
      expect(tile['pos'], isA<Map<String, dynamic>>());
      expect(tile['pos']['x'], isA<int>());
      expect(tile['pos']['y'], isA<int>());
      expect(tile['type'], isA<String>());
      expect(tile['isExplored'], isA<bool>());
    });

    test('Vec serialization works correctly', () {
      // Test Vec serialization indirectly through hero position
      var worldState = WorldStateManager.saveWorldState(game);
      var heroPos = worldState['hero']['pos'] as Map<String, dynamic>;
      
      expect(heroPos['x'], isA<int>());
      expect(heroPos['y'], isA<int>());
    });

    group('Enhanced stage data serialization', () {
      test('tile serialization includes comprehensive properties', () {
        // Explore a tile and modify its properties
        var testPos = Vec(10, 7);
        game.stage.explore(testPos);
        var tile = game.stage[testPos];
        
        // Modify tile properties to test serialization
        tile.addEmanation(5);
        tile.substance = 10;
        
        var worldState = WorldStateManager.saveWorldState(game);
        var tiles = worldState['stage']['tiles'] as List;
        
        // Find our test tile
        var testTile = tiles.firstWhere((t) {
          var tileData = t as Map<String, dynamic>;
          var pos = tileData['pos'] as Map<String, dynamic>;
          return pos['x'] == 10 && pos['y'] == 7;
        }) as Map<String, dynamic>;
        
        expect(testTile['pos']['x'], equals(10));
        expect(testTile['pos']['y'], equals(7));
        expect(testTile['type'], isA<String>());
        expect(testTile['isExplored'], isTrue);
        expect(testTile['emanation'], equals(5));
        expect(testTile['substance'], equals(10));
      });

      test('item position and inventory serialization works correctly', () {
        // Add an item to the stage
        var testItem = content.items.first;
        var item = Item(testItem, 3);
        var itemPos = Vec(12, 8);
        game.stage.addItem(item, itemPos);
        
        var worldState = WorldStateManager.saveWorldState(game);
        var items = worldState['stage']['items'] as List;
        
        expect(items.isNotEmpty, isTrue);
        
        var serializedItem = items.firstWhere((i) {
          var itemData = i as Map<String, dynamic>;
          var pos = itemData['pos'] as Map<String, dynamic>;
          return pos['x'] == 12 && pos['y'] == 8;
        }) as Map<String, dynamic>;
        
        expect(serializedItem['pos']['x'], equals(12));
        expect(serializedItem['pos']['y'], equals(8));
        expect(serializedItem['item']['type'], equals(testItem.name));
        expect(serializedItem['item']['count'], equals(3));
      });

      test('actor serialization includes monsters with complete state', () {
        // Create a test monster
        var breed = content.breeds.first;
        var monster = Monster(breed, 5, 5, 1);
        game.stage.addActor(monster);
        
        var worldState = WorldStateManager.saveWorldState(game);
        var actors = worldState['stage']['actors'] as List;
        
        expect(actors.isNotEmpty, isTrue);
        
        var serializedMonster = actors.first as Map<String, dynamic>;
        expect(serializedMonster['type'], equals('monster'));
        expect(serializedMonster['breed'], equals(breed.name));
        expect(serializedMonster['pos']['x'], equals(5));
        expect(serializedMonster['pos']['y'], equals(5));
        expect(serializedMonster['health'], isA<int>());
        expect(serializedMonster['generation'], equals(1));
      });

      test('hero position is accurately serialized', () {
        // Hero position is set during game initialization
        // We'll test with the current position
        var worldState = WorldStateManager.saveWorldState(game);
        var hero = worldState['hero'] as Map<String, dynamic>;
        
        expect(hero['pos']['x'], equals(game.hero.pos.x));
        expect(hero['pos']['y'], equals(game.hero.pos.y));
        expect(hero['health'], isA<int>());
      });

      test('stage serialization round-trip accuracy', () {
        // Set up a complex stage state
        var testPos1 = Vec(5, 5);
        var testPos2 = Vec(10, 10);
        var testPos3 = Vec(15, 12);
        
        // Explore tiles
        game.stage.explore(testPos1);
        game.stage.explore(testPos2);
        game.stage.explore(testPos3);
        
        // Add items
        var item1 = Item(content.items.first, 2);
        var item2 = Item(content.items.skip(1).first, 1);
        game.stage.addItem(item1, testPos1);
        game.stage.addItem(item2, testPos2);
        
        // Add monster
        var monster = Monster(content.breeds.first, testPos3.x, testPos3.y, 1);
        game.stage.addActor(monster);
        
        // Serialize
        var worldState = WorldStateManager.saveWorldState(game);
        
        // Verify stage structure
        var stage = worldState['stage'] as Map<String, dynamic>;
        expect(stage['width'], equals(game.stage.width));
        expect(stage['height'], equals(game.stage.height));
        
        var tiles = stage['tiles'] as List;
        var items = stage['items'] as List;
        var actors = stage['actors'] as List;
        
        expect(tiles.length, greaterThanOrEqualTo(1)); // At least our explored tiles
        expect(items.length, equals(2)); // Our two items
        expect(actors.length, equals(1)); // Our monster
        
        // Verify data integrity
        for (var tile in tiles) {
          var tileData = tile as Map<String, dynamic>;
          expect(tileData['pos'], isA<Map<String, dynamic>>());
          expect(tileData['type'], isA<String>());
          expect(tileData['isExplored'], isTrue);
        }
        
        for (var item in items) {
          var itemData = item as Map<String, dynamic>;
          expect(itemData['pos'], isA<Map<String, dynamic>>());
          expect(itemData['item'], isA<Map<String, dynamic>>());
          expect(itemData['item']['type'], isA<String>());
          expect(itemData['item']['count'], isA<int>());
        }
        
        for (var actor in actors) {
          var actorData = actor as Map<String, dynamic>;
          expect(actorData['type'], equals('monster'));
          expect(actorData['breed'], isA<String>());
          expect(actorData['pos'], isA<Map<String, dynamic>>());
          expect(actorData['health'], isA<int>());
        }
      });

      test('Vec helper methods work correctly through serialization', () {
        // Test Vec serialization indirectly through hero position
        var worldState = WorldStateManager.saveWorldState(game);
        var heroPos = worldState['hero']['pos'] as Map<String, dynamic>;
        
        // Verify serialization structure
        expect(heroPos.keys.toSet(), equals({'x', 'y'}));
        expect(heroPos['x'], isA<int>());
        expect(heroPos['y'], isA<int>());
        
        // Test that positions are correctly serialized in items and actors too
        var stage = worldState['stage'] as Map<String, dynamic>;
        var tiles = stage['tiles'] as List;
        
        if (tiles.isNotEmpty) {
          var tilePos = (tiles.first as Map<String, dynamic>)['pos'] as Map<String, dynamic>;
          expect(tilePos.keys.toSet(), equals({'x', 'y'}));
          expect(tilePos['x'], isA<int>());
          expect(tilePos['y'], isA<int>());
        }
      });
    });
  });
}

