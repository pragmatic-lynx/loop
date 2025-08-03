# SFX System Documentation

## Overview

The game now includes a fail-safe SFX system that automatically loads and plays audio files based on naming conventions. The system will continue to work even if audio files are missing or audio is not supported.

## Quick Setup

1. **Drop audio files** into the appropriate folders under `assets/audio/sfx/`
2. **Follow naming conventions** for automatic detection
3. **No code changes required** - audio will play automatically!

## Folder Structure

```
assets/audio/sfx/
├── player/           # Player action sounds
├── enemy/            # Enemy sounds  
├── ui/               # User interface sounds
├── loot/             # Item pickup sounds
├── loops/            # Continuous/looping sounds
└── stingers/         # Impact/notification sounds
```

## Naming Convention

- **snake_case** names only (no spaces)
- **Category prefix** (player_, enemy_, ui_, etc.)
- **Variation numbers** for randomness (_01, _02, _03...)
- **File types**: `.ogg` preferred, `.wav` supported

## Current Sound Events

| Action | Expected File(s) | When It Plays |
|--------|------------------|---------------|
| Player attacks | `player/magic_hit_01.ogg` | When player hits enemy |
| Arrows fired | `player/arrow_release_01.ogg` | When throwing/shooting |
| Arrow hits | `player/arrow_impact_wood_01.ogg` | When projectile impacts |
| Enemy dies | `enemy/enemy_death_01.ogg` | When enemy is killed |
| UI confirm | `ui/ui_confirm_01.ogg` | When confirming actions (Y key) |
| UI cancel | `ui/ui_cancel_01.ogg` | When canceling (N, Escape) |
| Item pickup | `loot/coin_pickup_01.ogg` | When picking up items |
| Level up | `stingers/level_up_01.ogg` | When hero levels up |

## Adding Variations

To add multiple variations of a sound:
```
player/arrow_release_01.ogg  ← Original
player/arrow_release_02.ogg  ← Variation 1  
player/arrow_release_03.ogg  ← Variation 2
```

The system will randomly pick one when playing.

## Fail-Safe Behavior

- **Missing files**: Logs a warning once but continues gameplay
- **No audio support**: Silently ignores audio calls
- **File errors**: Logs error but doesn't crash

## Technical Notes

- Audio is loaded at startup
- Uses Web Audio API for web deployment
- Volume and pitch variation supported
- Looping sounds supported (for spells, ambient, etc.)

## For Developers

### Adding New Sound Events

1. Add constant to `SfxId` class
2. Call `AudioManager.i.play(SfxId.yourSound)` in appropriate action
3. Add expected filename to documentation

### Example Usage

```dart
// Simple sound
AudioManager.i.play(SfxId.playerArrowRelease);

// With pitch variation
AudioManager.i.play(SfxId.playerMagicHit, pitchVar: 0.1);

// Looping sound
AudioManager.i.loop(SfxId.mageChargeLoop);
AudioManager.i.stopLoop(SfxId.mageChargeLoop);
```

## Game Jam Usage

This system is designed for rapid iteration during the 3-day "Loop" game jam:

1. **Artists/Sound designers**: Drop files in folders, follow naming convention
2. **Programmers**: Add `AudioManager.i.play()` calls to actions  
3. **No coordination needed**: Missing files won't break the game

The system supports the "Loop" theme with built-in looping sound capabilities and the game's loop mechanics get audio feedback automatically.
