// lib/src/engine/sfx_id.dart
/// Sound effect identifier constants.
///
/// These constants correspond to audio files in the assets/audio/sfx directory.
/// Files should be named using snake_case with optional variation numbers.
/// Example: player_arrow_release_01.ogg, player_arrow_release_02.ogg
class SfxId {
  // Player actions
  static const String playerArrowRelease = 'player_arrow_release';
  static const String playerArrowImpactWood = 'player_arrow_impact_wood';
  static const String playerMagicCast = 'player_magic_cast';
  static const String playerMagicHit = 'player_magic_hit';
  static const String playerHurt = 'player_hurt';

  // Enemy actions
  static const String enemyDeath = 'enemy_death';

  // UI sounds
  static const String uiConfirm = 'ui_confirm';
  static const String uiCancel = 'ui_cancel';

  // Loot and items
  static const String lootPickup = 'loot_pickup';

  // Loops (continuous sounds)
  static const String mageChargeLoop = 'mage_charge_loop';

  // Stingers (impact sounds)
  static const String levelUp = 'level_up';
  static const String pauseToggle = 'pause_toggle';
}
