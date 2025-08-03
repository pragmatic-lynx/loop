import 'dart:convert';
import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../hues.dart';
import 'draw.dart';
import 'loop_game_screen.dart';
import 'input.dart';
import 'storage.dart';

// From: http://medieval.stormthecastle.com/medieval-names.htm.
const _defaultNames = [
  "Merek",
  "Carac",
  "Ulric",
  "Tybalt",
  "Borin",
  "Sadon",
  "Terrowin",
  "Rowan",
  "Forthwind",
  "Althalos",
  "Fendrel",
  "Brom",
  "Hadrian",
  "Crewe",
  "Bolbec",
  "Fenwick",
  "Mowbray",
  "Drake",
  "Bryce",
  "Leofrick",
  "Letholdus",
  "Lief",
  "Barda",
  "Rulf",
  "Robin",
  "Gavin",
  "Terrin",
  "Jarin",
  "Cedric",
  "Gavin",
  "Josef",
  "Janshai",
  "Doran",
  "Asher",
  "Quinn",
  "Xalvador",
  "Favian",
  "Destrian",
  "Dain",
  "Millicent",
  "Alys",
  "Ayleth",
  "Anastas",
  "Alianor",
  "Cedany",
  "Ellyn",
  "Helewys",
  "Malkyn",
  "Peronell",
  "Thea",
  "Gloriana",
  "Arabella",
  "Hildegard",
  "Brunhild",
  "Adelaide",
  "Beatrix",
  "Emeline",
  "Mirabelle",
  "Helena",
  "Guinevere",
  "Isolde",
  "Maerwynn",
  "Catrain",
  "Gussalen",
  "Enndolynn",
  "Krea",
  "Dimia",
  "Aleida"
];

// TODO: Update to handle resizable UI.

/// Gets the starting weapon for a given class name
String _getStartingWeapon(String className) {
  // From weapon_tiers.json starting weapons
  switch (className.toLowerCase()) {
    case 'warrior':
      return 'Stick';
    case 'ranger':
      return 'Short Bow';
    case 'mage':
      return 'Walking Stick';
    default:
      return 'Stick'; // Default fallback
  }
}

class NewHeroScreen extends Screen<Input> {
  final Content _content;
  final Storage _storage;

  /// Index of the control that has focus.
  int _focus = 0;

  final NameControl _name;
  final SelectControl _class;
  final List<Control> _controls = [];

  NewHeroScreen(this._content, this._storage)
      : _name = NameControl(0, 0, _storage),
        _class = SelectControl(
            0, 4, "Class", ["Ranger", "Mage"]) {
    _controls.addAll([_name, _class]);

    // Auto-select Ranger (index 0)
    _class.selected = 0;
  }

  @override
  void render(Terminal terminal) {
    Draw.dialog(terminal, 60, 20,
        label: "Create New Hero",
        (terminal) {
      for (var i = 0; i < _controls.length; i++) {
        _controls[i].render(terminal, focus: i == _focus);
      }
    }, helpKeys: {
      "Tab": "Next field",
      ..._controls[_focus].helpKeys,
      if (_name._isUnique) "Enter": "Create hero",
      "`": "Cancel"
    });
  }

  @override
  bool handleInput(Input input) {
    if (_controls[_focus].handleInput(input)) {
      dirty();
      return true;
    }

    switch (input) {
      case Input.cancel:
        ui.pop();
        return true;
    }

    return false;
  }

  void _startLoopMode(HeroSave hero) {
    print("Starting loop mode for new hero: ${hero.name}");
    
    // Give the hero some starting gold and basic equipment for loop mode
    hero.gold = 1500;
    
    // Add class-specific starting equipment based on weapon_tiers.json
    try {
      // Get the appropriate starting weapon for this class
      var startingWeaponName = _getStartingWeapon(hero.heroClass.name);
      var startingWeapon = _content.tryFindItem(startingWeaponName);
      if (startingWeapon != null) {
        var weaponItem = Item(startingWeapon, 1);
        hero.equipment.equip(weaponItem);
        print("Equipped ${hero.heroClass.name} with starting weapon: $startingWeaponName");
      } else {
        print("Warning: Could not find starting weapon '$startingWeaponName' for ${hero.heroClass.name}");
        // Fallback to Club
        var club = _content.tryFindItem("Club");
        if (club != null) {
          var clubItem = Item(club, 1);
          hero.equipment.equip(clubItem);
        }
      }
      
      var robe = _content.tryFindItem("Robe");
      if (robe != null) {
        var robeItem = Item(robe, 1);
        hero.equipment.equip(robeItem);
      }
      
      var healingPotion = _content.tryFindItem("Healing Potion");
      if (healingPotion != null) {
        var potionItem = Item(healingPotion, 3);
        hero.inventory.tryAdd(potionItem);
      }
    } catch (e) {
      print("Error adding items: $e");
    }
    
    // Create loop manager and start at proper depth
    var loopManager = LoopManager();
    loopManager.currentLoop = 1;
    loopManager.isLoopActive = true;
    loopManager.moveCount = 0;
    loopManager.threatLevel = 2; // Start at threat level 2 so depth = 1 + 2 = 3
    
    print("Going to loop game screen...");
    ui.goTo(LoopGameScreen.create(_storage, _content, hero, loopManager));
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (_controls[_focus].keyDown(keyCode, shift: shift, alt: alt)) {
      dirty();
      return true;
    }

    if (alt) return false;

    switch (keyCode) {
      // We look for "enter" explicitly and not Input.OK, because typing "l"
      // should enter that letter, not create a hero.
      case KeyCode.enter when _name._isUnique:
        // Get the selected class (Ranger or Mage)
        var selectedClassName = _class._options[_class.selected];
        var heroClass = _content.classes.firstWhere((cls) => cls.name == selectedClassName);
        
        // Random race selection
        var randomRace = _content.races[rng.range(_content.races.length)];
        
        var hero = _content.createHero(_name._name,
            race: randomRace,
            heroClass: heroClass,
            permadeath: false); // Default to stairs death
        _storage.add(hero);
        
        // Start loop mode immediately instead of going to town
        _startLoopMode(hero);
        return true;

      case KeyCode.tab:
        var offset = shift ? _controls.length - 1 : 1;
        _focus = (_focus + offset) % _controls.length;
        dirty();
        return true;
    }

    return false;
  }
}

