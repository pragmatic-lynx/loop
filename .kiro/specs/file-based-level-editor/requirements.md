## Feature

This feature implements a file-based level editor system that saves the current game world state to a file, allows manual editing of that file, and loads it back into the game. This reuses existing serialization infrastructure for streamlined level creation and testing.

### 1 – Save World State

* **Story:** Developer saves world for testing.
* **AC:**

  1. “Save” se
  ializes full game state to JSON.
  2. Include stage size, tiles, items, actors.
  3. Keep hero position, stats, inventory.
  4. Use timestamped filename.
  5. On failure, show error.

### 2 – Edit World File

* **Story:** Creator edits JSON to craft levels.
* **AC:**

  1. JSON is human-readable.
  2. User edits tiles, item spots, counts.
  3. User adjusts hero start, inventory, stats.
  4. User adds or removes actors.
  5. Invalid JSON triggers clear load errors.

### 3 – Load World State

* **Story:** Developer loads custom file to test.
* **AC:**

  1. “Load” opens file picker.
  2. Valid file recreates game state.
  3. Restore layout, hero, items, actors.
  4. Validate format and integrity first.
  5. Corrupt file shows errors, leaves game unchanged.
  6. On success, jump into gameplay.

### 4 – Gameplay Parity

* **Story:** Custom levels behave like generated ones.
* **AC:**

  1. Loaded levels follow all mechanics.
  2. Validate referenced items, tiles, actors exist.
  3. Built-in save/load works the same.
  4. Switching levels keeps performance steady.
  5. Missing assets default, log warning.

### 5 – UI Access

* **Story:** Developer uses menu to save/load.
* **AC:**

  1. Debug mode shows “Save” and “Load” options.
  2. After save, display path and filename.
  3. Load shows browser or input.
  4. Show success or error after operation.
  5. Show progress indicator during IO.
