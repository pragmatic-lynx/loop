# Roguelite Loop System

This implementation adds a roguelite loop system to the Hauberk roguelike game for the 3-day game jam.

## Core Concept

Transform the traditional roguelike into short, tightly-scoped combat vignettes:
- Each run is a miniature combat encounter (50 moves)
- After each run, players select from 3 reward options
- Rewards provide temporary bonuses for the next run only
- Difficulty gradually increases with each loop

## How to Play

1. From the main menu, press **L** to enter Roguelite Loop mode
2. Select a hero preset (Warrior, Rogue, Mage, Ranger)
3. Complete combat encounters in 50 moves or less
4. Choose rewards to help with the next loop
5. Progress through increasingly difficult depths

## Features Implemented

### Core Systems
- **LoopManager**: Tracks loops, moves, and manages rewards
- **HeroPreset**: Quick hero configuration with different starting gear
- **LoopReward**: Temporary bonuses like damage boosts, armor, supplies

### UI Screens
- **LoopSetupScreen**: Select preset and start loops
- **LoopRewardScreen**: Choose from 3 reward options after each loop
- **Modified GameScreen**: Tracks moves and triggers reward selection
- **Updated Sidebar**: Shows loop progress (current loop, moves, depth)

### Reward Types
- **Combat Bonuses**: Damage boost, armor boost, health boost
- **Supply Drops**: Healing potions, food, scrolls, gold
- **Special Abilities**: Light radius, movement speed, lucky finds

## Technical Implementation

### Files Added
- `lib/src/engine/loop/loop_manager.dart` - Core loop system
- `lib/src/engine/loop/hero_preset.dart` - Hero configurations
- `lib/src/engine/loop/loop_reward.dart` - Reward system
- `lib/src/ui/loop_setup_screen.dart` - Preset selection
- `lib/src/ui/loop_reward_screen.dart` - Reward selection

### Files Modified
- `lib/src/ui/game_screen.dart` - Added loop integration
- `lib/src/ui/main_menu_screen.dart` - Added loop option
- `lib/src/ui/panel/sidebar_panel.dart` - Added loop info display
- `lib/src/engine.dart` - Added loop system exports

## Game Balance

- **Move Limit**: 50 moves per loop (tunable)
- **Starting Depth**: Depth 3 (early challenge)
- **Difficulty Scaling**: +1 depth per loop
- **Reward Variety**: 14 different reward types

## Future Enhancements

- Implement actual reward effects in combat/game systems
- Add investment system for permanent meta-progression
- Create more diverse reward types and hero presets
- Add visual effects for reward activation
- Balance move counts and difficulty scaling based on playtesting

The system is designed to be easily extensible and tunable for the game jam requirements.
