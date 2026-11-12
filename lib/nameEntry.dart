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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Hero section with gradient ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      kGreen.withOpacity(0.08),
                      context.c.bg,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Brand logo with subtle glow
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, t, child) => Opacity(
                        opacity: t.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 20),
                          child: child,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.c.card,
                          boxShadow: [
                            BoxShadow(
                              color: kGreen.withOpacity(0.15),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const BrandLeaf(size: 72),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Anywaa greeting
                    Text('Dëëri jööt?',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: context.c.accent)),
                    const SizedBox(height: 6),

                    // App name
                    Text('Dha Anywaa',
                        style: GoogleFonts.playfairDisplay(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: context.c.text,
                            letterSpacing: 0.5,
                            height: 1.1)),
                    const SizedBox(height: 10),

                    // Tagline
                    Text('Learn to read, write, and speak Anywaa',
                        style: TextStyle(
                            fontSize: 15,
                            color: context.c.textSub,
                            height: 1.4)),
                  ],
                ),
              ),

              // ── Feature highlights ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    _FeaturePill(
                      icon: Icons.volume_up_rounded,
                      label: 'Audio',
                      color: kGreen,
                    ),
                    const SizedBox(width: 10),
                    _FeaturePill(
                      icon: Icons.cloud_off_rounded,
                      label: 'Offline',
                      color: kGreenMid,
                    ),
                    const SizedBox(width: 10),
                    _FeaturePill(
                      icon: Icons.quiz_rounded,
                      label: 'Quizzes',
                      color: kGold,
                    ),
                  ],
                ),
              ),

              // ── Name input section ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What should we call you?',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.c.text)),
                      const SizedBox(height: 6),
                      Text('Your name appears on your home screen',
                          style: TextStyle(
                              fontSize: 13, color: context.c.textSub)),
                      const SizedBox(height: 16),

                      // Input
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: context.c.card,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _focused
                              ? [
                                  BoxShadow(
                                    color: kGreen.withValues(alpha: 0.18),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : const [kShadowSoft],
                        ),
                        child: TextFormField(
                          focusNode: _focusNode,
                          onChanged: (val) => setState(() => name = val),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Name is required' : null,
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                            hintStyle: TextStyle(
                                color: context.c.textSub, fontSize: 16),
                            filled: true,
                            fillColor: context.c.card,
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color:
                                  _focused ? context.c.accent : context.c.textSub,
                              size: 22,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: context.c.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  BorderSide(color: context.c.accent, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // CTA button
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [kShadowBtn],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await savedData.setName(name);
                                await AnalyticsService.instance.setUser(name);
                                if (!mounted) return;
                                Navigator.pushReplacementNamed(
                                    context, 'home_page');
                              }
                            },
                            child: const Text('Start learning',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: context.c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.c.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.c.text)),
          ],
        ),
      ),
    );
  }
}
