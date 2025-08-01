import 'package:malison/malison.dart';
import 'package:malison/malison_web.dart';
import 'package:piecemeal/piecemeal.dart';

import '../engine.dart';
import 'storage.dart';
import 'panel/stage_panel.dart';
import 'input.dart';

/// Common interface for all game screens that can be used with game panels.
/// This allows both GameScreen and LoopGameScreen to work with the same panel classes.
abstract class GameScreenInterface {
  Game get game;
  Storage get storage;
  Rect get cameraBounds;
  Color get heroColor;
  StagePanel get stagePanel;
  Actor? get currentTargetActor;
  
  /// Draws a glyph at the specified stage coordinates onto the stage panel.
  void drawStageGlyph(Terminal terminal, int x, int y, Glyph glyph);
  
  /// Get the loop manager if available (for loop mode).
  Object? get loopManager;
  
  /// Get the current game screen for 2UI updates
  Screen<Input>? get screen;
  
  /// Mark the screen as needing to be redrawn
  void dirty();
}
