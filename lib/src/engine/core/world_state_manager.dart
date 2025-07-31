import 'dart:convert';

import 'package:piecemeal/piecemeal.dart';

import '../hero/hero.dart';
import '../items/item.dart';
import '../monster/monster.dart';
import '../stage/stage.dart';
import '../stage/tile.dart';
import 'actor.dart';
import 'game.dart';

/// Manages serialization and deserialization of complete game world state
/// to/from JSON format for level editing purposes.
class WorldStateManager {
  /// Serializes the complete game state to a JSON-compatible Map.
  /// 
  /// This includes the stage layout, all items, actors, and hero state.
  /// Only explored tiles are serialized to reduce file size.
  static Map<String, dynamic> saveWorldState(Game game) {
    return {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'depth': game.depth,
      'stage': _serializeStage(game.stage),
      'hero': _serializeHero(game.hero),
    };
  }

  /// Serializes the stage including dimensions, tiles, items, and actors.
  static Map<String, dynamic> _serializeStage(Stage stage) {
    var tiles = <Map<String, dynamic>>[];
    var items = <Map<String, dynamic>>[];
    var actors = <Map<String, dynamic>>[];

    // Serialize only explored tiles to reduce file size
    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        var pos = Vec(x, y);
        var tile = stage[pos];
        
        // Only serialize explored tiles
        if (tile.isExplored) {
          tiles.add(_serializeTile(pos, tile));
        }
      }
    }

    // Serialize items on the ground
    stage.forEachItem((item, pos) {
      items.add({
        'pos': _serializeVec(pos),
        'item': _serializeItem(item),
      });
    });

    // Serialize all actors except the hero
    for (var actor in stage.actors) {
      if (actor is Monster) {
        actors.add(_serializeMonster(actor));
      }
    }

    return {
      'width': stage.width,
      'height': stage.height,
      'tiles': tiles,
      'items': items,
      'actors': actors,
    };
  }

  /// Serializes a single tile with its position and properties.
  static Map<String, dynamic> _serializeTile(Vec pos, Tile tile) {
    return {
      'pos': _serializeVec(pos),
      'type': tile.type.name,
      'isExplored': tile.isExplored,
      'isVisible': tile.isVisible,
      if (tile.emanation > 0) 'emanation': tile.emanation,
      if (tile.substance > 0) 'substance': tile.substance,
      if (tile.element.name != 'none') 'element': tile.element.name,
    };
  }

  /// Serializes a Vec position to a compact format.
  static Map<String, int> _serializeVec(Vec pos) {
    return {'x': pos.x, 'y': pos.y};
  }

  /// Serializes an item including its type and properties.
  static Map<String, dynamic> _serializeItem(Item item) {
    return {
      'type': item.type.name,
      'count': item.count,
      if (item.prefix != null) 'prefix': _serializeAffix(item.prefix!),
      if (item.suffix != null) 'suffix': _serializeAffix(item.suffix!),
      if (item.intrinsicAffix != null) 'intrinsic': _serializeAffix(item.intrinsicAffix!),
    };
  }

  /// Serializes an affix.
  static Map<String, dynamic> _serializeAffix(dynamic affix) {
    return {
      'id': affix.type.id,
      'parameter': affix.parameter,
    };
  }

  /// Serializes a monster actor.
  static Map<String, dynamic> _serializeMonster(Monster monster) {
    return {
      'type': 'monster',
      'breed': monster.breed.name,
      'pos': _serializeVec(monster.pos),
      'health': monster.health,
      'generation': monster.generation,
      'isAsleep': monster.isAsleep,
      'isAfraid': monster.isAfraid,
      'alertness': monster.alertness,
      'fear': monster.fear,
    };
  }

  /// Serializes the hero including position and current state.
  static Map<String, dynamic> _serializeHero(Hero hero) {
    return {
      'pos': _serializeVec(hero.pos),
      'health': hero.health,
      'save': _serializeHeroSave(hero.save),
    };
  }

  /// Serializes the hero's persistent save data.
  static Map<String, dynamic> _serializeHeroSave(dynamic heroSave) {
    // Use existing serialization logic from Storage class
    return {
      'name': heroSave.name,
      'race': {
        'name': heroSave.race.name,
        'seed': heroSave.race.seed,
        'stats': {
          for (var stat in heroSave.race.stats.keys) 
            stat.name: heroSave.race.stats[stat]
        }
      },
      'class': heroSave.heroClass.name,
      'death': heroSave.permadeath ? 'permanent' : 'dungeon',
      'inventory': _serializeItems(heroSave.inventory),
      'equipment': _serializeItems(heroSave.equipment),
      'home': _serializeItems(heroSave.home),
      'crucible': _serializeItems(heroSave.crucible),
      'shops': {
        for (var entry in heroSave.shops.entries)
          entry.key.name: _serializeItems(entry.value)
      },
      'experience': heroSave.experience,
      'skills': {
        for (var skill in heroSave.skills.discovered)
          skill.name: {
            'level': heroSave.skills.level(skill),
            'points': heroSave.skills.points(skill)
          }
      },
      'log': _serializeLog(heroSave.log),
      'lore': _serializeLore(heroSave.lore),
      'gold': heroSave.gold,
      'maxDepth': heroSave.maxDepth,
    };
  }

  /// Serializes a collection of items.
  static List<dynamic> _serializeItems(Iterable<dynamic> items) {
    return [
      for (var item in items) _serializeItem(item)
    ];
  }

  /// Serializes the hero's log.
  static List<dynamic> _serializeLog(dynamic log) {
    return [
      for (var message in log.messages)
        {
          'type': message.type.name,
          'text': message.text,
          'count': message.count,
        }
    ];
  }

  /// Serializes the hero's lore.
  static Map<String, dynamic> _serializeLore(dynamic lore) {
    // This is a simplified version - full implementation would need access to content
    return {
      'seen': {},
      'slain': {},
      'foundItems': {},
      'foundAffixes': {},
      'usedItems': {},
      'createdArtifacts': [],
    };
  }
}