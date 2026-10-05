import 'package:speech_to_text/speech_to_text.dart';

class SpeechInput {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  Future<void> listen(void Function(String text) onText) async {
    await _speech.listen(
      onResult: (result) {
        onText(result.recognizedWords);
      },
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
