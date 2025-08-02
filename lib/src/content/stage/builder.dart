import 'dart:html' as html;

import 'architect.dart';
import 'architectural_style.dart';
import 'catacomb.dart';
import 'cavern.dart';
import 'dungeon.dart';
import 'keep.dart';
import 'lake.dart';
import 'pit.dart';
import 'river.dart';
import 'room.dart';
import 'sandbox.dart';

void _addStyle(String name,
    {int start = 1,
    int end = 100,
    double? startFrequency,
    double? endFrequency,
    required String decor,
    double? decorDensity,
    String? monsters,
    double? monsterDensity,
    double? itemDensity,
    required Architecture Function() create,
    bool? canFill}) {
  monsters ??= "monster";

  var style = ArchitecturalStyle(name, decor, decorDensity, monsters.split(" "),
      monsterDensity, itemDensity, create,
      canFill: canFill);
  // TODO: Ramp frequencies?
  ArchitecturalStyle.styles.addRanged(style,
      start: start,
      end: end,
      startFrequency: startFrequency,
      endFrequency: endFrequency);
}

void dungeon(RoomShapes shapes, {required double frequency}) {
  _addStyle("dungeon",
      startFrequency: frequency,
      decor: "dungeon",
      decorDensity: 0.09,
      create: () => Dungeon(shapes: shapes));
}

void catacomb(String monsters,
    {required double startFrequency, required double endFrequency}) {
  _addStyle("catacomb",
      startFrequency: startFrequency,
      endFrequency: endFrequency,
      decor: "catacomb",
      decorDensity: 0.02,
      monsters: monsters,
      create: () => Catacomb());
}

void cavern(String monsters,
    {required double startFrequency, required double endFrequency}) {
  _addStyle("cavern",
      startFrequency: startFrequency,
      endFrequency: endFrequency,
      decor: "glowing-moss",
      decorDensity: 0.1,
      monsters: monsters,
      create: () => Cavern());
}

void lake(String monsters, {required int start, required int end}) {
  _addStyle("lake",
      start: start,
      end: end,
      decor: "water",
      decorDensity: 0.01,
      monsters: monsters,
      canFill: false,
      monsterDensity: 0.0,
      create: () => Lake());
}

void river(String monsters, {required int start, required int end}) {
  _addStyle("river",
      start: start,
      end: end,
      decor: "water",
      decorDensity: 0.01,
      monsters: monsters,
      monsterDensity: 0.0,
      canFill: false,
      create: () => River());
}

void keep(String monsters, {required int start, required int end}) {
  _addStyle("$monsters keep",
      start: start,
      end: end,
      startFrequency: 2.0,
      decor: "keep",
      decorDensity: 0.07,
      monsters: monsters,
      // Keep spawns monsters itself.
      monsterDensity: 0.0,
      itemDensity: 1.5,
      canFill: false,
      create: () => Keep(5));
}

void pit(String monsterGroup, {required int start, required int end}) {
  _addStyle("$monsterGroup pit",
      start: start,
      end: end,
      startFrequency: 0.2,
      // TODO: Different decor?
      decor: "glowing-moss",
      decorDensity: 0.05,
      canFill: false,
      create: () => Pit(monsterGroup));
}

void sandbox() {
  // Check if sandbox mode is enabled
  if (!_isSandboxEnabled()) return;
  
  _addStyle("sandbox",
      start: 1,
      end: 1, // Only available at depth 1 for testing
      startFrequency: 100.0, // Very high frequency to ensure it gets picked
      decor: "dungeon",
      decorDensity: 0.0, // No random decorations
      monsters: "monster", // All monster types
      monsterDensity: 0.0, // We handle monsters ourselves
      itemDensity: 10.0, // Very high item density for lots of items
      create: () => SandboxArchitecture());
}

/// Check if sandbox mode is enabled via localStorage or config
bool _isSandboxEnabled() {
  try {
    // First check localStorage for a quick toggle
    var localStorageValue = html.window.localStorage['sandbox_enabled'];
    if (localStorageValue == 'true') return true;
    
    // If not in localStorage, check if there's a global JS variable
    // This allows setting it via browser console: window.sandboxMode = true;
    try {
      var jsWindow = html.window as dynamic;
      if (jsWindow.sandboxMode == true) return true;
    } catch (e) {
      // Ignore JS interop errors
    }
    
    return false;
  } catch (e) {
    // If we can't access localStorage/window, default to false
    return false;
  }
}
