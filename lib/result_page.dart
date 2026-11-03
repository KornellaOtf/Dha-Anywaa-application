import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Result extends StatelessWidget {
  final int finalResult;
  final int total;

  const Result({super.key, required this.finalResult, required this.total});

  String _message() {
    final pct = total > 0 ? (finalResult / total * 100).round() : 0;
    if (pct < 40) return 'Keep practising —\nyou\'ll get there!';
    if (pct < 60) return 'Good effort!\nKeep going.';
    if (pct < 80) return 'Well done!\nAlmost there.';
    return 'Excellent!\nYou nailed it.';
  }

  IconData _icon() {
    final pct = total > 0 ? (finalResult / total * 100).round() : 0;
    if (pct < 40) return Icons.sentiment_dissatisfied_rounded;
    if (pct < 60) return Icons.sentiment_neutral_rounded;
    if (pct < 80) return Icons.sentiment_satisfied_rounded;
    return Icons.sentiment_very_satisfied_rounded;
  }

  Color _iconColor() {
    final pct = total > 0 ? (finalResult / total * 100).round() : 0;
    if (pct < 40) return const Color(0xFF8B3A2A);
    if (pct < 60) return const Color(0xFFC9993A);
    if (pct < 80) return const Color(0xFF1B4332);
    return const Color(0xFF1B4332);
  }

  @override
  Widget build(BuildContext context) {
    const bg    = Color(0xFFF5F0E8);
    const green = Color(0xFF1B4332);
    const gold  = Color(0xFFC9993A);

    final pct = total > 0 ? (finalResult / total * 100).round() : 0;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // ── Mood icon ──────────────────────────────────────────────
              Icon(_icon(), size: 72, color: _iconColor()),
              const SizedBox(height: 16),
              Text(
                _message(),
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1C1C1C)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // ── Score circle ───────────────────────────────────────────
              Container(
                width: 180, height: 180,
                decoration: const BoxDecoration(
                    color: green, shape: BoxShape.circle),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$finalResult / $total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                          color: Color(0xCCFFFFFF), fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // ── Share button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share score'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: green,
                    side: const BorderSide(color: green),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text:
                            'I scored $finalResult/$total ($pct%) on the Dha Anywaa quiz!'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Score copied to clipboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // ── Try again button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: const Color(0xFF1C1C1C),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 'quiz', ModalRoute.withName('home_page')),
                  child: const Text('Try again',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              // ── Back home button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 'home_page', (_) => false),
                  child: const Text('Back to home',
                      style: TextStyle(color: green, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
