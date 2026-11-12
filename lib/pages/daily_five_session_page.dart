import 'package:flutter/material.dart';
import 'package:dha_anywaaa/learning/card_state.dart';
import 'package:dha_anywaaa/learning/fsrs_engine.dart';
import 'package:dha_anywaaa/learning/rating_mapper.dart';
import 'package:dha_anywaaa/learning/review_event.dart';
import 'package:dha_anywaaa/progress/xp_system.dart';

/// Daily 5 Session Page
/// Core learning experience: 5 cards, 2-3 minutes, immediate feedback
class DailyFiveSessionPage extends StatefulWidget {
  final List<CardState> sessionCards;
  final FSRSEngine fsrsEngine;
  final Function(List<ReviewEvent>) onSessionComplete;

  const DailyFiveSessionPage({
    Key? key,
    required this.sessionCards,
    required this.fsrsEngine,
    required this.onSessionComplete,
  }) : super(key: key);

  @override
  State<DailyFiveSessionPage> createState() => _DailyFiveSessionPageState();
}

class _DailyFiveSessionPageState extends State<DailyFiveSessionPage> {
  int currentCardIndex = 0;
  List<ReviewEvent> reviewEvents = [];
  List<bool> cardResults = [];
  bool showingAnswer = false;
  String? userAnswer;
  DateTime? questionStartTime;
  int sessionXP = 0;
  int correctCount = 0;

  @override
  void initState() {
    super.initState();
    questionStartTime = DateTime.now();
  }

  CardState get currentCard => widget.sessionCards[currentCardIndex];
  bool get isLastCard => currentCardIndex == widget.sessionCards.length - 1;
  bool get sessionComplete => currentCardIndex >= widget.sessionCards.length;

  void _submitAnswer(bool correct) {
    if (showingAnswer) return;

    final responseTime = DateTime.now().difference(questionStartTime!).inMilliseconds;
    final rating = RatingMapper.mapBinaryAnswer(correct: correct);

    // Calculate FSRS update
    final reviewResult = widget.fsrsEngine.review(
      card: currentCard,
      rating: rating,
    );

    // Record review event
    final event = ReviewEvent(
      wordId: currentCard.wordId,
      timestamp: DateTime.now(),
      rating: rating,
      responseTimeMs: responseTime,
      stabilityBefore: currentCard.stability,
      stabilityAfter: reviewResult.card.stability,
      difficultyBefore: currentCard.difficulty,
      difficultyAfter: reviewResult.card.difficulty,
      scheduledInterval: reviewResult.card.dueDate.difference(DateTime.now()).inDays,
      sessionId: DateTime.now().toIso8601String(),
    );

    reviewEvents.add(event);
    cardResults.add(correct);

    // Calculate XP
    final cardXP = XPSystem.calculateReviewXP(
      rating: rating,
      isFirstReview: currentCard.reps == 0,
    );
    sessionXP += cardXP;

    if (correct) correctCount++;

    setState(() {
      showingAnswer = true;
    });

    // Auto-advance after 1.5 seconds
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _nextCard();
    });
  }

  void _nextCard() {
    if (isLastCard) {
      // Session complete
      final completionXP = XPSystem.calculateSessionXP(
        correctCount: correctCount,
        totalCount: widget.sessionCards.length,
      );
      sessionXP += completionXP;

      widget.onSessionComplete(reviewEvents);
      _showSessionSummary();
    } else {
      setState(() {
        currentCardIndex++;
        showingAnswer = false;
        userAnswer = null;
        questionStartTime = DateTime.now();
      });
    }
  }

  void _showSessionSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SessionSummaryDialog(
        correctCount: correctCount,
        totalCount: widget.sessionCards.length,
        xpEarned: sessionXP,
        cardResults: cardResults,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sessionComplete) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _confirmExit(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.sessionCards.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: index < currentCardIndex
                    ? (cardResults[index] ? Colors.green : Colors.orange)
                    : index == currentCardIndex
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${currentCardIndex + 1}/${widget.sessionCards.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              
              // Question card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Word to translate
                      const Text(
                        'Translate to English',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _getAnywaaWord(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1a1a2e),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      if (showingAnswer) ...[
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: cardResults[currentCardIndex]
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                cardResults[currentCardIndex]
                                    ? '✅ Correct!'
                                    : '🔄 Keep practicing',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: cardResults[currentCardIndex]
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getEnglishWord(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1a1a2e),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '+${XPSystem.calculateReviewXP(
                                  rating: cardResults[currentCardIndex]
                                      ? Rating.good
                                      : Rating.again,
                                )} XP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade700,
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
              
              const SizedBox(height: 40),
              
              // Answer buttons
              if (!showingAnswer) ...[
                _AnswerButton(
                  label: "I don't know",
                  color: Colors.red,
                  icon: Icons.close,
                  onPressed: () => _submitAnswer(false),
                ),
                const SizedBox(height: 16),
                _AnswerButton(
                  label: 'I know this',
                  color: Colors.green,
                  icon: Icons.check,
                  onPressed: () => _submitAnswer(true),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAnywaaWord() {
    // TODO: Get from actual word data
    return 'Placeholder'; // Replace with: wordData[currentCard.wordId].anywaa
  }

  String _getEnglishWord() {
    // TODO: Get from actual word data
    return 'Translation'; // Replace with: wordData[currentCard.wordId].english
  }

  void _confirmExit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit session?'),
        content: const Text(
          'Your progress will be lost if you exit now.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close session
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}

class _SessionSummaryDialog extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int xpEarned;
  final List<bool> cardResults;

  const _SessionSummaryDialog({
    required this.correctCount,
    required this.totalCount,
    required this.xpEarned,
    required this.cardResults,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = (correctCount / totalCount * 100).round();
    final isPerfect = correctCount == totalCount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPerfect ? '🌟 Perfect!' : '✨ Great work!',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Stats
            _StatRow(
              label: 'Accuracy',
              value: '$accuracy%',
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'Correct',
              value: '$correctCount/$totalCount',
              icon: Icons.done_all,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _StatRow(
              label: 'XP Earned',
              value: '+$xpEarned',
              icon: Icons.star,
              color: Colors.amber,
            ),
            
            const SizedBox(height: 32),
            
            // Continue button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close session
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a1a2e),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
