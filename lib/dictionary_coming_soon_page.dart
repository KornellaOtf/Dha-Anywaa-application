import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dha_anywaaa/theme/app_theme.dart';

class DictionaryComingSoonPage extends StatelessWidget {
  const DictionaryComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: kGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 4,
        title: Text(
          'Dictionary',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: kGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: kGold,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Heading
                Text(
                  'Coming Next Month',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: c.text,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'The Dha Anywaa dictionary is currently being verified and will be available next month.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: c.textSub,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Info card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fact_check_rounded, 
                              color: kGreen, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            '3,346 words',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: c.text,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Currently undergoing verification',
                        style: TextStyle(
                          fontSize: 14,
                          color: c.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: kGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: kGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'In the meantime, try asking Anywaa AI to translate words for you!',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: kGreen.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
