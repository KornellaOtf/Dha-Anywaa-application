import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/learning_engine.dart';
import '../services/gamification_service.dart';
import '../services/word_aggregator.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

/// Daily 5 — the core FSRS-6 learning session.
///
/// Shows a picture, presents two Anywaa word choices (one correct, one
/// distractor from a different category when possible).  Immediate
/// feedback with XP animation, combo tracking, and a polished summary.
class DailyFivePage extends StatefulWidget {
  final List<WordData> allWords;

  /// Optional pre-built session (Random Words, Mistakes, Saved, Long Session).
  /// When provided, the once-per-day Daily 5 lock is bypassed and the words
  /// are used as-is. Reviews are still recorded in the FSRS engine.
  final List<WordData>? sessionWords;

  /// Display title for custom sessions (e.g. 'Random Words').
  final String? sessionTitle;

  const DailyFivePage({
    Key? key,
    required this.allWords,
    this.sessionWords,
    this.sessionTitle,
  }) : super(key: key);

  @override
  State<DailyFivePage> createState() => _DailyFivePageState();
}

class _DailyFivePageState extends State<DailyFivePage>
    with TickerProviderStateMixin {
  final _learning      = LearningEngine.instance;
  final _gamification  = GamificationService.instance;

  // Session data
  List<WordData>  _sessionWords   = [];
  int             _currentIndex   = 0;
  bool            _loading        = true;
  bool            _alreadyDone    = false; // Daily 5 is once per day

  // Per-question state
  bool   _answered          = false;
  bool?  _lastAnswerCorrect;
  int    _questionStartMs   = 0;
  String? _wrongChoice;

  // Session scoring
  int  _combo       = 0;
  int  _maxCombo    = 0;
  int  _totalXp     = 0;
  int  _cardXp      = 0;       // XP earned on this card (shown in feedback)
  final List<bool> _results = [];

  // Animations
  late final AnimationController _progressCtrl;
  late final AnimationController _cardCtrl;
  late final AnimationController _xpCtrl;

  late Animation<double> _progressAnim;
  late Animation<double> _cardScaleAnim;
  late Animation<double> _xpFadeAnim;

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _xpCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _progressAnim = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _cardScaleAnim = Tween<double>(begin: 1, end: 0.97).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeInOut));
    _xpFadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _xpCtrl, curve: Curves.easeOut));

    _buildSession();
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _cardCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  // ── Session setup ─────────────────────────────────────────────────────────

  Future<void> _buildSession() async {
    // Custom practice sessions (Random/Mistakes/Saved/Long) skip the
    // once-per-day lock and use the caller-provided word list.
    if (widget.sessionWords != null) {
      final words = widget.sessionWords!;
      if (mounted) {
        setState(() {
          _sessionWords = words;
          _loading      = false;
        });
        _animateProgress(0, 1 / words.length);
        _resetQuestionTimer();
      }
      return;
    }

    // Daily 5 can only be played once per day — no replays, no extra XP.
    if (await _learning.isDailyCompleted()) {
      if (mounted) {
        setState(() {
          _loading     = false;
          _alreadyDone = true;
        });
      }
      return;
    }

    final allIds    = widget.allWords.map((w) => w.id).toList();
    final sessionIds = await _learning.buildDailyFive(allIds);

    final words = sessionIds
        .map((id) => widget.allWords.firstWhere(
              (w) => w.id == id,
              orElse: () => widget.allWords.first,
            ))
        .toList();

    if (mounted) {
      setState(() {
        _sessionWords = words;
        _loading      = false;
      });
      _animateProgress(0, 1 / words.length);
      _resetQuestionTimer();
      AnalyticsService.instance.logDaily5Start();
    }
  }

  void _resetQuestionTimer() {
    _questionStartMs = DateTime.now().millisecondsSinceEpoch;
    _wrongChoice = _pickWrongChoice(_sessionWords[_currentIndex]);
  }

  // ── Wrong-choice picker: prefer different category ────────────────────────

  String _pickWrongChoice(WordData word) {
    final pool = widget.allWords.where((w) => w.id != word.id).toList()
      ..shuffle();

    // Prefer a word from a different category to avoid easy category cues
    final diffCat = pool.where((w) => w.category != word.category).toList();
    return diffCat.isNotEmpty ? diffCat.first.anywaa : pool.first.anywaa;
  }

  // ── Answer handling ───────────────────────────────────────────────────────

  void _onAnswer(bool correct) async {
    if (_answered) return;
    HapticFeedback.lightImpact();

    final responseMs = DateTime.now().millisecondsSinceEpoch - _questionStartMs;
    final word = _sessionWords[_currentIndex];

    // Record FSRS review
    await _learning.recordReview(
      wordId:         word.id,
      correct:        correct,
      responseTimeMs: responseMs,
      questionType:   'picture_to_word',
    );

    // Log to analytics
    AnalyticsService.instance.logCardReview(
      correct:    correct,
      category:   word.category,
      responseMs: responseMs,
    );

    // XP preview calculation (shown in UI but not persisted until session end)
    int xp = correct ? GamificationService.xpCorrectAnswer : 1;
    if (correct) {
      _combo++;
      if (_combo > _maxCombo) _maxCombo = _combo;
      if (_combo >= 3) xp += GamificationService.xpCombo;
    } else {
      _combo = 0;
    }

    _cardXp = xp;
    _totalXp += xp;
    _results.add(correct);

    _xpCtrl.forward(from: 0);

    setState(() {
      _answered         = true;
      _lastAnswerCorrect = correct;
    });

    // Auto-advance after showing feedback
    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) _nextQuestion();
  }

  void _nextQuestion() {
    if (_currentIndex < _sessionWords.length - 1) {
      final next = (_currentIndex + 1 + 1) / _sessionWords.length;
      _animateProgress((_currentIndex + 1) / _sessionWords.length, next);

      setState(() {
        _currentIndex++;
        _answered          = false;
        _lastAnswerCorrect = null;
        _cardXp            = 0;
      });
      _resetQuestionTimer();
    } else {
      _finishSession();
    }
  }

  void _finishSession() async {
    // Custom practice sessions don't consume the daily Daily 5 slot.
    final isDailyFive = widget.sessionWords == null;
    if (isDailyFive) await _learning.markDailyCompleted();
    // Single unified award calculation — all XP flows through one method
    final award = await _gamification.completeDailyFive(
      correct: _results.where((r) => r).length,
      total: _results.length,
      comboXp: _combo >= 3 ? GamificationService.xpCombo : 0,
    );

    // Analytics
    final correctCount = _results.where((r) => r).length;
    if (isDailyFive) {
      AnalyticsService.instance.logDaily5Complete(
        correct: correctCount,
        total:   _results.length,
        xp:      award.awardedXp,
      );
      // Log level-up if it happened
      if (award.leveledUp) {
        AnalyticsService.instance.logLevelUp(
          award.level,
          'Level ${award.level}',
        );
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionSummaryPage(
          wordsReviewed: _sessionWords.length,
          xpEarned:      award.awardedXp,
          maxCombo:      _maxCombo,
          results:       List.unmodifiable(_results),
          words:         List.unmodifiable(_sessionWords),
          sessionLabel:  widget.sessionTitle,
        ),
      ),
    );
  }

  void _animateProgress(double from, double to) {
    _progressAnim = Tween<double>(begin: from, end: to.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));
    _progressCtrl.forward(from: 0);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B2E1A),
        body: const Center(
          child: CircularProgressIndicator(color: kGreen),
        ),
      );
    }

    if (_alreadyDone) return _doneTodayView();

    if (_sessionWords.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF1B2E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(widget.sessionTitle ?? 'Daily 5'),
        ),
        body: const Center(
          child: Text(
            'No words available yet.\nExplore a category first!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    final word     = _sessionWords[_currentIndex];
    final total    = _sessionWords.length;

    return Scaffold(
      backgroundColor: const Color(0xFF1B2E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(total),
            _buildProgressBar(),
            Expanded(child: _buildCard(word)),
            _buildBottomSection(word),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Top bar: close + step dots + combo ───────────────────────────────────

  Widget _buildTopBar(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54),
            onPressed: _confirmExit,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(total, (i) {
                Color color;
                if (i < _results.length) {
                  color = _results[i] ? kGreen : kRust;
                } else if (i == _currentIndex) {
                  color = Colors.white;
                } else {
                  color = Colors.white24;
                }
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width:  i == _currentIndex ? 28 : 20,
                  height: 5,
                  decoration: BoxDecoration(
                    color:        color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
          // Combo badge
          AnimatedOpacity(
            opacity:  _combo >= 3 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color:        Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  Text(
                    '$_combo',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated progress bar ─────────────────────────────────────────────────

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: AnimatedBuilder(
        animation: _progressAnim,
        builder: (_, __) => ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value:           _progressAnim.value,
            minHeight:       6,
            backgroundColor: Colors.white12,
            valueColor:      const AlwaysStoppedAnimation<Color>(kGreen),
          ),
        ),
      ),
    );
  }

  // ── Question card: image + prompt ─────────────────────────────────────────

  Widget _buildCard(WordData word) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: ScaleTransition(
        scale: _cardScaleAnim,
        child: Container(
          width:       double.infinity,
          decoration: BoxDecoration(
            color:        Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color:      Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset:     const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              const Text(
                'What is this in Dha Anywaa?',
                style: TextStyle(
                  fontSize:   15,
                  color:      Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Hero(
                tag: word.id,
                child: Container(
                  width:  180,
                  height: 180,
                  decoration: BoxDecoration(
                    color:        Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      word.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported_rounded,
                        size:  64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                word.english,
                style: const TextStyle(
                  fontSize:   22,
                  fontWeight: FontWeight.bold,
                  color:      Color(0xFF1B2E1A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color:        kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  word.category,
                  style: TextStyle(
                    fontSize: 12,
                    color:    kGreen.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom: answer choices OR feedback ───────────────────────────────────

  Widget _buildBottomSection(WordData word) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: _answered ? _buildFeedback(word) : _buildChoices(word),
    );
  }

  Widget _buildChoices(WordData word) {
    // Randomly place correct answer in top or bottom slot
    final rand    = math.Random();
    final correct = word.anywaa;
    final wrong   = _wrongChoice ?? _pickWrongChoice(word);
    final topIsCorrect = rand.nextBool();

    return Column(
      children: [
        _ChoiceButton(
          text:      topIsCorrect ? correct : wrong,
          isCorrect: topIsCorrect,
          onTap:     _onAnswer,
        ),
        const SizedBox(height: 12),
        _ChoiceButton(
          text:      topIsCorrect ? wrong : correct,
          isCorrect: !topIsCorrect,
          onTap:     _onAnswer,
        ),
      ],
    );
  }

  Widget _buildFeedback(WordData word) {
    final correct = _lastAnswerCorrect == true;
    final color   = correct ? kGreen : kRust;
    final icon    = correct ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final message = correct ? 'Correct!' : 'Not quite';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding:  const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize:   18,
                    fontWeight: FontWeight.bold,
                    color:      color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  word.anywaa,
                  style: const TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    color:      Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // XP earned badge
          FadeTransition(
            opacity: _xpFadeAnim,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color:        Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(color: Colors.amber.withOpacity(0.6)),
              ),
              child: Text(
                '+$_cardXp XP',
                style: const TextStyle(
                  color:      Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize:   15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Already-completed view (once per day) ─────────────────────────────────

  Widget _doneTodayView() {
    return Scaffold(
      backgroundColor: const Color(0xFF1B2E1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width:  88,
                  height: 88,
                  decoration: BoxDecoration(
                    color:        kGreen.withOpacity(0.15),
                    shape:        BoxShape.circle,
                    border:       Border.all(color: kGreen, width: 2),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: kGreen, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Daily 5 complete!',
                  style: TextStyle(
                    fontSize:   24,
                    fontWeight: FontWeight.bold,
                    color:      Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'You\'ve already finished today\'s session.\n'
                  'Come back tomorrow for 5 new words!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height:   1.5,
                    color:    Colors.white.withOpacity(0.65),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: const Color(0xFF1B2E1A),
                      padding:         const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Back to learning',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Exit confirmation ─────────────────────────────────────────────────────

  void _confirmExit() {
    final c = context.c;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [kShadowCard],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGold.withValues(alpha: 0.12),
                  ),
                  child: const Icon(Icons.pause_circle_rounded,
                      color: kGold, size: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text('Leave this session?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: c.text)),
              const SizedBox(height: 8),
              Text(
                'Your progress in this Daily 5 won\'t be saved.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5, color: c.textSub),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: c.text,
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Keep going',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kRust,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Leave',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Answer choice button
// ─────────────────────────────────────────────────────────────────────────────

class _ChoiceButton extends StatelessWidget {
  final String text;
  final bool   isCorrect;
  final void Function(bool) onTap;

  const _ChoiceButton({
    required this.text,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color:        Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:        () => onTap(isCorrect),
        child: Container(
          width:   double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border:       Border.all(color: Colors.white24, width: 1.5),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.w600,
              color:      Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Session Summary
// ─────────────────────────────────────────────────────────────────────────────

class SessionSummaryPage extends StatelessWidget {
  final int              wordsReviewed;
  final int              xpEarned;
  final int              maxCombo;
  final List<bool>       results;
  final List<WordData>   words;
  final String?          sessionLabel;

  const SessionSummaryPage({
    Key? key,
    required this.wordsReviewed,
    required this.xpEarned,
    required this.maxCombo,
    required this.results,
    required this.words,
    this.sessionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final correctCount = results.where((r) => r).length;
    final pct          = wordsReviewed > 0
        ? (correctCount / wordsReviewed * 100).round()
        : 0;
    final isPerfect    = correctCount == wordsReviewed;

    return Scaffold(
      backgroundColor: const Color(0xFF1B2E1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ── Session label (custom practice modes) ────────────────────
              if (sessionLabel != null) ...[
                Text(
                  sessionLabel!.toUpperCase(),
                  style: const TextStyle(
                    fontSize:   12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color:      kGold,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ── Headline ─────────────────────────────────────────────────
              Text(
                isPerfect ? '🌟 Perfect session!' : '✨ Great work!',
                style: const TextStyle(
                  fontSize:   30,
                  fontWeight: FontWeight.bold,
                  color:      Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isPerfect
                    ? 'Every word correct. You\'re building real mastery.'
                    : 'Every session makes you stronger. Keep going!',
                style: const TextStyle(fontSize: 15, color: Colors.white60),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // ── Stats row ─────────────────────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    label: 'Accuracy',
                    value: '$pct%',
                    icon:  Icons.track_changes_rounded,
                    color: kGreen,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'XP Earned',
                    value: '+$xpEarned',
                    icon:  Icons.star_rounded,
                    color: Colors.amber,
                  ),
                  if (maxCombo >= 3) ...[
                    const SizedBox(width: 12),
                    _StatCard(
                      label: 'Best Combo',
                      value: '$maxCombo',
                      icon:  Icons.bolt_rounded,
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 28),

              // ── Per-word result list ──────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  itemCount: words.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final ok = i < results.length ? results[i] : false;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color:        Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              words[i].imageUrl,
                              width:  44,
                              height: 44,
                              fit:    BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width:  44,
                                height: 44,
                                color:  Colors.white12,
                                child:  const Icon(
                                  Icons.image,
                                  color: Colors.white38,
                                  size:  24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  words[i].anywaa,
                                  style: const TextStyle(
                                    color:      Colors.white,
                                    fontSize:   16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  words[i].english,
                                  style: const TextStyle(
                                    color:   Colors.white54,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            ok
                                ? Icons.check_circle_rounded
                                : Icons.replay_rounded,
                            color: ok ? kGreen : kRust,
                            size:  26,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Continue button ───────────────────────────────────────────
              SizedBox(
                width:  double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small stat card used in summary
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize:   22,
                fontWeight: FontWeight.bold,
                color:      color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
