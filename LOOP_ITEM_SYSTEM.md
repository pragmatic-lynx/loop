# Loop Item System

The Loop Item System provides dynamic item progression and rewards for the roguelite loop mode. It categorizes items into functional groups and allows easy configuration of what items appear at different loops.

## Features

- **Item Categories**: Items are automatically categorized as Primary, Secondary, Healing, Armor, Utility, or Treasure
- **Loop Progression**: Starting items and rewards scale with loop level
- **Easy Configuration**: JSON config file for editing item availability
- **Smart Combat Integration**: Action buttons show context-aware labels based on equipped items

## Item Categories

- **🗡️ Primary**: Main weapons for action1 (swords, axes, maces, etc.)
- **⚡ Secondary**: Ranged weapons, scrolls, spells for action2 (bows, darts, magic)
- **❤️ Healing**: Potions, food, healing items for action3
- **🛡️ Armor**: Protective equipment (armor, shields, helmets, etc.)
- **🔧 Utility**: General utility items
- **💰 Treasure**: Gold and valuable items

## Configuration

Edit `loop_item_config.json` in the project root to customize:

### Starting Items
Items given to heroes at the start of each loop based on loop level:

```json
{
  "itemName": "Sword",
  "category": "primary", 
  "minLoop": 4,
  "maxLoop": 10,
  "weight": 15,
  "quantity": 1
}
```

### Reward Items
Items that can appear as rewards when completing loops:

```json
{
  "itemName": "Healing Potion",
  "category": "healing",
  "minLoop": 1,
  "maxLoop": 999,
  "weight": 20,
  "quantity": 5
}
```

### Parameters

- **itemName**: Exact name of the item type in the game
- **category**: One of: primary, secondary, healing, armor, utility, treasure  
- **minLoop**: First loop this item can appear (1-based)
- **maxLoop**: Last loop this item can appear (999 for always)
- **weight**: Probability weight (higher = more likely to appear)
- **quantity**: How many of this item to give

## Smart Combat Labels

The action buttons now show dynamic labels based on your equipment:

- **Action1 (🗡️)**: "Slash" (sword), "Chop" (axe), "Smash" (mace), etc.
- **Action2 (⚡)**: "Shoot" (bow), "Zap" (lightning scroll), "Cast" (magic), etc.
- **Action3 (❤️)**: "Heal" (potions), "Rest" (when healthy), with item counts

## Integration

The system integrates with existing components:

- **HeroPreset**: Starting equipment is enhanced with loop-scaled items
- **LoopReward**: Now includes actual item rewards alongside temporary bonuses  
- **SmartCombat**: Action labels reflect current equipment and available items
- **LoopManager**: Manages progression and applies items at appropriate times

## Usage

The system automatically:

1. **Categorizes items** based on their names and types
2. **Scales starting items** based on current loop level
3. **Generates item rewards** when loops complete
4. **Updates action labels** based on equipped items
5. **Manages item progression** across multiple loops

No manual intervention needed - just configure the JSON file and the system handles the rest!

## File Structure

```
lib/src/engine/loop/item/
├── item_category.dart          # Item categorization system
├── loop_item_config.dart       # Configuration loading/saving
├── loop_item_manager.dart      # Core item management
└── item_loop_system.dart       # Export file

loop_item_config.json           # Editable configuration file
```
