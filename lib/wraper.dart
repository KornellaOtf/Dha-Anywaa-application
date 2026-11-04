import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/home_page.dart';
import 'package:dha_anywaaa/nameEntry.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});
  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final SavedData _savedData = SavedData();
  bool _loading = true;
  bool _needsName = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final name = await _savedData.getName();
    if (!mounted) return;
    setState(() {
      _needsName = name == 'guess';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            builder: (_, opacity, child) => Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: child,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with subtle shadow
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kGreen.withOpacity(0.18),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/word_images/awal_icon.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Dha Anywaa',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: kGreen,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: kGreen,
                    backgroundColor: kGreen.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _needsName ? const NameEntry() : const HomePage();
  }
}
