import 'dart:async';
import 'dart:io';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';

/// Wraps the llama.cpp inference engine.
///
/// Phase 2 placeholder: the actual llama.cpp FFI bridge will replace the
/// stub below once the llama_cpp_dart package is integrated. The public API
/// is stable so the rest of the app does not need to change when the real
/// engine is wired in.
///
/// Current behaviour:
///   - [isAvailable] returns false when the GGUF file is not present.
///   - [generate] calls the existing [AnywaaAiService] RAG pipeline and
///     returns a deterministic grounded reply, exactly as today.
///   - When [modelPath] is set and the GGUF exists, a TODO comment marks
///     the swap-in point for real inference.
class LlamaService {
  LlamaService._();
  static final LlamaService instance = LlamaService._();

  String? _modelPath;
  bool get isAvailable => _modelPath != null && File(_modelPath!).existsSync();

  /// Call after a successful model download.
  void setModelPath(String path) {
    _modelPath = path;
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
  /// When the real llama.cpp engine is available ([isAvailable] == true),
  /// this will call native inference. Until then it returns the grounded
  /// deterministic reply from [AnywaaAiService] — identical accuracy,
  /// slightly less conversational phrasing.
  Future<String> generate({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async {
    final _ = buildContext(dictionaryResult); // context for future LLM use

    // ── TODO: swap in real llama.cpp inference here ──────────────────────
    // When isAvailable is true:
    //   final prompt = buildPrompt(userQuery: userQuery, context: context);
    //   final raw = await _nativeGenerate(prompt);  // llama_cpp_dart call
    //   return applyGuardrail(
    //       llmOutput: raw, context: context, fallback: dictionaryResult.text);
    // ────────────────────────────────────────────────────────────────────

    // Fallback: return the grounded dictionary reply unchanged.
    return dictionaryResult.text;
  }
}
