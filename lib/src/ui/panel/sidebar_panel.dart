import 'package:malison/malison.dart';

// TODO: Directly importing this is a little hacky. Put "appearance" on Element?
import '../../content/elements.dart';
import '../../debug.dart';
import '../../engine.dart';
import '../../hues.dart';
import '../draw.dart';
import '../game_screen_interface.dart';
import '../game_screen.dart';
import '../item/item_renderer.dart';
import 'panel.dart';

// TODO: Split this into multiple panels and/or give it a better name.
// TODO: There's room at the bottom of the panel for something else. Maybe a
// mini-map?
class SidebarPanel extends Panel {
  static final _resistLetters = {
    Elements.air: "A",
    Elements.earth: "E",
    Elements.fire: "F",
    Elements.water: "W",
    Elements.acid: "A",
    Elements.cold: "C",
    Elements.lightning: "L",
    Elements.poison: "P",
    Elements.dark: "D",
    Elements.light: "L",
    Elements.spirit: "S"
  };

  final GameScreenInterface _gameScreen;

  SidebarPanel(this._gameScreen);
  
  int _drawLoopInfo(Terminal terminal, int y) {
    var loopManager = _gameScreen.loopManager;
    if (loopManager is! LoopManager) return y;
    var status = loopManager.getStatus();
    
    terminal.writeAt(1, y, "Loop ${status['currentLoop']}", lightBlue);
    terminal.writeAt(1, y + 1, "Moves: ${status['moveCount']}/${status['moveCount'] + status['movesRemaining']}", ash);
    terminal.writeAt(1, y + 2, "Depth: ${status['currentDepth']}", coolGray);
    
    return y + 2;
  }

  @override
  void renderPanel(Terminal terminal) {
    var game = _gameScreen.game;
    var hero = game.hero;

    Draw.frame(terminal, 0, 0, terminal.width, terminal.height,
        label: hero.save.name);

    //terminal.writeAt(1, 2, "${hero.save.race.name} ${hero.save.heroClass.name}", gold);

    // Show loop information if in loop mode
    var y = 4;
    if (_gameScreen.loopManager != null) {
      y = _drawLoopInfo(terminal, y) + 1;
    }

    // Draw stats (takes 2 lines)
    _drawStats(hero, terminal, y);
    y += 3;

    // Draw health bar
    _drawHealth(hero, terminal, y);
    y += 1;
    
    // Draw level and gold
    _drawLevel(hero, terminal, y);
    y += 1;
    _drawGold(hero, terminal, y);
    y += 1;

    // Draw armor and defense
    _drawArmor(hero, terminal, y);
    y += 1;
    _drawDefense(hero, terminal, y);
    y += 1;
    _drawWeapons(hero, terminal, y);
    y += 2; // Extra space before meters

    // Draw meters
    _drawFood(hero, terminal, y);
    y += 1;
    _drawFocus(hero, terminal, y);
    y += 1;
    _drawFury(hero, terminal, y);
    y += 2; // Extra space before monsters

    // Draw the nearby monsters.
    // Draw player info with visual distinction
    terminal.writeAt(1, y, "@", _gameScreen.heroColor);
    terminal.writeAt(3, y, hero.save.name, gold);
    y += 1;
    
    // Draw decorative top border for HP bar
    terminal.writeAt(9, y, "╔" + "═" * (terminal.width - 11) + "╗", gold);
    y += 1;
    
    // Draw health bar with side borders
    terminal.writeAt(9, y, "║", gold);
    _drawHealthBar(terminal, y, hero);
    terminal.writeAt(terminal.width - 2, y, "║", gold);
    y += 1;
    
    // Draw decorative bottom border for HP bar
    terminal.writeAt(9, y, "╚" + "═" * (terminal.width - 11) + "╝", gold);
    y += 2; // Extra space after player HP

    var visibleMonsters = _gameScreen.stagePanel.visibleMonsters;
    visibleMonsters.sort((a, b) {
      var aDistance = (a.pos - hero.pos).lengthSquared;
      var bDistance = (b.pos - hero.pos).lengthSquared;
      return aDistance.compareTo(bDistance);
    });

    for (var i = 0; i < 10 && i < visibleMonsters.length; i++) {
      if (y >= terminal.height - 2) break;

      var monster = visibleMonsters[i];

      var glyph = monster.appearance as Glyph;
      if (_gameScreen.currentTargetActor == monster) {
        glyph = Glyph.fromCharCode(glyph.char, glyph.back, glyph.fore);
      }

      var name = monster.breed.name;
      if (name.length > terminal.width - 4) {
        name = name.substring(0, terminal.width - 4);
      }

      terminal.drawGlyph(1, y, glyph);
      terminal.writeAt(
          3,
          y,
          name,
          (_gameScreen.currentTargetActor == monster)
              ? UIHue.selection
              : UIHue.text);
      y += 1;

      _drawHealthBar(terminal, y, monster);
      y += 1;
    }
  }

