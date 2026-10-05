import 'package:speech_to_text/speech_to_text.dart';

class SpeechInput {
  final SpeechToText _speech = SpeechToText();

  void Function()? _onFinished;
  bool _finished = false;

  Future<bool> initialize() async {
    return await _speech.initialize(
      onStatus: (status) {
        print("Speech status: $status");

        if (!_finished && (status == "notListening" || status == "done")) {
          _finished = true;

          if (_onFinished != null) {
            _onFinished!();
          }
        }
      },
    );
  }

  Future<void> listen(
    void Function(String text) onText,
    void Function() onFinished,
  ) async {
    _finished = false;
    _onFinished = onFinished;

    await _speech.listen(
      onResult: (result) {
        if (!_finished) {
          onText(result.recognizedWords);
        }
      },
      listenFor: Duration(seconds: 30),
      pauseFor: Duration(seconds: 3),
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
