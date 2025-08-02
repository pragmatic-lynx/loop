// lib/src/ui/inventory_dialog.dart

import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';

import '../engine.dart';
import '../engine/loop/item/item_category.dart';
import '../hues.dart';
import 'draw.dart';
import 'input.dart';

/// Modal dialog showing the hero's complete inventory organized by category
class InventoryDialog extends Screen<Input> {
  final Game _game;

  InventoryDialog(this._game);

  @override
  bool get isTransparent => true;

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel || input == Input.inventory) {
      ui.pop();
      return true;
    }
    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (alt) return false;
    
    // Close on escape or J key
    if (keyCode == KeyCode.escape || keyCode == KeyCode.j) {
      ui.pop();
      return true;
    }
    
    return false;
  }

  @override
  void render(Terminal terminal) {
    var hero = _game.hero;
    
    // Calculate dialog size - wide enough for content
    var width = 60;
    var height = terminal.height - 4;
    var left = (terminal.width - width) ~/ 2;
    var top = 2;
    
    // Draw main dialog box
    Draw.frame(terminal, left, top, width, height, label: "INVENTORY");
    
    // Show help
    Draw.helpKeys(terminal, {
      'J/Esc': 'Close',
    });
    
    var y = top + 1;
    var x = left + 1;
    var contentWidth = width - 2;
    var maxY = top + height - 3; // Reserve space for bottom border
    
    // Group items by category
    var itemsByCategory = <ItemCategory, List<Item>>{};
    
    // Add inventory items
    for (var item in hero.inventory) {
      var category = ItemCategorizer.categorizeByName(item.type.name);
      itemsByCategory.putIfAbsent(category, () => []).add(item);
    }
    
    // Add equipped items to appropriate categories
    for (var item in hero.equipment) {
      var category = ItemCategorizer.categorizeByName(item.type.name);
      itemsByCategory.putIfAbsent(category, () => []).add(item);
    }
    
    // Show equipped gear first
    y = _drawEquippedGear(terminal, x, y, contentWidth, hero, maxY);
    
    // Show categories in logical order
    var categoryOrder = [
      ItemCategory.primary,
      ItemCategory.secondary, 
      ItemCategory.healing,
      ItemCategory.armor,
      ItemCategory.utility,
      ItemCategory.treasure,
    ];
    
    for (var category in categoryOrder) {
      var items = itemsByCategory[category] ?? [];
      if (items.isEmpty) continue;
      
      // Check if we have space for at least the category header
      if (y >= maxY - 2) {
        terminal.writeAt(x, y, "... (more items)", darkCoolGray);
        break;
      }
      
      y = _drawCategory(terminal, x, y, contentWidth, category, items, hero, maxY);
    }
  }
  
  int _drawEquippedGear(Terminal terminal, int x, int y, int width, Hero hero, int maxY) {
    terminal.writeAt(x, y, "═══ EQUIPPED GEAR ═══", gold);
    y += 1;
    
    var hasEquippedItems = false;
    
    // Show equipped items with slot names
    for (var i = 0; i < hero.equipment.slots.length; i++) {
      var item = hero.equipment.slots[i];
      var slotName = hero.equipment.slotTypes[i];
      
      if (item != null) {
        hasEquippedItems = true;
        
        // Draw item glyph and name
        var glyph = item.appearance as Glyph;
        terminal.drawGlyph(x, y, glyph);
        
        var itemText = "${item.type.name}";
        if (itemText.length > width - 25) {
          itemText = itemText.substring(0, width - 25);
        }
        
        terminal.writeAt(x + 2, y, itemText, ash);
        terminal.writeAt(x + width - 15, y, "($slotName)", darkCoolGray);
        
        // Show item stats if relevant
        if (item.attack != null) {
          var damage = "${item.attack!.damage} dmg";
          terminal.writeAt(x + 4, y + 1, damage, coolGray);
        } else if (item.baseArmor > 0) {
          var armor = "${item.baseArmor} armor";
          terminal.writeAt(x + 4, y + 1, armor, coolGray);
        }
        
        y += 2;
      }
    }
    
    if (!hasEquippedItems) {
      terminal.writeAt(x + 2, y, "(No equipment)", darkCoolGray);
      y += 1;
    }
    
    return y + 1;
  }
  
  int _drawCategory(Terminal terminal, int x, int y, int width, 
                   ItemCategory category, List<Item> items, Hero hero, int maxY) {
    // Category header
    terminal.writeAt(x, y, "${category.icon} ${category.displayName.toUpperCase()}", 
                    _getCategoryColor(category));
    y += 1;
    
    // Sort items by name for consistent display
    items.sort((a, b) => a.type.name.compareTo(b.type.name));
    
    // Group identical items and show counts
    var itemGroups = <String, List<Item>>{};
    for (var item in items) {
      itemGroups.putIfAbsent(item.type.name, () => []).add(item);
    }
    
    for (var entry in itemGroups.entries) {
      // Check if we have space for this item
      if (y >= maxY) {
        terminal.writeAt(x + 2, y, "... (more items in ${category.displayName})", darkCoolGray);
        y += 1;
        break;
      }
      
      var itemName = entry.key;
      var itemList = entry.value;
      var totalCount = itemList.fold(0, (sum, item) => sum + item.count);
      var item = itemList.first;
      
      // Skip if this item is equipped (already shown in equipped section)
      var isEquipped = hero.equipment.contains(item);
      if (isEquipped && itemList.length == 1) continue;
      
      // Draw item
      var glyph = item.appearance as Glyph;
      terminal.drawGlyph(x + 2, y, glyph);
      
      var displayText = itemName;
      if (displayText.length > width - 15) {
        displayText = displayText.substring(0, width - 15);
      }
      
      terminal.writeAt(x + 4, y, displayText, ash);
      
      // Show count if > 1
      if (totalCount > 1) {
        var countText = "x$totalCount";
        terminal.writeAt(x + width - countText.length - 1, y, countText, lima);
      }
      
      // Show if equipped (for stackable items where some are equipped)
      if (isEquipped) {
        terminal.writeAt(x + width - 10, y, "(equipped)", darkCoolGray);
      }
      
      y += 1;
    }
    
    return y + 1;
  }
  
  Color _getCategoryColor(ItemCategory category) {
    switch (category) {
      case ItemCategory.primary:
        return carrot;
      case ItemCategory.secondary:
        return lightBlue;
      case ItemCategory.healing:
        return red;
      case ItemCategory.armor:
        return peaGreen;
      case ItemCategory.utility:
        return tan;
      case ItemCategory.treasure:
        return gold;
    }
  }
}
