import 'package:piecemeal/piecemeal.dart';

import '../../engine.dart';
import '../chest.dart';
import '../elements.dart';
import '../item/drops.dart';
import '../tiles.dart';
import '../rarity.dart';

/// Base class for actions that open a container tile.
abstract class _OpenTileAction extends Action {
  final Vec _pos;

  _OpenTileAction(this._pos);

  String get _name;

  TileType get _openTile;

  // TODO: Do something more sophisticated. Take into account the theme where
  // the tile is.

  int get _minDepthEmptyChance;

  int get _maxDepthEmptyChance;

  @override
  ActionResult onPerform() {
    game.stage[_pos].type = _openTile;
    addEvent(EventType.openBarrel, pos: _pos);

    // TODO: Chance of monster in it?
    // TODO: Traps. Locks.
    if (rng.percent(lerpInt(game.depth, 1, Option.maxDepth,
        _minDepthEmptyChance, _maxDepthEmptyChance))) {
      log("The $_name is empty.", actor);
    } else {
      game.stage.placeDrops(_pos, _createDrop(), depth: game.depth);

      log("{1} open[s] the $_name.", actor);
    }

    return ActionResult.success;
  }

  Drop _createDrop();
}

/// Open a barrel and place its drops.
class OpenBarrelAction extends _OpenTileAction {
  OpenBarrelAction(super.pos);

  @override
  String get _name => "barrel";

  @override
  TileType get _openTile => Tiles.openBarrel;

  @override
  int get _minDepthEmptyChance => 40;

  @override
  int get _maxDepthEmptyChance => 10;

  // TODO: More sophisticated drop.
  @override
  Drop _createDrop() => parseDrop("food", depth: game.depth);
}

/// Open a chest and place its drops.
class OpenChestAction extends Action {
  final Vec _pos;

  OpenChestAction(this._pos);

  @override
  ActionResult onPerform() {
    final currentTile = game.stage[_pos].type;
    final ChestType chestType;
    final TileType openTile;

    // Determine chest type and corresponding open tile
    if (currentTile == Tiles.closedChest) {
      chestType = ChestType.wooden;
      openTile = Tiles.openChest;
    } else if (currentTile == Tiles.closedOrnateChest) {
      chestType = ChestType.ornate;
      openTile = Tiles.openOrnateChest;
    } else if (currentTile == Tiles.closedMythicChest) {
      chestType = ChestType.mythic;
      openTile = Tiles.openMythicChest;
    } else {
      // Fallback to wooden chest
      chestType = ChestType.wooden;
      openTile = Tiles.openChest;
    }

    // Change the tile to open
    game.stage[_pos].type = openTile;
    addEvent(EventType.openBarrel, pos: _pos);

    // Generate loot using the new chest system
    final chest = Chest(chestType, game.depth);
    final loot = chest.open();

    // Add gold to hero
    if (loot.gold > 0) {
      game.hero.gold += loot.gold;
    }

    // Place items on the ground
    for (final item in loot.items) {
      game.stage.addItem(item, _pos);
    }

    // Create treasure found event for UI feedback
    addEvent(EventType.openBarrel, pos: _pos);

    if (loot.items.isNotEmpty || loot.gold > 0) {
      log("{1} open[s] the ${chestType.name}.", actor);
    } else {
      log("The ${chestType.name} is empty.", actor);
    }

    return ActionResult.success;
  }
}
