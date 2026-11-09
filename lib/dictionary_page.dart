import 'package:dha_anywaaa/services/anywaa_ai_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  final AnywaaAiService _ai = AnywaaAiService.instance;
  final TextEditingController _controller = TextEditingController();

  bool _loading = true;
  String _query = 'water';
  String _status = 'Loading dictionary...';
  List<AnywaaMatch> _matches = const [];
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _runSearch('water');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _status = 'Type a word in English or Dha Anywaa.';
        _matches = const [];
        _suggestions = const [];
      });
      return;
    }

    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );

    setState(() {
      _loading = true;
      _query = query;
      _status = 'Searching...';
    });

    await _ai.load();
    if (!mounted) return;

    final result = _ai.answer(query);
    setState(() {
      _loading = false;
      _matches = result.matches;
      _suggestions = result.suggestions;
      _status = result.text;
      if (result.matches.isEmpty) {
        _query = query;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Dictionary'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: _runSearch,
                        style: TextStyle(color: c.text, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Search English or Dha Anywaa',
                          hintStyle: TextStyle(color: c.textSub),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _runSearch(_controller.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: c.accent),
                  ),
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'water',
                    'house',
                    'animal',
                    'abandon',
                    'friend',
                  ].map((example) {
                    return ActionChip(
                      label: Text(example,
                          style: TextStyle(color: c.text, fontSize: 12)),
                      backgroundColor: c.card,
                      side: BorderSide(color: c.border),
                      onPressed: () {
                        _controller.text = example;
                        _runSearch(example);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    _status,
                    style: TextStyle(color: c.textSub, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _matches.isEmpty
                      ? Center(
                          child: Text(
                            'No matches yet. Try a word like “water” or “abandon”.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSub),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _matches.length,
                          itemBuilder: (context, index) {
                            final match = _matches[index];
                            final entry = match.entry;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: c.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          entry.en,
                                          style: TextStyle(
                                            color: c.text,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: kGreen.withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          match.source == 'dha'
                                              ? 'Dha Anywaa'
                                              : 'English',
                                          style: const TextStyle(
                                            color: kGreen,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Dha Anywaa: ${entry.dha}',
                                    style: TextStyle(
                                      color: c.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.defs,
                                    style: TextStyle(
                                      color: c.textSub,
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (entry.syn.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: entry.syn
                                          .where((s) => s.trim().isNotEmpty)
                                          .take(6)
                                          .map((s) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: c.bg,
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                  border: Border.all(
                                                      color: c.border),
                                                ),
                                                child: Text(
                                                  s,
                                                  style: TextStyle(
                                                    color: c.textSub,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                ),
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Suggested words',
                      style: TextStyle(
                        color: c.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestions
                        .take(6)
                        .map((word) => GestureDetector(
                              onTap: () {
                                _controller.text = word;
                                _runSearch(word);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: c.card,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: c.border),
                                ),
                                child: Text(
                                  word,
                                  style: TextStyle(
                                    color: c.textSub,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