  void _drawStats(Hero hero, Terminal terminal, int y) {
    var x = 1;
    void drawStat(StatBase stat) {
      terminal.writeAt(x, y, stat.name.substring(0, 3), UIHue.helpText);
      terminal.writeAt(
          x, y + 1, stat.value.toString().padLeft(3), UIHue.primary);
      x += (terminal.width - 4) ~/ 4;
    }

    drawStat(hero.strength);
    drawStat(hero.agility);
    drawStat(hero.fortitude);
    drawStat(hero.intellect);
    drawStat(hero.will);
  }

  void _drawHealth(Hero hero, Terminal terminal, int y) {
    _drawStat(terminal, y, "Health", hero.health, red, hero.maxHealth, maroon);
  }

  void _drawLevel(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Level", UIHue.helpText);

    var levelString = hero.level.toString();
    terminal.writeAt(
        terminal.width - levelString.length - 1, y, levelString, lightAqua);

    if (hero.level < Hero.maxLevel) {
      var levelPercent = 100 *
          (hero.experience - experienceLevelCost(hero.level)) ~/
          (experienceLevelCost(hero.level + 1) -
              experienceLevelCost(hero.level));
      Draw.thinMeter(terminal, 10, y, terminal.width - 14, levelPercent, 100,
          lightAqua, aqua);
    }
  }

  void _drawGold(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Gold", UIHue.helpText);
    var heroGold = formatMoney(hero.gold);
    terminal.writeAt(terminal.width - 1 - heroGold.length, y, heroGold, gold);
  }

  void _drawWeapons(Hero hero, Terminal terminal, int y) {
    var hits = hero.createMeleeHits(null).toList();

    var label = hits.length == 2 ? "Weapons" : "Weapon";
    terminal.writeAt(1, y, label, UIHue.helpText);

    for (var i = 0; i < hits.length; i++) {
      var hitString = hits[i].damageString;
      // TODO: Show element and other bonuses.
      terminal.writeAt(
          terminal.width - hitString.length - 1, y + i, hitString, carrot);
    }
  }

  void _drawDefense(Hero hero, Terminal terminal, int y) {
    var total = 0;
    for (var defense in hero.defenses) {
      total += defense.amount;
    }

    _drawStat(terminal, y, "Dodge", "$total%", aqua);
  }

  void _drawArmor(Hero hero, Terminal terminal, int y) {
    // Show equipment resistances.
    var x = 10;
    for (var element in Elements.all) {
      if (hero.resistance(element) > 0) {
        terminal.writeAt(x, y, _resistLetters[element]!, elementColor(element));
        x++;
      }
    }

    var armor = " ${(100 - getArmorMultiplier(hero.armor) * 100).toInt()}%";
    _drawStat(terminal, y, "Armor", armor, peaGreen);
  }

