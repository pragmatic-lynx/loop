// lib/src/engine/loop/loop_meter.dart

import 'dart:math' as math;

import '../core/game.dart';
import '../hero/hero.dart';

/// Tracks loop progress through various activities like enemy kills and loot collection.
/// When the meter reaches 100%, the player gets enhanced rewards at the end of the loop.
class LoopMeter {
  static const double _killFill = 8.0;
  static const double _lootFill = 4.0;
  static const double _sacFillMax = 25.0;
  static const double _fullThreshold = 100.0;
  static const double _halfThreshold = 50.0;
  
  double _progress = 0.0;
  
  /// Current loop meter progress as a percentage (0.0 to 100.0+)
  double get progress => _progress;
  
  /// Current loop meter progress as a ratio (0.0 to 1.0+)
  double get progressRatio => math.min(_progress / 100.0, 1.0);
  
  /// Whether the loop meter is completely full (≥ 100%)
  bool get isFull => _progress >= _fullThreshold;
  
  /// Whether the loop meter is at least half full (≥ 50%)
  bool get isHalfFull => _progress >= _halfThreshold;
  
  /// Whether the loop meter is empty (< 50%)
  bool get isEmpty => _progress < _halfThreshold;
  
  /// Add progress to the loop meter from enemy kill
  /// Returns the new progress percentage
  double addKillProgress() {
    _progress += _killFill;
    return _progress;
  }
  
  /// Add progress to the loop meter from loot pickup
  /// Returns the new progress percentage
  double addLootProgress() {
    _progress += _lootFill;
    return _progress;
  }
  
  /// Add progress to the loop meter from shrine sacrifice
  /// Progress is based on percentage of max HP lost, capped at 25%
  /// Returns the new progress percentage
  double addSacrificeProgress(double hpLost, double maxHp) {
    var percentage = (hpLost / maxHp) * 100.0;
    var cappedPercentage = math.min(percentage, _sacFillMax);
    _progress += cappedPercentage;
    return _progress;
  }
  
  /// Add a specific amount of progress
  /// Returns the new progress percentage
  double addProgress(double amount) {
    _progress += amount;
    return _progress;
  }
  
  /// Get the reward tier based on current progress
  LoopMeterRewardTier getRewardTier() {
    if (progress >= 100.0) return LoopMeterRewardTier.legendary;
    if (progress >= 75.0) return LoopMeterRewardTier.master;
    if (progress >= 50.0) return LoopMeterRewardTier.apprentice;
    if (progress >= 25.0) return LoopMeterRewardTier.novice;
    return LoopMeterRewardTier.survival;
  }
  
  /// Reset the loop meter for a new loop
  void reset() {
    _progress = 0.0;
  }
  
  /// Get current state as a map for debugging/display
  Map<String, dynamic> getState() {
    return {
      'progress': _progress,
      'progressRatio': progressRatio,
      'isFull': isFull,
      'isHalfFull': isHalfFull,
      'isEmpty': isEmpty,
      'rewardTier': getRewardTier().toString(),
    };
  }
}

/// The different reward tiers based on loop meter fill level
enum LoopMeterRewardTier {
  legendary,   // ≥100% - Legendary Case
  master,      // ≥75% - Master Case  
  apprentice,  // ≥50% - Apprentice Case
  novice,      // ≥25% - Novice Case
  survival,    // <25% - Survival Package
}

extension LoopMeterRewardTierExtension on LoopMeterRewardTier {
  String get displayName {
    switch (this) {
      case LoopMeterRewardTier.legendary:
        return "🏆 Legendary Case";
      case LoopMeterRewardTier.master:
        return "⭐ Master Case";
      case LoopMeterRewardTier.apprentice:
        return "🎖️ Apprentice Case";
      case LoopMeterRewardTier.novice:
        return "🥉 Novice Case";
      case LoopMeterRewardTier.survival:
        return "📦 Survival Package";
    }
  }
  
  String get description {
    switch (this) {
      case LoopMeterRewardTier.legendary:
        return "The ring blazes with ultimate power! Choose your destiny.";
      case LoopMeterRewardTier.master:
        return "The ring shines brilliantly! Excellence rewarded.";
      case LoopMeterRewardTier.apprentice:
        return "The ring glows steadily. Good work, adventurer.";
      case LoopMeterRewardTier.novice:
        return "The ring flickers weakly. You survived.";
      case LoopMeterRewardTier.survival:
        return "The ring barely glimmers. Take what you can get.";
    }
  }
  
  double get threshold {
    switch (this) {
      case LoopMeterRewardTier.legendary:
        return 100.0;
      case LoopMeterRewardTier.master:
        return 75.0;
      case LoopMeterRewardTier.apprentice:
        return 50.0;
      case LoopMeterRewardTier.novice:
        return 25.0;
      case LoopMeterRewardTier.survival:
        return 0.0;
    }
  }
  
  /// Get all tiers at or below this one (for "what you could have gotten")
  List<LoopMeterRewardTier> get availableTiers {
    switch (this) {
      case LoopMeterRewardTier.legendary:
        return [LoopMeterRewardTier.legendary, LoopMeterRewardTier.master, LoopMeterRewardTier.apprentice, LoopMeterRewardTier.novice, LoopMeterRewardTier.survival];
      case LoopMeterRewardTier.master:
        return [LoopMeterRewardTier.master, LoopMeterRewardTier.apprentice, LoopMeterRewardTier.novice, LoopMeterRewardTier.survival];
      case LoopMeterRewardTier.apprentice:
        return [LoopMeterRewardTier.apprentice, LoopMeterRewardTier.novice, LoopMeterRewardTier.survival];
      case LoopMeterRewardTier.novice:
        return [LoopMeterRewardTier.novice, LoopMeterRewardTier.survival];
      case LoopMeterRewardTier.survival:
        return [LoopMeterRewardTier.survival];
    }
  }
}
