import 'package:malison/malison.dart';

import '../engine/audio_manager.dart';
import '../engine/sfx_id.dart';
import 'input.dart';
import 'popup.dart';

/// Modal dialog for letting the user confirm an action.
class ConfirmPopup extends Popup {
  final String _message;
  final Object _result;

  ConfirmPopup(this._message, this._result);

  @override
  List<String> get message => [_message];

  @override
  Map<String, String> get helpKeys => const {"Y": "Yes", "N": "No", "`": "No"};

  @override
  bool handleInput(Input input) {
    if (input == Input.cancel) {
      AudioManager.i.play(SfxId.uiCancel);
      ui.pop();
      return true;
    }

    return false;
  }

  @override
  bool keyDown(int keyCode, {required bool shift, required bool alt}) {
    if (shift || alt) return false;

    switch (keyCode) {
      case KeyCode.n:
        AudioManager.i.play(SfxId.uiCancel);
        ui.pop();

      case KeyCode.y:
        AudioManager.i.play(SfxId.uiConfirm);
        ui.pop(_result);
    }

    return true;
  }
}
