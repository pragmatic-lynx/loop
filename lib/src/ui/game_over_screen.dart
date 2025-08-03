import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import 'draw.dart';
import 'input.dart';
import 'new_hero_screen.dart';
import 'storage.dart';

class GameOverScreen extends Screen<Input> {
  final HeroSave _hero;
  final Storage _storage;
  final Content _content;

  GameOverScreen(this._storage, this._hero, HeroSave previousSave, this._content) {
    // If they have permadeath on, delete the hero.
    if (_hero.permadeath) {
      _storage.remove(_hero);
    } else {
      _storage.replace(previousSave);
    }
    _storage.save();
  }

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case 96: // Backtick key
        if (_hero.permadeath) {
          // Create a new hero - pop this screen and push new hero screen
          ui.pop();
          ui.push(NewHeroScreen(_content, _storage));
        } else {
          // Try again - pop back to main menu
          ui.pop();
        }
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal) {
    // TODO: This could be a whole lot more interesting looking. Show the hero's
    // final stats, etc.
    Draw.dialog(terminal, 60, 40, label: "You have died", (terminal) {
      var y = terminal.height - 1;
      for (var i = _hero.log.messages.length - 1; i >= 0; i--) {
        // TODO: Include count, lines, color.
        var lines = Log.wordWrap(terminal.width, _hero.log.messages[i].text);
        for (var j = lines.length - 1; j >= 0; j--) {
          terminal.writeAt(0, y, lines[j]);
          y--;
          if (y < 0) break;
        }

        if (y < 0) break;
      }
    }, helpKeys: {'`': _hero.permadeath ? "Create a new hero" : "Try again"});
  }
}
