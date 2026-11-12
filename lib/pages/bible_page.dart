import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

/// Wël Jwøk - Bible reader in Dha Anywaa
/// Loads Bible content from assets/holybooks/ANY/OT and NT
class BiblePage extends StatefulWidget {
  const BiblePage({super.key});

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  bool _isLoading = true;
  List<BibleBook> _otBooks = [];
  List<BibleBook> _ntBooks = [];
  BibleBook? _selectedBook;
  int _selectedChapter = 0;
  BibleChapter? _chapterData;
  bool _loadingChapter = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _audioAvailable = false;

  // Reading position tracking
  String? _lastBookCode;
  int? _lastChapter;

  @override
  void initState() {
    super.initState();
    _loadBooks();
    _loadLastPosition();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final lastBook = prefs.getString('bible_last_book');
    final lastChapter = prefs.getInt('bible_last_chapter');
    if (lastBook != null && lastChapter != null) {
      setState(() {
        _lastBookCode = lastBook;
        _lastChapter = lastChapter;
      });
    }
  }

  Future<void> _saveLastPosition(String bookCode, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bible_last_book', bookCode);
    await prefs.setInt('bible_last_chapter', chapter);
  }

  Future<void> _loadBooks() async {
    // Load OT books
    final otCodes = ['GEN', 'EXO', 'LEV', 'NUM', 'DEU', 'JOS', 'JDG', 'RUT',
        '1SA', '2SA', '1KI', '2KI', '1CH', '2CH', 'EZR', 'NEH', 'EST',
        'JOB', 'PSA', 'PRO', 'ECC', 'SNG', 'ISA', 'JER', 'LAM', 'EZK',
        'DAN', 'HOS', 'JOL', 'AMO', 'OBA', 'JON', 'MIC', 'NAH', 'HAB',
        'ZEP', 'HAG', 'ZEC', 'MAL'];

    // Load NT books
    final ntCodes = ['MAT', 'MRK', 'LUK', 'JHN', 'ACT', 'ROM',
        '1CO', '2CO', 'GAL', 'EPH', 'PHP', 'COL',
        '1TH', '2TH', '1TI', '2TI', 'TIT', 'PHM',
        'HEB', 'JAS', '1PE', '2PE', '1JN', '2JN', '3JN', 'JUD', 'REV'];

    for (final code in otCodes) {
      try {
        final json = await _loadBookJson(code, isOT: true);
        if (json != null) {
          _otBooks.add(BibleBook(
            code: code,
            name: json['chapterName'] ?? code,
            chapterCount: (json['text'] as List).length,
            isOT: true,
          ));
        }
      } catch (_) {}
    }

    for (final code in ntCodes) {
      try {
        final json = await _loadBookJson(code, isOT: false);
        if (json != null) {
          _ntBooks.add(BibleBook(
            code: code,
            name: json['chapterName'] ?? code,
            chapterCount: (json['text'] as List).length,
            isOT: false,
          ));
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _loadBookJson(String code, {required bool isOT}) async {
    final path = 'assets/holybooks/ANY/${isOT ? 'OT' : 'NT'}/$code.json';
    final bytes = await DefaultAssetBundle.of(context).loadString(path);
    return jsonDecode(bytes) as Map<String, dynamic>;
  }

  Future<void> _openChapter(BibleBook book, int chapterIndex) async {
    setState(() {
      _selectedBook = book;
      _selectedChapter = chapterIndex;
      _loadingChapter = true;
      _chapterData = null;
      _audioAvailable = false;
    });

    try {
      final json = await _loadBookJson(book.code, isOT: book.isOT);
      if (json != null) {
        final chapters = json['text'] as List;
        if (chapterIndex < chapters.length) {
          final chapter = chapters[chapterIndex] as Map<String, dynamic>;
          final verses = (chapter['text'] as List).map((v) {
            final verseMap = v as Map<String, dynamic>;
            return BibleVerse(
              number: int.tryParse(verseMap['ID']?.toString() ?? '0') ?? 0,
              text: verseMap['text']?.toString() ?? '',
              sectionTitle: verseMap['title']?.toString(),
            );
          }).toList();
          
          final audioLink = chapter['audioLink']?.toString();
          
          setState(() {
            _chapterData = BibleChapter(
              name: chapter['name']?.toString() ?? '${book.name} ${chapterIndex + 1}',
              verses: verses,
              audioLink: audioLink,
            );
            _audioAvailable = audioLink != null && audioLink.isNotEmpty;
            _loadingChapter = false;
          });
          
          await _saveLastPosition(book.code, chapterIndex);
          
          // Log analytics
          await FirebaseAnalytics.instance.logEvent(
            name: 'bible_chapter_opened',
            parameters: {
              'book': book.code,
              'book_name': book.name,
              'chapter': chapterIndex + 1,
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingChapter = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load chapter: $e')),
        );
      }
    }
  }

  Future<void> _toggleAudio() async {
    if (_chapterData?.audioLink == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        await _audioPlayer.play(UrlSource(_chapterData!.audioLink!));
        await FirebaseAnalytics.instance.logEvent(
          name: 'bible_audio_played',
          parameters: {
            'book': _selectedBook?.code ?? '',
            'chapter': _selectedChapter + 1,
          },
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not play audio. Check your connection.')),
          );
        }
      }
    }
  }

  void _goBack() {
    if (_chapterData != null) {
      setState(() {
        _chapterData = null;
        _loadingChapter = false;
      });
      _audioPlayer.pause();
    } else if (_selectedBook != null) {
      setState(() => _selectedBook = null);
    } else {
      Navigator.pop(context);
    }
  }

  void _nextChapter() {
    if (_selectedBook == null) return;
    if (_selectedChapter < _selectedBook!.chapterCount - 1) {
      _openChapter(_selectedBook!, _selectedChapter + 1);
    }
  }

  void _prevChapter() {
    if (_selectedChapter > 0) {
      _openChapter(_selectedBook!, _selectedChapter - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _chapterData == null && _selectedBook == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2D5016),
          foregroundColor: Colors.white,
          title: Text(
            _chapterData != null
                ? _chapterData!.name
                : _selectedBook != null
                    ? _selectedBook!.name
                    : 'Wëël Jwøk',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          actions: [
            if (_chapterData != null && _audioAvailable) ...[
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle),
                onPressed: _toggleAudio,
                tooltip: _isPlaying ? 'Pause audio' : 'Play audio',
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _chapterData != null ? _buildBottomBar() : null,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2D5016)),
      );
    }

    // Show chapter reading view
    if (_chapterData != null) {
      return _buildChapterView();
    }

    // Show chapter selection for a book
    if (_selectedBook != null) {
      return _buildChapterGrid();
    }

    // Show book selection
    return _buildBookSelection();
  }

  Widget _buildBookSelection() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Last reading position banner
          if (_lastBookCode != null && _lastChapter != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFE8F5E9),
              child: GestureDetector(
                onTap: () {
                  // Find the book and open it
                  final allBooks = [..._otBooks, ..._ntBooks];
                  final book = allBooks.firstWhere(
                    (b) => b.code == _lastBookCode,
                  );
                  _openChapter(book, _lastChapter!);
                },
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded, color: Color(0xFF2D5016), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Continue reading: ${_lastBookCode} ${_lastChapter! + 1}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF2D5016)),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF2D5016)),
                  ],
                ),
              ),
            ),
          TabBar(
            labelColor: const Color(0xFF2D5016),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2D5016),
            tabs: const [
              Tab(text: 'Old Testament'),
              Tab(text: 'New Testament'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBookGrid(_otBooks),
                _buildBookGrid(_ntBooks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookGrid(List<BibleBook> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () {
            setState(() => _selectedBook = book);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F0E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF2D5016), size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${book.chapterCount} chapters',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterGrid() {
    final book = _selectedBook!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF5F0E8),
          child: Text(
            book.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D5016),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: book.chapterCount,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openChapter(book, index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChapterView() {
    if (_loadingChapter) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)));
    }

    final chapter = _chapterData!;
    final verses = chapter.verses;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      itemCount: verses.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Chapter header
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chapter.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5016),
                  ),
                ),
                if (_audioAvailable) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _toggleAudio,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                            color: const Color(0xFF2D5016),
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPlaying ? 'Pause audio' : 'Listen to this chapter',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2D5016),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Divider(height: 32),
              ],
            ),
          );
        }

        final verse = verses[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (verse.sectionTitle != null && verse.sectionTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  verse.sectionTitle!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.7,
                    color: Color(0xFF1A1A1A),
                  ),
                  children: [
                    TextSpan(
                      text: '${verse.number} ',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5016),
                      ),
                    ),
                    TextSpan(text: verse.text),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _selectedChapter > 0 ? _prevChapter : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Previous'),
            ),
            Text(
              '${_selectedChapter + 1} / ${_selectedBook?.chapterCount ?? 0}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: _selectedBook != null &&
                      _selectedChapter < _selectedBook!.chapterCount - 1
                  ? _nextChapter
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Models ─────────────────────────────────────────────────────────────────

class BibleBook {
  final String code;
  final String name;
  final int chapterCount;
  final bool isOT;

  const BibleBook({
    required this.code,
    required this.name,
    required this.chapterCount,
    required this.isOT,
  });
}

class BibleChapter {
  final String name;
  final List<BibleVerse> verses;
  final String? audioLink;

  const BibleChapter({
    required this.name,
    required this.verses,
    this.audioLink,
  });
}

class BibleVerse {
  final int number;
  final String text;
  final String? sectionTitle;

  const BibleVerse({
    required this.number,
    required this.text,
    this.sectionTitle,
  });
}
