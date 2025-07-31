# Design Document

The file-based level editor system extends the existing Hauberk architecture to enable saving complete game world states to JSON files, manual editing of those files, and loading them back into the game. This system leverages the existing Storage class's JSON serialization infrastructure and integrates seamlessly with the current Game, Stage, and Hero systems.

## Architecture

* **Existing:** Game, Stage, HeroSave, Storage.
* **New:**

  * **WorldStateManager** – saveWorldState(), loadWorldState(), validateWorldState().
  * **LevelEditorUI** – showSaveDialog(), showLoadDialog(), saveToFile(), loadFromFile().
  * **WorldStateValidator** – validate() → ValidationResult.

## Data

* **JSON root:** version, timestamp, depth, stage, hero.
* **Stage:** width, height, tiles, items, actors.
* **Tile:** type, substance, visible, explored, emanation.
* **Actor:** hero | monster map.

## Validation

1. Check schema.
2. Verify content IDs.
3. Catch logical errors.
4. Swap defaults, log warnings.

## Testing

* Unit: round-trip, validation.
* Integration: loaded vs generated parity.

## Browser IO

* Save: URL.createObjectURL.
* Load: FileReader.
* Fallback: copy/paste JSON.

## Integration Points

* Game constructor accepts Stage data.
* Storage gains world-state methods.
* UI adds “Save/Load World”.
* Content system backs validation.

## Performance

* Serialize explored tiles only.
* Optional JSON minify.
* Cache validation lookups.
* Dispose old state on load.
