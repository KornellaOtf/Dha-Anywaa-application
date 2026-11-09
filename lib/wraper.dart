import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/home_page.dart';
import 'package:dha_anywaaa/nameEntry.dart';
import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/widgets/brand_leaf.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    
    // Initialize analytics with stored user ID
    await AnalyticsService.instance.initializeFromStorage();
    
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
        backgroundColor: context.c.bg,
        body: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (_, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, (1 - t) * 18),
                child: child,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BrandLeaf(size: 108),
                const SizedBox(height: 26),
                Text(
                  'Dha Anywaa',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: context.c.text,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Learn the Anywaa language, offline',
                  style: TextStyle(fontSize: 14, color: context.c.textSub),
                ),
                const SizedBox(height: 34),
                SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.c.accent,
                    backgroundColor: context.c.accent.withValues(alpha: 0.12),
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
