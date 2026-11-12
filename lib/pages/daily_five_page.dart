import 'package:flutter/material.dart';
import '../services/learning_engine.dart';
import '../services/gamification_service.dart';

/// Daily 5: the core learning session.
/// 5 quick questions mixing due, weak and new words.
/// Immediate feedback, XP rewards, combo tracking.
class DailyFivePage extends StatefulWidget {
  final List<WordData> allWords; // Your full vocabulary

  const DailyFivePage({Key? key, required this.allWords}) : super(key: key);

  @override
  State<DailyFivePage> createState() => _DailyFivePageState();
}

class _DailyFivePageState extends State<DailyFivePage> {
  final _learning = LearningEngine.instance;
  final _gamification = GamificationService.instance;

  List<WordData> _sessionWords = [];
  int _currentIndex = 0;
  int _combo = 0;
  int _totalXp = 0;
  bool _loading = true;
  bool _answered = false;
  bool? _lastAnswerCorrect;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _buildSession();
  }

  Future<void> _buildSession() async {
    final allIds = widget.allWords.map((w) => w.id).toList();
    final sessionIds = await _learning.buildDailyFive(allIds);
    final words = sessionIds
        .map((id) => widget.allWords.firstWhere((w) => w.id == id))
        .toList();

    setState(() {
      _sessionWords = words;
      _loading = false;
    });
  }

  void _onAnswer(bool correct) async {
    if (_answered) return;

    final responseTime = DateTime.now().difference(_startTime).inMilliseconds;
    final word = _sessionWords[_currentIndex];

    // Record in learning engine
    await _learning.recordReview(
      wordId: word.id,
      correct: correct,
      responseTimeMs: responseTime,
      questionType: 'picture_to_word',
    );

    // Award XP
    int xp = correct ? GamificationService.xpCorrectAnswer : 1; // 1 XP for trying
    if (correct) {
      _combo++;
      if (_combo >= 3) {
        xp += GamificationService.xpCombo;
      }
    } else {
      _combo = 0;
    }

    final gam = await _gamification.onLessonComplete();

    setState(() {
      _answered = true;
      _lastAnswerCorrect = correct;
      _totalXp += xp + gam.streakBonus;
    });

    // Auto-advance after 1.5 seconds
    await Future.delayed(const Duration(milliseconds: 1500));
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_currentIndex < _sessionWords.length - 1) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _lastAnswerCorrect = null;
      });
    } else {
      _finishSession();
    }
  }

  void _finishSession() async {
    await _learning.markDailyCompleted();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryPage(
          wordsReviewed: _sessionWords.length,
          xpEarned: _totalXp,
          maxCombo: _combo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sessionWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Daily 5')),
        body: const Center(
          child: Text('No words available. Add content first!'),
        ),
      );
    }

    final word = _sessionWords[_currentIndex];
    final progress = (_currentIndex + 1) / _sessionWords.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0), // Cream
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5016), // Dark green
        foregroundColor: Colors.white,
        title: Text('Daily 5 (${_currentIndex + 1}/${_sessionWords.length})'),
        actions: [
          if (_combo >= 3)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 20),
                    Text('$_combo', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2D5016)),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Question
                  const Text(
                    'What is this?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 32),

                  // Picture
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        word.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Answer choices (2 options for speed)
                  if (!_answered) ...[
                    _buildChoice(word.anywaaWord, true),
                    const SizedBox(height: 12),
                    _buildChoice(word.wrongChoice, false),
                  ] else ...[
                    // Feedback
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _lastAnswerCorrect == true
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _lastAnswerCorrect == true ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _lastAnswerCorrect == true ? Icons.check_circle : Icons.cancel,
                            color: _lastAnswerCorrect == true ? Colors.green : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lastAnswerCorrect == true ? 'Correct!' : 'Not quite',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _lastAnswerCorrect == true ? Colors.green : Colors.red,
                                  ),
                                ),
                                Text(
                                  word.anywaaWord,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(
                                  word.englishWord,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoice(String text, bool isCorrect) {
    return InkWell(
      onTap: () => _onAnswer(isCorrect),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2D5016), width: 2),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Session summary shown after completing Daily 5
class SessionSummaryPage extends StatelessWidget {
  final int wordsReviewed;
  final int xpEarned;
  final int maxCombo;

  const SessionSummaryPage({
    Key? key,
    required this.wordsReviewed,
    required this.xpEarned,
    required this.maxCombo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, size: 80, color: Color(0xFF2D5016)),
              const SizedBox(height: 24),
              const Text(
                'Great work!',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),

              _buildStat('Words reviewed', '$wordsReviewed'),
              _buildStat('XP earned', '+$xpEarned'),
              if (maxCombo >= 3) _buildStat('Best combo', '$maxCombo'),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Word data model (adapt this to your existing structure)
// ══════════════════════════════════════════════════════════════════════════

class WordData {
  final String id;
  final String anywaaWord;
  final String englishWord;
  final String imagePath;
  final String wrongChoice; // For multiple choice (you can generate this)

  const WordData({
    required this.id,
    required this.anywaaWord,
    required this.englishWord,
    required this.imagePath,
    required this.wrongChoice,
  });
}
