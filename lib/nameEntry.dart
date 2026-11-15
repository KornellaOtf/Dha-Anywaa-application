import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/services/analytics_service.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:dha_anywaaa/widgets/brand_leaf.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NameEntry extends StatefulWidget {
  const NameEntry({super.key});
  @override
  State<NameEntry> createState() => _NameEntryState();
}

class _NameEntryState extends State<NameEntry> {
  final SavedData savedData = SavedData();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();
  String name = '';
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _rise(int i, Widget child, {double distance = 24}) {
    final delay = (i * 90).clamp(0, 500);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 550 + delay),
      curve: Interval(delay / 900.0, 1.0, curve: Curves.easeOutCubic),
      builder: (_, t, c) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * distance),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero ────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 52, 28, 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kGreen.withValues(alpha: 0.10),
                      kGreen.withValues(alpha: 0.02),
                      c.bg,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
                child: Column(
                  children: [
                    _rise(
                      0,
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: kGreen.withValues(alpha: 0.25),
                              width: 1.5),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: c.card,
                            boxShadow: [
                              BoxShadow(
                                color: kGreen.withValues(alpha: 0.18),
                                blurRadius: 32,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const BrandLeaf(size: 68),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _rise(
                      1,
                      Text('Dëëri jööt?',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: c.accent)),
                    ),
                    const SizedBox(height: 6),
                    _rise(
                      2,
                      Text('Dha Anywaa',
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: c.text,
                              letterSpacing: 0.5,
                              height: 1.1)),
                    ),
                    const SizedBox(height: 12),
                    _rise(
                      3,
                      Text('Learn to read, write, and speak Anywaa',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: c.textSub)),
                    ),
                  ],
                ),
              ),

              // ── Feature pills ───────────────────────────────────────────
              _rise(
                4,
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 0),
                  child: Row(
                    children: [
                      _FeaturePill(
                          icon: Icons.volume_up_rounded,
                          label: 'Audio',
                          color: kGreen),
                      const SizedBox(width: 10),
                      _FeaturePill(
                          icon: Icons.cloud_off_rounded,
                          label: 'Offline',
                          color: kGreenMid),
                      const SizedBox(width: 10),
                      _FeaturePill(
                          icon: Icons.quiz_rounded,
                          label: 'Quizzes',
                          color: kGold),
                    ],
                  ),
                ),
              ),

              // ── Name form card ──────────────────────────────────────────
              _rise(
                5,
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: c.border),
                      boxShadow: const [kShadowSoft],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What should we call you?',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: c.text)),
                          const SizedBox(height: 6),
                          Text('Your name appears on your home screen',
                              style: TextStyle(
                                  fontSize: 13, color: c.textSub)),
                          const SizedBox(height: 18),

                          // Input
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: c.bg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _focused
                                    ? c.accent.withValues(alpha: 0.7)
                                    : c.border,
                                width: _focused ? 1.6 : 1,
                              ),
                              boxShadow: _focused
                                  ? [
                                      BoxShadow(
                                        color: c.accent
                                            .withValues(alpha: 0.15),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : const [],
                            ),
                            child: TextFormField(
                              focusNode: _focusNode,
                              onChanged: (val) =>
                                  setState(() => name = val),
                              validator: (v) {
                                final t = v?.trim() ?? '';
                                if (t.isEmpty) return 'Please enter your name';
                                if (t.length < 2) {
                                  return 'Name must be at least 2 characters';
                                }
                                return null;
                              },
                              textCapitalization:
                                  TextCapitalization.words,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: c.text),
                              decoration: InputDecoration(
                                hintText: 'Enter your name',
                                hintStyle: TextStyle(
                                    color: c.textSub,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400),
                                filled: false,
                                prefixIcon: Container(
                                  margin:
                                      const EdgeInsets.only(left: 12),
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: c.accent
                                        .withValues(alpha: 0.12),
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: _focused
                                        ? c.accent
                                        : c.textSub,
                                  ),
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(
                                        minWidth: 0, minHeight: 0),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 16),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // CTA — gradient green with arrow
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [kGreenMid, kGreen],
                                ),
                                boxShadow: const [kShadowBtn],
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                ),
                                icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20),
                                label: const Text('Start learning',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: 0.3)),
                                onPressed: () async {
                                  if (_formKey
                                      .currentState!
                                      .validate()) {
                                    await savedData.setName(name);
                                    await AnalyticsService.instance
                                        .setUser(name);
                                    if (!context.mounted) return;
                                    Navigator.pushReplacementNamed(
                                        context, 'home_page');
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 13, color: c.textSub),
                                const SizedBox(width: 5),
                                Text(
                                  'Your progress stays on this device',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: c.textSub),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature pill: small icon + label chip ────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.c.border),
          boxShadow: const [kShadowSoft],
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 7),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.c.text)),
          ],
        ),
      ),
    );
  }
}
