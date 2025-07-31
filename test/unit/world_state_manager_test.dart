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

    setUp(() {
      // Initialize content for testing
      content = createContent();
      
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
  });
}