  void _drawFood(Hero hero, Terminal terminal, int y) {
    terminal.writeAt(1, y, "Food", UIHue.helpText);
    Draw.thinMeter(terminal, 10, y, terminal.width - 11, hero.stomach,
        Option.heroMaxStomach, tan, brown);
  }

  void _drawFocus(Hero hero, Terminal terminal, int y) {
    // TODO: Show bar once these are tuned.
    // terminal.writeAt(1, y, 'Focus', UIHue.helpText);
    // Draw.thinMeter(terminal, 10, y, terminal.width - 11, hero.focus,
    //     hero.intellect.maxFocus, blue, darkBlue);
    _drawStat(terminal, y, 'Focus', hero.focus, blue, hero.intellect.maxFocus,
        darkBlue);
  }

  void _drawFury(Hero hero, Terminal terminal, int y) {
    // If the hero can't have any fury, gray it out.
    terminal.writeAt(1, y, 'Fury',
        hero.strength.maxFury == 0 ? UIHue.disabled : UIHue.helpText);

    terminal.writeAt(
        terminal.width - 3, y, hero.fury.toString().padLeft(2), persimmon);

    if (hero.fury > 0) {
      var scale = "${hero.strength.furyScale(hero.fury).toStringAsFixed(1)}x";
      terminal.writeAt(10, y, scale.padLeft(4),
          hero.fury == hero.strength.maxFury ? carrot : persimmon);
    }
  }

  /// Draws a labeled numeric stat.
  void _drawStat(
      Terminal terminal, int y, String label, Object value, Color valueColor,
      [int? max, Color? maxColor]) {
    terminal.writeAt(1, y, label, UIHue.helpText);

    var x = terminal.width - 1;
    if (max != null) {
      var maxString = max.toString();
      x -= maxString.length;
      terminal.writeAt(x, y, maxString, maxColor);

      x -= 3;
      terminal.writeAt(x, y, " / ", maxColor);
    }

    var valueString = value.toString();
    x -= valueString.length;
    terminal.writeAt(x, y, valueString, valueColor);
  }

  /// Draws a health bar for [actor].
  void _drawHealthBar(Terminal terminal, int y, Actor actor) {
    // Show conditions.
    var x = 11; // Increased from 3 to account for border

    void drawCondition(String char, Color fore, [Color? back]) {
      // Don't overlap other stuff.
      if (x > 16) return; // Adjusted for new starting position

      terminal.writeAt(x, y, char, fore, back);
      x++;
    }

    if (actor is Monster && actor.isAfraid) {
      drawCondition("!", sandal);
    }

    if (actor is Monster && actor.isAsleep) {
      drawCondition("z", darkBlue);
    }

    if (actor.poison.isActive) {
      switch (actor.poison.intensity) {
        case 1:
          drawCondition("P", sherwood);
        case 2:
          drawCondition("P", peaGreen);
        default:
          drawCondition("P", mint);
      }
    }

    if (actor.cold.isActive) drawCondition("C", lightBlue);
    switch (actor.haste.intensity) {
      case 1:
        drawCondition("S", tan);
      case 2:
        drawCondition("S", gold);
      case 3:
        drawCondition("S", buttermilk);
    }

    if (actor.blindness.isActive) drawCondition("B", darkCoolGray);
    if (actor.dazzle.isActive) drawCondition("D", lilac);
    if (actor.perception.isActive) drawCondition("V", ash);

    for (var element in Elements.all) {
      if (actor.resistanceCondition(element).isActive) {
        drawCondition(
            _resistLetters[element]!, Color.black, elementColor(element));
      }
    }

    if (Debug.showMonsterAlertness && actor is Monster) {
      var alertness = (actor.alertness * 100).toInt().toString().padLeft(3);
      terminal.writeAt(2, y, alertness, ash);
    }

Draw.meter(terminal, 11, y, terminal.width - 13, actor.health,
        actor.maxHealth, red, maroon);
  }
}
