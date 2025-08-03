import 'dart:math';

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart' as hues;
import 'confirm_popup.dart';
import 'draw.dart';
import 'loop_game_screen.dart';
import 'input.dart';
import 'new_hero_screen.dart';
import 'storage.dart';



const _devilChars = [
  r"  (\_/)   ",
  r"  >, ,<   ",
  r"  | o |   ",
  r"  \\_//   ",
  r"   \^/    ",
  r"   /|\    ",
  r" _/   \_  ",
  r"/       \ ",
];

const _devilColors = [
  r"  RRRRR   ",
  r"  RR RR   ",
  r"  R O R   ",
  r"  RRRRR   ",
  r"   RRR    ",
  r"   RRR    ",
  r" RR   RR  ",
  r"RR     RR ",
];

const _colors = {
  "L": hues.lightWarmGray,
  "E": hues.warmGray,
  "R": hues.red,
  "O": hues.carrot,
  "G": hues.gold,
  "Y": hues.yellow
};

class MainMenuScreen extends Screen<Input> {
  /// The number of heroes shown in the list at one time.
  static const _listHeight = 8;

  final Content content;
  final Storage storage;
  int selectedHero = 0;

  Game? _game;
  Iterator<String>? _generator;
  bool _lightDungeon = false;

  /// After dungeon is done being generated, how many frames to wait before
  /// making a new one.
  int _regenerateDelay = 0;

  /// Whether there are any screens above this one.
  ///
  /// We only want to update when you're actually on the main menu.
  // TODO: This seems like something malison should be able to handle directly.
  bool _isActive = true;

  /// How far down in the list of heroes the user has scrolled.
  int _scroll = 0;

  final LoopManager loopManager = LoopManager();
  
  MainMenuScreen(this.content) : storage = Storage(content) {
    // Create a default loop mode hero if none exist
    _ensureDefaultHero();
  }
  
  /// Ensure there's always a default hero for loop mode
  void _ensureDefaultHero() {
    if (storage.heroes.isEmpty) {
      return;
      //print("Creating default Loop Mode hero...");
      //var defaultHero = content.createHero("Loop Runner");
      //defaultHero.gold = 2000; // Give extra starting gold for loop mode
      //storage.heroes.add(defaultHero);
      //storage.save();
    }
  }

  void _startLoopModeWithExistingHero(HeroSave hero) {
    print("Starting loop mode with existing hero: ${hero.name}");
    
    // Reset hero to loop starting state
    hero.gold = max(hero.gold, 1500); // Ensure minimum gold
    
    // Create loop manager and start at proper depth
    var loopManager = LoopManager();
    loopManager.currentLoop = 1;
    loopManager.isLoopActive = true;
    loopManager.moveCount = 0;
    loopManager.threatLevel = 2; // Start at threat level 2 so depth = 1 + 2 = 3
    
    print("Starting Loop Game Screen");
    ui.push(LoopGameScreen.create(storage, content, hero, loopManager));
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n when selectedHero > 0:
        selectedHero--;
        _refreshScroll();
        dirty();
        return true;

      case Input.s when selectedHero < storage.heroes.length - 1:
        selectedHero++;
        _refreshScroll();
        dirty();
        return true;

      case Input.ok:
        if (storage.heroes.isEmpty) {
          // If no heroes exist, create a new one
          _isActive = false;
          ui.push(NewHeroScreen(content, storage));
        } else if (selectedHero < storage.heroes.length) {
          var save = storage.heroes[selectedHero];
          _isActive = false;
          _startLoopModeWithExistingHero(save);
        }
        return true;
    }

