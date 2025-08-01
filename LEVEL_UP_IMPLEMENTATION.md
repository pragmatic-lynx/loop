# Level-Up System Implementation Summary

## Changes Made

### 1. Core System Files

**`lib/src/engine/core/constants.dart`** - New file
- Added configurable stair XP bonus (25 XP)
- Added XP curve constants and asset path

**`web/assets/xp_curve.json`** - New file
- XP requirements for levels 0-49
- Hot-reloadable for balance tweaking

### 2. Hero System Changes

**`lib/src/engine/hero/hero_save.dart`**
- Added `pendingLevels` property to track level-ups

**`lib/src/engine/hero/hero.dart`**
- Added `gainExperience(int amount)` method
- Immediate level-up detection and toast notifications
- XP curve table loading (defaults to constants)
- Modified `onKilled()` to use new `gainExperience()` method
- Updated `experienceLevel()` and `experienceLevelCost()` functions

### 3. Loop Manager Updates

**`lib/src/engine/loop/loop_manager.dart`**
- Added `finishLoop(HeroSave hero)` method
- Returns true if level-up screen should be shown

### 4. UI Components

**`lib/src/ui/level_up_screen.dart`** - New file
- Shows level-up notification
- Awards skill points automatically
- Displays current skills and levels
- Handles multiple pending level-ups

**`lib/src/ui/loop_game_screen.dart`**
- Modified `_handleLoopExit()` to award stair XP bonus
- Added level-up screen integration
- Added necessary imports

**`lib/src/ui/loop_reward_screen.dart`**
- Added level-up screen after reward selection
- Added necessary imports

## How It Works

### XP Gain Flow
1. **Monster Kills**: `Hero.onKilled()` → `gainExperience()` → immediate level check
2. **Stair Descent**: `_handleLoopExit()` → `gainExperience(25)` → immediate level check

### Level-Up Flow
1. XP gained → level threshold crossed → `pendingLevels++` → toast notification
2. End of loop → `finishLoop()` checks `pendingLevels > 0`
3. If pending → show `LevelUpScreen` → award skill points → clear `pendingLevels`

### Key Features
- ✅ **Mid-floor level-ups**: Players get XP and level notifications immediately
- ✅ **Stair XP bonus**: 25 XP for descending (configurable)
- ✅ **Deferred UI**: Level-up dialog only appears at end of loop sequence
- ✅ **Skill point rewards**: Awards 3 skill points per level (existing game mechanic)
- ✅ **Multiple level-ups**: Handles gaining multiple levels in one loop
- ✅ **Hot-reload XP curve**: JSON file for easy balance tweaking

## Configuration

### Tuning Balance
- **Stair XP**: Modify `GameConstants.stairXpBonus` in `constants.dart`
- **Skill Points**: Modify `Option.skillPointsPerLevel` in `option.dart`
- **XP Curve**: Edit `web/assets/xp_curve.json` (reloads on game restart)

### Future Enhancements
- Sound effect integration (`levelup.ogg`)
- Choice-based stat increases instead of random skill point allocation
- More sophisticated level-up rewards (perks, abilities, etc.)

## File Structure
```
lib/src/engine/core/constants.dart          (new)
lib/src/engine/hero/hero.dart               (modified)
lib/src/engine/hero/hero_save.dart          (modified)
lib/src/engine/loop/loop_manager.dart       (modified)
lib/src/ui/level_up_screen.dart             (new)
lib/src/ui/loop_game_screen.dart            (modified)
lib/src/ui/loop_reward_screen.dart          (modified)
web/assets/xp_curve.json                    (new)
```

The implementation successfully separates XP gain (immediate) from level-up UI (end-of-loop), maintaining smooth gameplay flow while ensuring players get rewarded for their progress.
