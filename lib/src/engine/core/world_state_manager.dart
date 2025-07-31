import 'dart:convert';

import 'package:piecemeal/piecemeal.dart';

import '../hero/hero.dart';
import '../hero/stat.dart';
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
  /// Enhanced with better organization and comprehensive data capture.
  static Map<String, dynamic> _serializeStage(Stage stage) {
    var tiles = <Map<String, dynamic>>[];

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

    return {
      'width': stage.width,
      'height': stage.height,
      'tiles': tiles,
      'items': _serializeStageItems(stage),
      'actors': _serializeStageActors(stage),
    };
  }

  /// Serializes a single tile with its position and properties.
  static Map<String, dynamic> _serializeTile(Vec pos, Tile tile) {
    var result = {
      'pos': _serializeVec(pos),
      'type': tile.type.name,
      'isExplored': tile.isExplored,
      'isVisible': tile.isVisible,
    };

    // Include optional tile properties only if they have non-default values
    if (tile.emanation > 0) result['emanation'] = tile.emanation;
    if (tile.substance > 0) result['substance'] = tile.substance;
    if (tile.element.name != 'none') result['element'] = tile.element.name;
    
    // Include illumination data for better reconstruction
    if (tile.floorIllumination > 0) result['floorIllumination'] = tile.floorIllumination;
    if (tile.actorIllumination > 0) result['actorIllumination'] = tile.actorIllumination;
    
    // Include occlusion and fall-off data
    if (tile.isOccluded) result['isOccluded'] = tile.isOccluded;
    if (tile.fallOff > 0) result['fallOff'] = tile.fallOff;

    return result;
  }

  /// Serializes a Vec position to a compact format.
  /// This is a helper method used throughout the serialization process.
  static Map<String, int> _serializeVec(Vec pos) {
    return {'x': pos.x, 'y': pos.y};
  }

  /// Deserializes a Vec position from serialized data.
  /// This is the counterpart to _serializeVec for round-trip accuracy.
  static Vec _deserializeVec(Map<String, dynamic> data) {
    return Vec(data['x'] as int, data['y'] as int);
  }

  /// Serializes an item including its type and properties.
  /// Enhanced to handle all item properties for accurate reconstruction.
  static Map<String, dynamic> _serializeItem(Item item) {
    var result = {
      'type': item.type.name,
      'count': item.count,
    };

    // Include affixes if present
    if (item.prefix != null) result['prefix'] = _serializeAffix(item.prefix!);
    if (item.suffix != null) result['suffix'] = _serializeAffix(item.suffix!);
    if (item.intrinsicAffix != null) result['intrinsic'] = _serializeAffix(item.intrinsicAffix!);

    // Include emanation level if the item emits light
    if (item.emanationLevel > 0) result['emanationLevel'] = item.emanationLevel;

    return result;
  }

  /// Serializes item positions and inventory data for stage items.
  /// This method handles the mapping of items to their positions on the stage.
  static List<Map<String, dynamic>> _serializeStageItems(Stage stage) {
    var items = <Map<String, dynamic>>[];
    
    stage.forEachItem((item, pos) {
      items.add({
        'pos': _serializeVec(pos),
        'item': _serializeItem(item),
      });
    });

    return items;
  }

  /// Serializes an affix.
  static Map<String, dynamic> _serializeAffix(dynamic affix) {
    return {
      'id': affix.type.id,
      'parameter': affix.parameter,
    };
  }

  /// Serializes a monster actor with complete state information.
  /// Enhanced to include all necessary monster properties for accurate reconstruction.
  static Map<String, dynamic> _serializeMonster(Monster monster) {
    var result = {
      'type': 'monster',
      'breed': monster.breed.name,
      'pos': _serializeVec(monster.pos),
      'health': monster.health,
      'generation': monster.generation,
    };

    // Include behavioral state
    if (monster.isAsleep) result['isAsleep'] = monster.isAsleep;
    if (monster.isAfraid) result['isAfraid'] = monster.isAfraid;
    if (monster.alertness > 0) result['alertness'] = monster.alertness;
    if (monster.fear > 0) result['fear'] = monster.fear;

    return result;
  }

  /// Serializes all actors on the stage including monsters.
  /// The hero is handled separately in _serializeHero.
  static List<Map<String, dynamic>> _serializeStageActors(Stage stage) {
    var actors = <Map<String, dynamic>>[];

    for (var actor in stage.actors) {
      if (actor is Monster) {
        actors.add(_serializeMonster(actor));
      }
    }

    return actors;
  }

  /// Serializes the hero including position and current state.
  /// Enhanced to capture complete hero state for accurate reconstruction.
  static Map<String, dynamic> _serializeHero(Hero hero) {
    var result = {
      'pos': _serializeVec(hero.pos),
      'health': hero.health,
      'save': _serializeHeroSave(hero.save),
    };

    // Include additional hero state that might differ from save data
    if (hero.maxHealth != hero.health) {
      result['maxHealth'] = hero.maxHealth;
    }

    // Include energy state for turn management
    if (hero.energy.energy > 0) {
      result['energy'] = hero.energy.energy;
    }

    return result;
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
          for (var stat in Stat.all) 
            stat.name: heroSave.race.max(stat)
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