    return false;
  }

  void _refreshScroll() {
    // Keep it in bounds.
    _scroll = _scroll.clamp(0, max(storage.heroes.length - _listHeight, 0));

    // Show the selected hero.
    if (selectedHero < _scroll) {
      _scroll = selectedHero;
    } else if (selectedHero >= _scroll + _listHeight) {
      _scroll = selectedHero - _listHeight + 1;
    }
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.d:
        if (selectedHero < storage.heroes.length) {
          var name = storage.heroes[selectedHero].name;
          _isActive = false;
          ui.push(
              ConfirmPopup("Are you sure you want to delete $name?", 'delete'));
        }
        return true;

      case KeyCode.n:
        _isActive = false;
        ui.push(NewHeroScreen(content, storage));
        return true;
        

    }

    return false;
  }

  @override
  void activate(Screen popped, Object? result) {
    _isActive = true;

    if (popped is ConfirmPopup && result == "delete") {
      storage.heroes.remove(storage.heroes[selectedHero]);

      // If they deleted the last hero, keep the selection in bounds.
      if (selectedHero > 0 && selectedHero >= storage.heroes.length) {
        selectedHero--;
      }

      _refreshScroll();
      dirty();
    }
  }

  @override
  void resize(Vec size) {
    // Clear the dungeon so we generate a new one at the new size.
    _game = null;
    _generator = null;
  }

  @override
  void update() {
    if (!_isActive) return;

    if (_regenerateDelay > 0) {
      _regenerateDelay--;

      if (_regenerateDelay == 0) {
        // Kick off a new dungeon generation.
        _game = null;
        dirty();
      }

      return;
    }

    if (_generator case var generator?) {
      if (!generator.moveNext()) {
        _generator = null;

        // Wait ten seconds before regenerating.
        _regenerateDelay = 60 * 5;
        return;
      }

      if (generator.current == "Ready to decorate") _lightDungeon = true;
      if (_lightDungeon) {
        _game!.stage.tileOpacityChanged();
        _game!.stage.refreshView();
      }
      dirty();
    }
  }

  @override
  void render(Terminal terminal) {
    if (_game case var game?) {
      _renderDungeon(terminal, game);
    } else {
      var save = content.createHero("Temporary");
      var game = _game = Game(content, rng.inclusive(1, Option.maxDepth), save,
          width: terminal.width, height: terminal.height);

      _generator = game.generate().iterator;
      _lightDungeon = false;
      _renderDungeon(terminal, game);
    }

    // Center the content.
    var centerTerminal = terminal.rect(
        (terminal.width - 68) ~/ 2, (terminal.height - 34) ~/ 2, 68, 34);

    centerTerminal.clear();

    // Draw multiple devils across the top
    var devilPositions = [8, 23, 38, 53];
    for (var i = 0; i < devilPositions.length; i++) {
      var xOffset = devilPositions[i];
      for (var y = 0; y < _devilChars.length; y++) {
        var charLine = _devilChars[y];
        var colorLine = _devilColors[y];
        for (var x = 0; x < charLine.length && x < colorLine.length; x++) {
          if (charLine[x] != ' ') {
            var colorKey = colorLine[x];
            var color = _colors[colorKey] ?? hues.UIHue.text;
            centerTerminal.writeAt(x + xOffset, y + 3, charLine[x], color);
          }
        }
      }
    }

    centerTerminal.writeAt(3, 16, "Devil's Coil", hues.UIHue.text);

    Draw.hLine(centerTerminal, 3, 18, centerTerminal.width - 6);
    Draw.hLine(centerTerminal, 3, 27, centerTerminal.width - 6);

    if (storage.heroes.isEmpty) {
      centerTerminal.writeAt(
          3, 19, '(No heroes. Please create a new one.)', hues.UIHue.disabled);
    } else {
      if (_scroll > 0) {
        centerTerminal.writeAt(
            centerTerminal.width ~/ 2, 18, "▲", hues.UIHue.selection);
      }

      if (_scroll < storage.heroes.length - _listHeight) {
        centerTerminal.writeAt(
            centerTerminal.width ~/ 2, 27, "▼", hues.UIHue.selection);
      }

      for (var i = 0; i < _listHeight; i++) {
        var heroIndex = i + _scroll;
        if (heroIndex >= storage.heroes.length) break;

        var hero = storage.heroes[heroIndex];

        var primary = hues.UIHue.primary;
        var secondary = hues.UIHue.secondary;
        if (heroIndex == selectedHero) {
          primary = hues.UIHue.selection;
          secondary = hues.UIHue.selection;

          centerTerminal.drawChar(
              2, 19 + i, CharCode.blackRightPointingPointer, hues.UIHue.selection);
        }

        centerTerminal.writeAt(3, 19 + i, hero.name, primary);
        centerTerminal.writeAt(25, 19 + i, "Level ${hero.level}", secondary);
        centerTerminal.writeAt(34, 19 + i, hero.race.name, secondary);
        centerTerminal.writeAt(42, 19 + i, hero.heroClass.name, secondary);
        if (hero.permadeath) {
          centerTerminal.writeAt(55, 19 + i, "Permadeath", secondary);
        }
      }
    }

    Draw.helpKeys(terminal, {
      "OK": "Start",
      "↕": "Change",
      "N": "New",
      "D": "Delete",
    });
  }

  void _renderDungeon(Terminal terminal, Game game) {
    var stage = game.stage;

    for (var y = 0; y < stage.height; y++) {
      for (var x = 0; x < stage.width; x++) {
        var pos = Vec(x, y);
        _renderTile(terminal, game, pos);
      }
    }
  }

  void _renderTile(Terminal terminal, Game game, Vec pos) {
    var tile = game.stage[pos];

    var tileGlyph = switch (tile.type.appearance) {
      Glyph glyph => glyph,
      List<Glyph> glyphs =>
        // Calculate a "random" but consistent phase for each position.
        glyphs[hashPoint(pos.x, pos.y) % glyphs.length],
      _ => Glyph.clear,
    };

    var char = tileGlyph.char;
    var fore = tileGlyph.fore;
    var back = tileGlyph.back;
    var lightFore = true;
    var lightBack = true;

    // Show the item if the tile has been explored, even if not currently
    // visible.
    var items = game.stage.itemsAt(pos);
    if (items.isNotEmpty) {
      var itemGlyph = items.first.appearance as Glyph;
      char = itemGlyph.char;
      fore = itemGlyph.fore;
      lightFore = false;
    }

    // Show any actor on it.
    if (game.stage.actorAt(pos)?.appearance case Glyph actor) {
      char = actor.char;
      fore = actor.fore;
      lightFore = false;
    }

    Color multiply(Color a, Color b) {
      return Color(a.r * b.r ~/ 255, a.g * b.g ~/ 255, a.b * b.b ~/ 255);
    }

    // TODO: This could be cached if needed.
    var foreShadow = multiply(fore, const Color(80, 80, 95));
    var backShadow = multiply(back, const Color(20, 20, 35));

    // Apply lighting and visibility to the tile.
    Color applyLighting(Color color, Color shadow) {
      // Apply a slight brightness curve to either end of the range of
      // floor illumination. We keep most of the middle of the range flat
      // so that there is still a visible ramp down at the dark end and
      // just a small bloom around lights at the bright end.
      var visibility = tile.floorIllumination;
      if (visibility < 128) {
        color = color.blend(shadow, lerpDouble(visibility, 0, 127, 1.0, 0.0));
      } else if (visibility > 128) {
        color = color.add(hues.ash, lerpDouble(visibility, 128, 255, 0.0, 0.2));
      }

      if (tile.actorIllumination > 0) {
        const glow = Color(200, 130, 0);
        color = color.add(
            glow, lerpDouble(tile.actorIllumination, 0, 255, 0.05, 0.1));
      }

      return color;
    }

    if (lightFore) fore = applyLighting(fore, foreShadow);
    if (lightBack) back = applyLighting(back, backShadow);

    var glyph = Glyph.fromCharCode(char, fore, back);
    terminal.drawGlyph(pos.x, pos.y, glyph);
  }
}
