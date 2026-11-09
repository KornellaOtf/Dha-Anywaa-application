import 'dart:async';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

/// On-device LLM inference wrapper.
///
/// MODEL: Qwen2.5-0.5B-Instruct-Q4_K_M (~469 MB)
/// STATUS: Not yet integrated — requires cmake 3.31+ and NDK 29 to compile
/// llama.cpp native code. The app currently uses the dictionary-based
/// AnywaaAiService for all responses, which is fully functional.
///
/// Qwen2.5 uses ChatML format (<|im_start|> / <|im_end|>) — same as SmolLM2,
/// so the buildPrompt() code below is already correct for when inference lands.
class LlamaService {
  LlamaService._();
  static final LlamaService instance = LlamaService._();

  String? _modelPath;

  /// True once a model is available for local inference.
  bool get isAvailable => _modelPath != null && _modelPath!.isNotEmpty;

  /// Call after a successful model download.
  Future<void> setModelPath(String path) async {
    _modelPath = path;
  }

  /// Clears the model path.
  Future<void> clearModelPath() async {
    _modelPath = null;
  }

  /// Builds a ChatML prompt for SmolLM2-360M-Instruct.
  static String buildPrompt({
    required String userQuery,
    required String context,
  }) {
    if (context == 'NO_DATA') {
      return '<|im_start|>system\n'
          'You are Anywaa AI, a helpful assistant.\n'
          '<|im_end|>\n'
          '<|im_start|>user\n$userQuery\n<|im_end|>\n'
          '<|im_start|>assistant\n';
    }
    return '<|im_start|>system\n'
        'You are Anywaa AI. Answer using ONLY the [CONTEXT] facts.\n'
        '<|im_end|>\n'
        '<|im_start|>user\n[CONTEXT]\n$context\n[/CONTEXT]\n\n$userQuery\n'
        '<|im_end|>\n<|im_start|>assistant\n';
  }

  /// Builds context from a dictionary result.
  static String buildContext(AnywaaAnswer answer) {
    if (!answer.found) return 'NO_DATA';
    final buf = StringBuffer();
    for (final m in answer.matches) {
      buf.writeln('English: ${m.entry.en}');
      buf.writeln('Dha Anywaa: ${m.entry.dha}');
      if (m.entry.defs.isNotEmpty) buf.writeln('Definition: ${m.entry.defs}');
      buf.writeln();
    }
    return buf.toString().trim();
  }

  /// Returns the dictionary reply until LLM inference is integrated.
  Future<String> generate({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async {
    return dictionaryResult.text;
  }

  /// Yields the dictionary reply as a single token.
  Stream<String> generateStream({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async* {
    yield dictionaryResult.text;
  }
}
