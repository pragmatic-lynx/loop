// lib/src/ui/loop_setup_screen.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import '../engine/loop/loop_manager.dart';
import '../engine/loop/hero_preset.dart';
import '../hues.dart';
import 'draw.dart';
import 'loop_game_screen.dart';
import 'input.dart';
import 'storage.dart';

class LoopSetupScreen extends Screen<Input> {
  static const _listHeight = 6;
  
  final Content content;
  final Storage storage;
  final LoopManager loopManager;
  final List<HeroPreset> presets;
  
  int selectedPreset = 0;
  
  LoopSetupScreen(this.content, this.storage, this.loopManager) 
      : presets = HeroPreset.getAllPresets();
  
  @override
  bool handleInput(Input input) {
    switch (input) {
      case Input.n when selectedPreset > 0:
        selectedPreset--;
        dirty();
        return true;
        
      case Input.s when selectedPreset < presets.length - 1:
        selectedPreset++;
        dirty();
        return true;
        
      case Input.ok:
        _startLoop();
        return true;
    }
    
    return false;
  }
  
  void _startLoop() {
    var preset = presets[selectedPreset];
    
    print("Starting loop with preset: ${preset.name}");
    
    // Create a temporary hero from the preset
    var hero = preset.createHero("Loop Hero", content);
    print("Created hero: ${hero.name}, class: ${hero.heroClass.name}");
    
    // Start the loop
    loopManager.startLoop(preset);
    
    // Apply any active rewards from previous loops
    loopManager.applyActiveRewards(hero);
    
    // Start the game at the appropriate depth
    var depth = loopManager.getCurrentDepth();
    print("Starting game at depth: $depth");
    
    ui.goTo(LoopGameScreen.create(storage, content, hero, loopManager));
  }
  
  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;
    
    switch (keyCode) {
      case KeyCode.escape:
        ui.pop();
        return true;
    }
    
    return false;
  }
  
  @override
  void render(Terminal terminal) {
    terminal.clear();
    
    // Center the content
    var centerTerminal = terminal.rect(
        (terminal.width - 70) ~/ 2, (terminal.height - 25) ~/ 2, 70, 25);
    
    centerTerminal.clear();
    Draw.doubleBox(centerTerminal, 0, 0, centerTerminal.width, centerTerminal.height);
    
    // Title
    centerTerminal.writeAt(3, 2, 'ROGUELITE LOOP', UIHue.primary);
    centerTerminal.writeAt(3, 3, 'Choose your configuration for this run', UIHue.text);
    
    // Loop info
    var status = loopManager.getStatus();
    centerTerminal.writeAt(3, 5, 'Current Loop: ${status['currentLoop']}', UIHue.secondary);
    centerTerminal.writeAt(3, 6, 'Threat Level: ${status['threatLevel']}', UIHue.secondary);
    centerTerminal.writeAt(3, 7, 'Target Depth: ${status['currentDepth']}', UIHue.secondary);
    
    Draw.hLine(centerTerminal, 3, 9, centerTerminal.width - 6);
    
    // Preset list
    centerTerminal.writeAt(3, 11, 'Select Hero Preset:', UIHue.text);
    
    for (var i = 0; i < presets.length; i++) {
      var preset = presets[i];
      var y = 13 + i * 2;
      
      var primary = UIHue.primary;
      var secondary = UIHue.secondary;
      
      if (i == selectedPreset) {
        primary = UIHue.selection;
        secondary = UIHue.selection;
        centerTerminal.drawChar(2, y, CharCode.blackRightPointingPointer, UIHue.selection);
      }
      
      centerTerminal.writeAt(3, y, preset.name, primary);
      centerTerminal.writeAt(15, y, preset.raceName, secondary);
      centerTerminal.writeAt(22, y, preset.className, secondary);
      centerTerminal.writeAt(3, y + 1, preset.description, UIHue.disabled);
    }
    
    Draw.helpKeys(terminal, {
      "OK": "Start Loop",
      "↕": "Change", 
      "Esc": "Back to menu",
    });
  }
}
