import 'package:dha_anywaaa/components/savedData.dart';
import 'package:dha_anywaaa/home_page.dart';
import 'package:dha_anywaaa/nameEntry.dart';
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
        backgroundColor: const Color(0xFFF5F0E8),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/word_images/awal_icon.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: Color(0xFF1B4332),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }
    return _needsName ? const NameEntry() : const HomePage();
  }
}
