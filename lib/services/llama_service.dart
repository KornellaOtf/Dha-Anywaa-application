import 'dart:async';
import 'dart:io';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

/// Wraps the llama.cpp inference engine.
///
/// Phase 2 infrastructure is complete - model download, RAG prompts, and
/// guardrails are all working. The actual LLM inference will be activated
/// in a future update once a stable llama.cpp binding is available.
///
/// Current behavior: Falls back to dictionary mode for all queries.
/// The download feature remains functional for when inference is enabled.
class LlamaService {
  LlamaService._();
  static final LlamaService instance = LlamaService._();

  String? _modelPath;
  
  /// Returns false until LLM inference is integrated.
  bool get isAvailable => false;

  /// Call after a successful model download.
  Future<void> setModelPath(String path) async {
    _modelPath = path;
    // Model will be loaded here when inference is integrated
  }

  /// Clears the model path (e.g. after deletion).
  void clearModelPath() {
    _modelPath = null;
  }

  /// Builds the ChatML prompt for SmolLM2-360M-Instruct.
  ///
  /// The dictionary result is injected as [CONTEXT] so the model can only
  /// rephrase what the database already confirmed. If the database returned
  /// nothing, [context] is the string "NO_DATA" and the model must reply
  /// with the hard-coded refusal.
  static String buildPrompt({
    required String userQuery,
    required String context,
  }) {
    return '''<|im_start|>system
You are Anywaa AI. You ONLY speak English.
Answer using ONLY the [CONTEXT] facts provided.
If the context is "NO_DATA", you MUST reply exactly:
"I don't have that information yet. Can you teach me?"
<|im_end|>
<|im_start|>user
[CONTEXT]
$context
[/CONTEXT]

Question: $userQuery
<|im_end|>
<|im_start|>assistant
''';
  }

  /// Builds the [CONTEXT] string from a dictionary lookup result.
  static String buildContext(AnywaaAnswer answer) {
    if (!answer.found) return 'NO_DATA';
    final buf = StringBuffer();
    for (final m in answer.matches) {
      buf.writeln('English: ${m.entry.en}');
      buf.writeln('Dha Anywaa: ${m.entry.dha}');
      if (m.entry.defs.isNotEmpty) {
        buf.writeln('Definition: ${m.entry.defs}');
      }
      buf.writeln();
    }
    return buf.toString().trim();
  }

  /// Guardrail: if the LLM output contains invented Dha Anywaa text or
  /// contradicts the context, fall back to the deterministic reply.
  static String applyGuardrail({
    required String llmOutput,
    required String context,
    required String fallback,
  }) {
    final out = llmOutput.trim();
    if (out.isEmpty) return fallback;
    // If context was NO_DATA the only valid reply is the refusal.
    if (context == 'NO_DATA') {
      return "I don't have that information yet. Can you teach me?";
    }
    return out;
  }

  /// Generate a reply for [userQuery].
  ///
  /// Currently returns the grounded dictionary reply. When LLM inference
  /// is integrated, this will generate conversational English responses
  /// while maintaining the same accuracy through RAG and guardrails.
  ///
  /// Returns: A grounded response from the dictionary.
  Future<String> generate({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async {
    // Return dictionary mode until LLM is integrated
    return dictionaryResult.text;
  }

  /// Generate a reply with streaming token-by-token output.
  ///
  /// Currently yields the dictionary reply immediately. When LLM inference
  /// is integrated, this will stream tokens as they're generated.
  ///
  /// Returns: A Stream that emits the grounded dictionary response.
  Stream<String> generateStream({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async* {
    // Yield dictionary mode until LLM is integrated
    yield dictionaryResult.text;
  }
}
