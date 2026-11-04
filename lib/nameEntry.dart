import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NameEntry extends StatefulWidget {
  const NameEntry({super.key});
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
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 40, bottom: 8),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App icon
                      ClipOval(
                        child: Image.asset(
                          'assets/word_images/awal_icon.jpeg',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.eco_rounded, color: kGreen, size: 44),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Welcome to',
                          style: TextStyle(fontSize: 16, color: kTextSub)),
                      const SizedBox(height: 4),
                      const Text('Obwöc paac',
                          style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: kText)),
                      const SizedBox(height: 4),
                      const Text('Dha Anywaa learning hub',
                          style: TextStyle(fontSize: 15, color: kTextSub)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // ── Label ─────────────────────────────────────────────────
                const Text('What\'s your name?',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kText)),
                const SizedBox(height: 14),

                // ── Input with animated shadow ────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _focused
                        ? [
                            BoxShadow(
                              color: kGreen.withOpacity(0.18),
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle:
                          const TextStyle(color: kTextMuted, fontSize: 16),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: _focused ? kGreen : kTextMuted,
                        size: 22,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: kGreen, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── CTA button ────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.0),
                    duration: const Duration(milliseconds: 150),
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            savedData.setName(name);
                            Navigator.pushReplacementNamed(
                                context, 'home_page');
                          }
                        },
                        child: const Text('Get started →',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
