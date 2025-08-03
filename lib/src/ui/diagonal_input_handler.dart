// lib/src/ui/diagonal_input_handler.dart

import 'dart:developer' as developer;
import 'package:piecemeal/piecemeal.dart';

/// Tracks the state of keys for diagonal movement with Shift.
class DiagonalInputHandler {
  bool _isShiftDown = false;
  Vec? _firstDirection;
  
  /// Returns true if the Shift key is currently pressed.
  bool get isShiftDown => _isShiftDown;
  
  /// Updates the Shift key state.
  void updateShift(bool isDown) {
    developer.log('Shift ${isDown ? 'pressed' : 'released'}', name: 'DiagonalInput');
    
    _isShiftDown = isDown;
    
    // Reset first direction when Shift is released
    if (!isDown) {
      developer.log('Shift released - resetting first direction', name: 'DiagonalInput');
      _firstDirection = null;
    }
  }
  
  /// Handles a directional input and returns the resulting direction if a move
  /// should be made, or null otherwise.
  Vec? handleDirection(Vec direction) {
    developer.log('Handling direction: $direction (Shift: $_isShiftDown, First: $_firstDirection)', 
        name: 'DiagonalInput');
        
    if (!_isShiftDown) {
      // Normal movement when Shift isn't held
      return direction;
    }
    
    if (_firstDirection == null) {
      // First direction in the sequence
      developer.log('First direction: $direction', name: 'DiagonalInput');
      _firstDirection = direction;
      return null;
    } else {
      // Second direction - combine with first for diagonal
      var combined = _firstDirection! + direction;
      developer.log('Second direction: $direction, combined: $combined', name: 'DiagonalInput');
      _firstDirection = null;
      
      // Only return if this is a valid diagonal (both components are non-zero)
      if (combined.x != 0 && combined.y != 0) {
        developer.log('Valid diagonal movement: $combined', name: 'DiagonalInput');
        return combined;
      } else {
        developer.log('Invalid diagonal combination', name: 'DiagonalInput');
      }
      
      // If not a valid diagonal, just use the new direction as first
      _firstDirection = direction;
      return null;
    }
  }
  
  /// Resets the input state, clearing any pending directions.
  void reset() {
    _firstDirection = null;
  }
}
