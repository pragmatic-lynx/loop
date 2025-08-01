// lib/src/ui/panel/equipment_status_panel.dart

import 'package:malison/malison.dart';

import '../../engine/core/game.dart';
import '../../engine/items/item.dart';
import '../../engine/items/equipment.dart';
import '../../hues.dart';
import '../draw.dart';
import 'panel.dart';

/// Panel showing current equipment and active weapon for quick reference
class EquipmentStatusPanel extends Panel {
  final Game game;
  
  EquipmentStatusPanel(this.game);
  
  @override
  void renderPanel(Terminal terminal) {
    Draw.frame(terminal, 0, 0, terminal.width, terminal.height, label: "GEAR");
    
    var hero = game.hero;
    var y = 1;
    
    // Active weapon
    terminal.writeAt(1, y, "Active:", ash);
    var weapons = hero.equipment.weapons;
    if (weapons.isNotEmpty) {
      var weapon = weapons.first;
      terminal.writeAt(1, y + 1, "🗡️ ${weapon.type.name}", lightBlue);
      if (weapon.attack != null) {
        var damage = weapon.attack!.damage.toString();
        terminal.writeAt(1, y + 2, "  ${damage} dmg", coolGray);
      }
    } else {
      terminal.writeAt(1, y + 1, "🗡️ Fists", lightBlue);
      terminal.writeAt(1, y + 2, "  1 dmg", coolGray);
    }
    
    y += 4;
    
    // Armor
    var armorPiece = _getArmorPiece(hero.equipment);
    if (armorPiece != null) {
      terminal.writeAt(1, y, "Armor:", ash);
      var armorText = armorPiece.type.name;
      if (armorText.length > terminal.width - 3) {
        armorText = armorText.substring(0, terminal.width - 3);
      }
      terminal.writeAt(1, y + 1, "🛡️ $armorText", peaGreen);
      terminal.writeAt(1, y + 2, "  ${armorPiece.type.armor} armor", coolGray);
      y += 3;
    }
    
    // Secondary weapon / ranged
    var secondaryWeapon = _getSecondaryWeapon(hero.equipment.weapons.toList());
    if (secondaryWeapon != null) {
      terminal.writeAt(1, y, "Secondary:", ash);
      var weaponText = secondaryWeapon.type.name;
      if (weaponText.length > terminal.width - 3) {
        weaponText = weaponText.substring(0, terminal.width - 3);
      }
      terminal.writeAt(1, y + 1, "🏹 $weaponText", lima);
      y += 2;
    }
    
    // Active spell with glyph
    var activeSpell = _getActiveSpell();
    if (activeSpell != null) {
      terminal.writeAt(1, y, "Active Spell:", ash);
      var spellGlyph = _getSpellGlyph(activeSpell);
      var spellText = _getShortSpellName(activeSpell);
      if (spellText.length > terminal.width - 5) {
        spellText = spellText.substring(0, terminal.width - 5);
      }
      terminal.writeAt(1, y + 1, "$spellGlyph $spellText", violet);
      var count = _getSpellCount(activeSpell);
      if (count > 1) {
        terminal.writeAt(1, y + 2, "  x$count", coolGray);
      }
      
      // Show cooldown for summon spells
      if (_isSummonSpell(activeSpell)) {
        var cooldown = _getSummonCooldown();
        if (cooldown > 0) {
          terminal.writeAt(1, y + 3, "  CD: ${cooldown}s", yellow);
        }
      }
    }
  }
  
  Item? _getSecondaryWeapon(List<Item> weapons) {
    // Find bow, dart, or other ranged weapon
    for (var weapon in weapons) {
      var name = weapon.type.name.toLowerCase();
      if (name.contains('bow') || 
          name.contains('dart') || 
          name.contains('sling') ||
          name.contains('crossbow')) {
        return weapon;
      }
    }
    return null;
  }
  
  Item? _getActiveSpell() {
    // Get first spell from inventory (will be implemented with spell cycling)
    for (var item in game.hero.inventory) {
      var name = item.type.name.toLowerCase();
      if (name.contains('scroll') && 
          (name.contains('lightning') ||
           name.contains('fireball') ||
           name.contains('ice') ||
           name.contains('teleport') ||
           name.contains('summon'))) {
        return item;
      }
    }
    return null;
  }
  
  int _getSpellCount(Item spell) {
    return spell.count;
  }
  
  String _getSpellGlyph(Item spell) {
    var name = spell.type.name.toLowerCase();
    if (name.contains('lightning') || name.contains('bolt')) return '⚡';
    if (name.contains('fire') || name.contains('fireball')) return '🔥';
    if (name.contains('ice') || name.contains('frost')) return '❄️';
    if (name.contains('teleport')) return '🌀';
    if (name.contains('heal')) return '❤️';
    if (name.contains('summon')) return '👾';
    return '✨'; // Default magic sparkle
  }
  
  String _getShortSpellName(Item spell) {
    var name = spell.type.name;
    // Remove "Scroll of" prefix if present
    if (name.startsWith('Scroll of ')) {
      name = name.substring(10);
    }
    return name;
  }
  
  bool _isSummonSpell(Item spell) {
    return spell.type.name.toLowerCase().contains('summon');
  }
  
  int _getSummonCooldown() {
    // This would be implemented with actual cooldown tracking
    // For now, return 0 (no cooldown)
    return 0;
  }
  
  Item? _getArmorPiece(Equipment equipment) {
    // Look for body armor first, then helm, then other armor pieces
    for (var item in equipment) {
      if (item.equipSlot == 'body' || 
          item.equipSlot == 'helm' ||
          item.equipSlot == 'gloves' ||
          item.equipSlot == 'boots' ||
          item.equipSlot == 'cloak') {
        return item;
      }
    }
    return null;
  }
}