abstract class Control {
  Map<String, String> get helpKeys;

  bool handleInput(Input input) => false;

  bool keyDown(int keyCode, {required bool shift, required bool alt}) => false;

  void render(Terminal terminal, {required bool focus});
}

class NameControl extends Control {
  static const _maxNameLength = 20;

  final int _x;
  final int _y;

  final Storage _storage;

  String _enteredName = "";

  String _defaultName = rng.item(_defaultNames);

  String get _name => _enteredName.isNotEmpty ? _enteredName : _defaultName;

  bool _isUnique = false;

  NameControl(this._x, this._y, this._storage) {
    _refreshUnique();
  }

  @override
  Map<String, String> get helpKeys => const {"A-Z Del": "Edit name"};

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;

    switch (keyCode) {
      case KeyCode.delete:
        if (_enteredName.isNotEmpty) {
          _enteredName = _enteredName.substring(0, _enteredName.length - 1);

          // Pick a new default name.
          if (_enteredName.isEmpty) {
            _defaultName = rng.item(_defaultNames);
          }
        }

        _refreshUnique();
        return true;

      case KeyCode.space:
        // TODO: Handle modifiers.
        _append(" ");
        return true;

      default:
        var key = keyCode;

        if (key >= KeyCode.a && key <= KeyCode.z) {
          // TODO: Figuring out the char code manually here is lame. Pass it
          // in from the KeyEvent?
          var charCode = key;
          // TODO: Handle other modifiers.
          if (!shift) {
            charCode = 'a'.codeUnits[0] - 'A'.codeUnits[0] + charCode;
          }

          _append(String.fromCharCode(charCode));
          return true;
        } else if (key >= KeyCode.zero && key <= KeyCode.nine) {
          _append(String.fromCharCode(key));
          return true;
        }
    }

    return false;
  }

  void _append(String append) {
    if (_enteredName.length < _maxNameLength) {
      _enteredName += append;
    }

    _refreshUnique();
  }

  /// See if there is already a hero with this name.
  ///
  /// We don't allow heroes to share the same name because when permadeath is
  /// on, we use the name to figure out which hero to delete from storage.
  void _refreshUnique() {
    _isUnique = _storage.heroes.every((hero) => hero.name != _name);
  }

  @override
  void render(Terminal terminal, {required bool focus}) {
    var color = _isUnique ? UIHue.selection : red;

    terminal.writeAt(_x, _y + 1, "Name:", focus ? UIHue.selection : UIHue.text);
    if (focus) {
      Draw.box(terminal, _x + 18, _y, 23, 3, color);
    }

    if (_enteredName.isNotEmpty) {
      terminal.writeAt(_x + 19, _y + 1, _enteredName, UIHue.primary);
      if (focus) {
        terminal.writeAt(
            _x + 19 + _enteredName.length, _y + 1, " ", Color.black, color);
      }
    } else {
      if (focus) {
        terminal.writeAt(_x + 19, _y + 1, _defaultName, Color.black, color);
      } else {
        terminal.writeAt(_x + 19, _y + 1, _defaultName, UIHue.primary);
      }
    }

    if (!_isUnique) {
      terminal.writeAt(42, 1, "Already a hero with that name", red);
    }
  }
}

class SelectControl extends Control {
  final int _x;
  final int _y;
  final String _name;
  final List<String> _options;

  int selected = 0;

  SelectControl(this._x, this._y, this._name, this._options);

  @override
  Map<String, String> get helpKeys => {"◄►": "Select ${_name.toLowerCase()}"};

  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.w:
        selected = (selected + _options.length - 1) % _options.length;
        return true;
      case Input.e:
        selected = (selected + 1) % _options.length;
        return true;
    }

    return false;
  }

  @override
  void render(Terminal terminal, {required bool focus}) {
    terminal.writeAt(
        _x, _y + 1, "$_name:", focus ? UIHue.selection : UIHue.text);

    if (focus) {
      var x = _x + 19;
      for (var i = 0; i < _options.length; i++) {
        var option = _options[i];

        if (i == selected) {
          Draw.box(terminal, x - 1, _y, option.length + 2, 3, UIHue.selection);
          terminal.writeAt(x - 1, _y + 1, "◄", UIHue.selection);
          terminal.writeAt(x + option.length, _y + 1, "►", UIHue.selection);
        }

        terminal.writeAt(
            x, _y + 1, option, i == selected ? UIHue.selection : UIHue.primary);
        x += option.length + 2;
      }
    } else {
      terminal.writeAt(_x + 19, _y + 1, _options[selected], UIHue.primary);
    }
  }
}
