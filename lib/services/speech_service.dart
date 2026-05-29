import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isListening = false;
  String _lastRecognizedWords = '';
  void Function()? _onStopped;

  bool get isListening => _isListening;
  String get lastRecognizedWords => _lastRecognizedWords;

  Future<void> initialize() async {
    await _speechToText.initialize();
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function() onListening,
    required void Function() onStopped,
  }) async {
    if (!_speechToText.isAvailable) {
      await _speechToText.initialize();
    }

    if (_speechToText.isListening) {
      await stopListening();
    }

    _isListening = true;
    _onStopped = onStopped;
    onListening();

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        _lastRecognizedWords = result.recognizedWords;
        onResult(_lastRecognizedWords);
      },
      localeId: 'zh_CN',
      listenMode: ListenMode.confirmation,
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
    if (_onStopped != null) {
      _onStopped!();
      _onStopped = null;
    }
  }

  Future<void> cancelListening() async {
    await _speechToText.cancel();
    _isListening = false;
    if (_onStopped != null) {
      _onStopped!();
      _onStopped = null;
    }
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  void dispose() {
    _speechToText.cancel();
    _flutterTts.stop();
  }
}
