// lib/src/ui/loop_input_wrapper.dart

import 'package:malison/malison.dart';
import 'input.dart';
import 'loop_input.dart';
import 'input_converter.dart';
import 'loop_game_screen.dart';

/// Wrapper that allows LoopGameScreen to receive standard Input
/// but process it as simplified LoopInput
class LoopInputWrapper extends Screen<Input> {
  final LoopGameScreen _loopScreen;
  
  LoopInputWrapper(this._loopScreen);
  
  @override
  bool handleInput(Input input) {
    // Convert standard input to loop input
    var loopInput = InputConverter.convertToLoopInput(input);
    
    if (loopInput != null) {
      return _loopScreen.handleInput(loopInput);
    }
    
    // If we can't convert it, ignore it (this simplifies the control scheme)
    return true;
  }
  
  @override
  void activate(Screen popped, Object? result) {
    _loopScreen.activate(popped, result);
  }
  
  @override
  void update() {
    _loopScreen.update();
  }
  
  @override
  void resize(Vec size) {
    _loopScreen.resize(size);
  }
  
  @override
  void render(Terminal terminal) {
    _loopScreen.render(terminal);
  }
  
  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    return _loopScreen.keyDown(keyCode, shift: shift, alt: alt);
  }
  
  @override
  bool keyUp(int keyCode, {required bool shift, required bool alt}) {
    return _loopScreen.keyUp(keyCode, shift: shift, alt: alt);
  }
  
  // Delegate all property access to the wrapped screen
  dynamic noSuchMethod(Invocation invocation) {
    return reflect(_loopScreen).delegate(invocation);
  }
}
