import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../theme/app_theme.dart';

class BibleVerse {
  final String book;
  final int chapter;
  final int verse;
  final String anywaa;
  final String english;

  BibleVerse({
    required this.book,
    required this.chapter,
    required this.verse,
    required this.anywaa,
    required this.english,
  });

  factory BibleVerse.fromJson(Map<String, dynamic> json) {
    return BibleVerse(
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      anywaa: json['anywaa'] as String,
      english: json['english'] as String,
    );
  }
}

class BiblePage extends StatefulWidget {
  const BiblePage({Key? key}) : super(key: key);

  @override
  State<BiblePage> createState() => _BiblePageState();
}

class _BiblePageState extends State<BiblePage> {
  List<BibleVerse> _allVerses = [];
  bool _isLoading = true;
  String? _selectedBook;
  int? _selectedChapter;
  
  // Book metadata
  final Map<String, int> _bookChapterCounts = {};
  final List<String> _otBooks = [];
  final List<String> _ntBooks = [];
  
  // Audio
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  
  // Last reading position
  String? _lastBook;
  int? _lastChapter;

  @override
  void initState() {
    super.initState();
    _loadBible();
    _loadLastPosition();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadBible() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/bible.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      setState(() {
        _allVerses = jsonData.map((v) => BibleVerse.fromJson(v)).toList();
        _buildBookMetadata();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading Bible: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildBookMetadata() {
    // Build chapter counts and categorize OT/NT
    final bookSet = <String>{};
    for (var verse in _allVerses) {
      bookSet.add(verse.book);
      _bookChapterCounts[verse.book] = 
          (_bookChapterCounts[verse.book] ?? 0) < verse.chapter 
              ? verse.chapter 
              : _bookChapterCounts[verse.book]!;
    }
    
    // Split into OT/NT (first 39 books are OT)
    final books = bookSet.toList();
    _otBooks.addAll(books.take(39));
    _ntBooks.addAll(books.skip(39));
  }

  Future<void> _loadLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBook = prefs.getString('bible_last_book');
      _lastChapter = prefs.getInt('bible_last_chapter');
    });
  }

  Future<void> _saveLastPosition(String book, int chapter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bible_last_book', book);
    await prefs.setInt('bible_last_chapter', chapter);
    setState(() {
      _lastBook = book;
      _lastChapter = chapter;
    });
    
    // Analytics
    FirebaseAnalytics.instance.logEvent(
      name: 'bible_chapter_opened',
      parameters: {'book': book, 'chapter': chapter},
    );
  }

  List<BibleVerse> _getChapterVerses(String book, int chapter) {
    return _allVerses
        .where((v) => v.book == book && v.chapter == chapter)
        .toList();
  }

  void _playAudio(String book, int chapter) async {
    // Audio URL format from Firebase
    final bookAbbrev = book.replaceAll(' ', '_').toLowerCase();
    final audioUrl = 
        'https://firebasestorage.googleapis.com/v0/b/learn-dha-anywaa.appspot.com/o/bible_audio%2F$bookAbbrev%2Fchapter_$chapter.mp3?alt=media';
    
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      try {
        await _audioPlayer.play(UrlSource(audioUrl));
        setState(() => _isPlaying = true);
        
        FirebaseAnalytics.instance.logEvent(
          name: 'bible_audio_played',
          parameters: {'book': book, 'chapter': chapter},
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio not available for this chapter')),
        );
      }
    }
    
    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() => _isPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Wëël Jwøk')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedBook != null && _selectedChapter != null) {
      return _buildReadingView();
    }

    if (_selectedBook != null) {
      return _buildChapterSelection();
    }

    return _buildBookSelection();
  }

  Widget _buildBookSelection() {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wëël Jwøk'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Old Testament (39)'),
              Tab(text: 'New Testament (27)'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Continue Reading Banner
            if (_lastBook != null && _lastChapter != null)
              Container(
                color: kGreen.withOpacity(0.1),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark, color: kGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Continue Reading',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$_lastBook Chapter $_lastChapter',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedBook = _lastBook;
                          _selectedChapter = _lastChapter;
                        });
                      },
                      child: const Text('OPEN'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBookList(_otBooks),
                  _buildBookList(_ntBooks),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookList(List<String> books) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final chapterCount = _bookChapterCounts[book] ?? 0;
        
        return Card(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedBook = book;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    book,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$chapterCount chapters',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterSelection() {
    final chapterCount = _bookChapterCounts[_selectedBook] ?? 0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBook!),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedBook = null;
            });
          },
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: chapterCount,
        itemBuilder: (context, index) {
          final chapter = index + 1;
          
          return Card(
            color: kGreen,
            child: InkWell(
              onTap: () {
                _saveLastPosition(_selectedBook!, chapter);
                setState(() {
                  _selectedChapter = chapter;
                });
              },
              child: Center(
                child: Text(
                  '$chapter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadingView() {
    final verses = _getChapterVerses(_selectedBook!, _selectedChapter!);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$_selectedBook $_selectedChapter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedChapter = null;
            });
          },
        ),
      ),
      body: Column(
        children: [
          // Audio Player
          Container(
            padding: const EdgeInsets.all(16),
            color: kGreen.withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  iconSize: 32,
                  color: kGreen,
                  onPressed: () => _playAudio(_selectedBook!, _selectedChapter!),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Listen to this chapter',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
          
          // Verses
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final verse = verses[index];
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.7,
                        color: Colors.black87,
                      ),
                      children: [
                        TextSpan(
                          text: '${verse.verse} ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kGreen,
                            fontSize: 14,
                          ),
                        ),
                        TextSpan(text: verse.anywaa),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Navigation
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                  onPressed: _selectedChapter! > 1
                      ? () {
                          final prev = _selectedChapter! - 1;
                          _saveLastPosition(_selectedBook!, prev);
                          setState(() => _selectedChapter = prev);
                        }
                      : null,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                  onPressed: _selectedChapter! < _bookChapterCounts[_selectedBook!]!
                      ? () {
                          final next = _selectedChapter! + 1;
                          _saveLastPosition(_selectedBook!, next);
                          setState(() => _selectedChapter = next);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
