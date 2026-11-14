import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_widget.dart';

class QuickChallengePage extends StatefulWidget {
  final List<Map<String, dynamic>> words;
  
  const QuickChallengePage({
    super.key,
    required this.words,
  });

  @override
  State<QuickChallengePage> createState() => _QuickChallengePageState();
}

class _QuickChallengePageState extends State<QuickChallengePage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _currentRound = 0;
  int _wordsLearned = 0;
  bool _showCelebration = false;
  
  static const int _maxRounds = 3;
  
  Map<String, dynamic>? get _currentWord {
    if (_currentRound >= widget.words.length || _currentRound >= _maxRounds) {
      return null;
    }
    return widget.words[_currentRound];
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void _playAudio() async {
    final word = _currentWord;
    if (word != null && word['soundFile'] != null) {
      await _audioPlayer.play(AssetSource(word['soundFile']));
    }
  }
  
  void _onLearned() async {
    setState(() {
      _showCelebration = true;
      _wordsLearned++;
    });
    
    // Track the word learned
    await LeaderboardService.instance.incrementWeeklyWords();
    
    // Hide celebration after 1 second
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _showCelebration = false;
      _currentRound++;
    });
    
    // Auto-play next word audio
    if (_currentWord != null) {
      await Future.delayed(const Duration(milliseconds: 300));
      _playAudio();
    }
  }
  
  void _exitChallenge() {
    Navigator.pop(context, _wordsLearned);
  }
  
  @override
  void initState() {
    super.initState();
    // Auto-play first word
    Future.delayed(const Duration(milliseconds: 500), _playAudio);
  }

  @override
  Widget build(BuildContext context) {
    final word = _currentWord;
    
    if (word == null) {
      // All rounds completed
      return _buildCompletionScreen();
    }
    
    return Scaffold(
      backgroundColor: context.c.bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F4D3A),
        title: Text(
          'Quick Challenge - ${_currentRound + 1}/$_maxRounds',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _exitChallenge,
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Progress indicator
                  LinearProgressIndicator(
                    value: (_currentRound + 1) / _maxRounds,
                    backgroundColor: context.c.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1F4D3A)),
                    minHeight: 8.h,
                  ),
                  SizedBox(height: 40.h),
                  
                  // Word image
                  if (word['imagePath'] != null)
                    Container(
                      height: 200.h,
                      width: 200.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Image.asset(
                          word['imagePath'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  SizedBox(height: 32.h),
                  
                  // Anywaa word
                  Text(
                    word['anywaa'] ?? '',
                    style: TextStyle(
                      fontSize: 36.sp,
                      fontWeight: FontWeight.bold,
                      color: context.c.accent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 12.h),
                  
                  // English translation
                  Text(
                    word['english'] ?? '',
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: context.c.textSub,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Play audio button
                  IconButton(
                    onPressed: _playAudio,
                    icon: Icon(
                      Icons.volume_up,
                      size: 48.sp,
                      color: context.c.accent,
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Learned button
                  SizedBox(
                    width: double.infinity,
                    height: 56.h,
                    child: ElevatedButton(
                      onPressed: _onLearned,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F4D3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Learned',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16.h),
                  
                  // Skip button
                  TextButton(
                    onPressed: _exitChallenge,
                    child: Text(
                      'Take a break',
                      style: TextStyle(
                        color: context.c.textSub,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Celebration overlay
          if (_showCelebration)
            const CelebrationOverlay(
              type: CelebrationType.quickWin,
            ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionScreen() {
    return Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 100.sp,
                color: context.c.accent,
              ),
              
              SizedBox(height: 24.h),
              
              Text(
                'Challenge Complete!',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: context.c.accent,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 16.h),
              
              Text(
                'You learned $_wordsLearned words in 30 seconds',
                style: TextStyle(
                  fontSize: 18.sp,
                  color: context.c.textSub,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: 48.h),
              
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _exitChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F4D3A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
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
