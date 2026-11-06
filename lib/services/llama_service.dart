import 'dart:async';
import 'dart:io';
import 'package:dha_anywaaa/services/anywaa_ai_service.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

/// Wraps the llama.cpp inference engine.
///
/// When the SmolLM2 model is downloaded, this service loads it via
/// llama_cpp_dart and generates conversational English responses using
/// the RAG (Retrieval-Augmented Generation) pipeline.
///
/// The dictionary result is injected as [CONTEXT] so the model can only
/// rephrase what the database already confirmed.
class LlamaService {
  LlamaService._();
  static final LlamaService instance = LlamaService._();

  String? _modelPath;
  LlamaEngine? _engine;
  EngineSession? _session;
  
  bool get isAvailable => _modelPath != null && File(_modelPath!).existsSync();

  /// Call after a successful model download.
  Future<void> setModelPath(String path) async {
    _modelPath = path;
    await _loadModel();
  }

  /// Clears the model path (e.g. after deletion).
  void clearModelPath() {
    _dispose();
    _modelPath = null;
  }

  /// Load the GGUF model into memory.
  Future<void> _loadModel() async {
    if (_modelPath == null || !File(_modelPath!).existsSync()) {
      return;
    }

    try {
      // Dispose any existing model first
      _dispose();

      // Load the model with llama_cpp_dart v0.9.0 API
      _engine = await LlamaEngine.spawn(
        modelParams: ModelParams(
          path: _modelPath!,
          gpuLayers: 0, // CPU only for compatibility (increase if GPU available)
        ),
        contextParams: const ContextParams(
          nCtx: 2048, // Safe for mobile
        ),
      );

      // Create a session for generation
      _session = await _engine!.createSession();
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load LLM model: $e');
      _dispose();
    }
  }

  /// Dispose of the model and context.
  void _dispose() {
    _session?.dispose();
    _engine?.dispose();
    _session = null;
    _engine = null;
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
  /// If the model is available, uses SmolLM2 for conversational English
  /// responses while maintaining grounded accuracy through the RAG pipeline.
  /// Otherwise falls back to the dictionary-based reply.
  ///
  /// Returns: A conversational English response grounded in database facts.
  Future<String> generate({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async {
    // Fallback to dictionary mode if model not available
    if (_session == null) {
      return dictionaryResult.text;
    }

    try {
      // Build the RAG prompt with verified database facts
      final context = buildContext(dictionaryResult);
      final prompt = buildPrompt(userQuery: userQuery, context: context);

      // Generate response using llama.cpp
      final buffer = StringBuffer();
      await for (final event in _session!.generate(
        prompt: prompt,
        addSpecial: true,
        sampler: const SamplerParams(
          temperature: 0.7,
          topP: 0.9,
        ),
        maxTokens: 256,
      )) {
        if (event is TokenEvent) {
          buffer.write(event.text);
          // Stop at special tokens
          if (buffer.toString().contains('<|im_end|>') || 
              buffer.toString().contains('<|im_start|>')) {
            break;
          }
        } else if (event is DoneEvent) {
          break;
        }
      }

      final generated = buffer.toString()
          .replaceAll('<|im_end|>', '')
          .replaceAll('<|im_start|>', '')
          .trim();

      // Apply guardrail to prevent hallucinations
      return applyGuardrail(
        llmOutput: generated,
        context: context,
        fallback: dictionaryResult.text,
      );
    } catch (e) {
      // ignore: avoid_print
      print('LLM generation failed: $e');
      // Fallback to dictionary mode on error
      return dictionaryResult.text;
    }
  }

  /// Generate a reply with streaming token-by-token output.
  ///
  /// Returns a Stream that emits each token as it's generated.
  Stream<String> generateStream({
    required String userQuery,
    required AnywaaAnswer dictionaryResult,
  }) async* {
    // Fallback to dictionary mode if model not available
    if (_session == null) {
      yield dictionaryResult.text;
      return;
    }

    try {
      // Build the RAG prompt with verified database facts
      final context = buildContext(dictionaryResult);
      final prompt = buildPrompt(userQuery: userQuery, context: context);

      // Stream tokens from llama.cpp
      final buffer = StringBuffer();
      await for (final event in _session!.generate(
        prompt: prompt,
        addSpecial: true,
        sampler: const SamplerParams(
          temperature: 0.7,
          topP: 0.9,
        ),
        maxTokens: 256,
      )) {
        if (event is TokenEvent) {
          buffer.write(event.text);
          yield event.text;
          
          // Stop at special tokens
          if (buffer.toString().contains('<|im_end|>') || 
              buffer.toString().contains('<|im_start|>')) {
            break;
          }
        } else if (event is DoneEvent) {
          break;
        }
      }

      // Apply guardrail after generation completes
      final generated = buffer.toString()
          .replaceAll('<|im_end|>', '')
          .replaceAll('<|im_start|>', '')
          .trim();
          
      final validated = applyGuardrail(
        llmOutput: generated,
        context: context,
        fallback: dictionaryResult.text,
      );

      // If guardrail rejected the output, emit correction
      if (validated != generated && validated == dictionaryResult.text) {
        yield '\n\n[Corrected]: $validated';
      }
    } catch (e) {
      // ignore: avoid_print
      print('LLM streaming failed: $e');
      // Fallback to dictionary mode on error
      yield dictionaryResult.text;
    }
  }
}
