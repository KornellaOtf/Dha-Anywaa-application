# Integration Guide: Adding the Learning Engine to Your App

## Step 1: Add Dependencies

Your `pubspec.yaml` already has `shared_preferences`. No new dependencies needed! 

## Step 2: Connect Your Word Data

The learning engine needs a list of word IDs. Here's how to connect it to your existing structure:

### Current Structure (from your codebase)

You have categories like:
- `lib/body_part.dart`
- `lib/words.dart`  
- `lib/vowel.dart`
- etc.

Each likely has a list of words with images. Example:

```dart
// Existing structure (example)
class AnywaaWord {
  final String anywaaText;
  final String englishText;
  final String imagePath;
  // ...
}

final List<AnywaaWord> bodyParts = [
  AnywaaWord(anywaaText: 'Wiic', englishText: 'Head', imagePath: 'assets/...'),
  // ...
];
```

### What You Need to Add

Give each word a **unique ID**:

```dart
class AnywaaWord {
  final String id;           // NEW: unique identifier
  final String anywaaText;
  final String englishText;
  final String imagePath;
  final String category;     // NEW: for topic mastery tracking
  
  const AnywaaWord({
    required this.id,
    required this.anywaaText,
    required this.englishText,
    required this.imagePath,
    required this.category,
  });
}

// Use category_name format for IDs
final bodyParts = [
  AnywaaWord(
    id: 'body_wiic',
    anywaaText: 'Wiic',
    englishText: 'Head',
    imagePath: 'assets/body_part/head.png',
    category: 'body_parts',
  ),
  // ...
];
```

## Step 3: Create a Word Repository

Make one file that collects all words:

```dart
// lib/data/word_repository.dart
import '../body_part.dart';
import '../words.dart';
// ... import all your category files

class WordRepository {
  static List<AnywaaWord> getAllWords() {
    return [
      ...bodyParts,
      ...animals,
      ...birds,
      ...fish,
      // ... all your categories
    ];
  }

  static List<AnywaaWord> getWordsByCategory(String category) {
    return getAllWords().where((w) => w.category == category).toList();
  }

  static List<String> getAllWordIds() {
    return getAllWords().map((w) => w.id).toList();
  }
}
```

## Step 4: Add Daily 5 Card to Home Page

Open `lib/home_page.dart` and add the Daily 5 card at the top:

```dart
import 'services/learning_engine.dart';
import 'services/gamification_service.dart';
import 'data/word_repository.dart';

// Inside your Home screen build method:
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: FutureBuilder<_HomeData>(
      future: _loadHomeData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final data = snapshot.data!;
        
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            //  Daily 5 Card (add this)
            _buildDailyFiveCard(context, data),
            SizedBox(height: 16),
            
            // Your existing Continue button
            _buildContinueButton(),
            
            // Your existing categories grid
            _buildCategoriesGrid(),
          ],
        );
      },
    ),
  );
}

//  Add this method
Widget _buildDailyFiveCard(BuildContext context, _HomeData data) {
  final dailyCompleted = data.dailyCompleted;
  final dueCount = data.dueCount;
  
  return InkWell(
    onTap: () async {
      if (dailyCompleted) {
        // Show "Already completed" message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Daily 5 completed! Come back tomorrow.')),
        );
        return;
      }
      
      // Navigate to Daily 5
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DailyFivePage(
            allWords: WordRepository.getAllWords()
                .map((w) => WordData(
                  id: w.id,
                  anywaaWord: w.anywaaText,
                  englishWord: w.englishText,
                  imagePath: w.imagePath,
                  wrongChoice: _generateWrongChoice(w.id), // see below
                ))
                .toList(),
          ),
        ),
      );
      
      // Reload home data after session
      setState(() {});
    },
    child: Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D5016), Color(0xFF4A7C2A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              dailyCompleted ? Icons.check_circle : Icons.school,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dailyCompleted ? 'Daily 5 Complete!' : 'Daily 5',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  dailyCompleted
                      ? 'Come back tomorrow'
                      : '$dueCount words ready to review',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.white),
        ],
      ),
    ),
  );
}

// Helper to load all home data
Future<_HomeData> _loadHomeData() async {
  final learning = LearningEngine.instance;
  final gamification = GamificationService.instance;
  final allIds = WordRepository.getAllWordIds();
  
  final dailyCompleted = await learning.isDailyCompleted();
  final dueCount = await learning.getDueCount(allIds);
  final gamState = await gamification.load();
  
  return _HomeData(
    dailyCompleted: dailyCompleted,
    dueCount: dueCount,
    gamState: gamState,
  );
}

class _HomeData {
  final bool dailyCompleted;
  final int dueCount;
  final GamState gamState;
  
  _HomeData({
    required this.dailyCompleted,
    required this.dueCount,
    required this.gamState,
  });
}
```

## Step 5: Generate Wrong Choices for Multiple Choice

For the Daily 5 to work, you need a wrong answer choice. Here's a simple generator:

```dart
// lib/data/word_repository.dart (add this)

import 'dart:math';

class WordRepository {
  static final _random = Random();
  
  // ... your existing methods ...
  
  /// Generate a plausible wrong answer for multiple choice
  static String generateWrongChoice(String correctWordId) {
    final allWords = getAllWords();
    final correctWord = allWords.firstWhere((w) => w.id == correctWordId);
    
    // Get words from the same category (more challenging)
    final sameCategory = allWords
        .where((w) => w.category == correctWord.category && w.id != correctWordId)
        .toList();
    
    if (sameCategory.isNotEmpty) {
      return sameCategory[_random.nextInt(sameCategory.length)].anywaaText;
    }
    
    // Fallback: any random word
    final randomWord = allWords[_random.nextInt(allWords.length)];
    return randomWord.anywaaText;
  }
}
```

## Step 6: Add Streak & XP Display

Add this to your app bar or home page top:

```dart
// Inside your home page
FutureBuilder<GamState>(
  future: GamificationService.instance.load(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();
    
    final state = snapshot.data!;
    
    return Container(
      padding: EdgeInsets.all(12),
      child: Row(
        children: [
          // Streak
          Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
          Text('${state.streakDays}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          
          SizedBox(width: 20),
          
          // Level
          Icon(Icons.star, color: Colors.amber, size: 24),
          Text('Level ${state.level}', style: TextStyle(fontSize: 18)),
          
          Spacer(),
          
          // XP progress to next level
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: state.levelPct,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(Color(0xFF2D5016)),
            ),
          ),
        ],
      ),
    );
  },
)
```

## Step 7: Add Topic Mastery to Category Pages

In each category page (animals, birds, etc.), show mastery progress:

```dart
// At the top of your category page
FutureBuilder<(int, int)>(
  future: LearningEngine.instance.getTopicMastery(categoryWordIds),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return SizedBox();
    
    final (mastered, total) = snapshot.data!;
    final progress = total > 0 ? mastered / total : 0.0;
    
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Color(0xFF2D5016)),
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text('$mastered / $total mastered'),
        ],
      ),
    );
  },
)
```

## Step 8: Testing

### Quick test flow:

1. Open app
2. See Daily 5 card with "X words ready to review"
3. Tap Daily 5
4. Answer 5 questions
5. See summary (words reviewed, XP earned, combo)
6. Return to home
7. See "Daily 5 Complete! Come back tomorrow"
8. Check streak increased by 1

### Debug tips:

```dart
// Add this to your settings page for testing
ElevatedButton(
  onPressed: () async {
    await LearningEngine.instance.resetAllProgress();
    await GamificationService.instance.load(); // reset gamification too if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All progress reset!')),
    );
  },
  child: Text('Reset All Progress (DEBUG)'),
),
```

## Step 9: Optional Enhancements

### Sound Effects

Add to `assets/sounds/`:
- `correct.mp3` — cheerful chime
- `wrong.mp3` — gentle buzz
- `combo.mp3` — energy sound
- `level_up.mp3` — celebration

Play on answer:

```dart
import 'package:audioplayers/audioplayers.dart';

final player = AudioPlayer();

void _onAnswer(bool correct) async {
  // ... existing code ...
  
  await player.play(AssetSource(correct ? 'sounds/correct.mp3' : 'sounds/wrong.mp3'));
}
```

### Animations

Use `AnimatedContainer` and `AnimatedOpacity` for:
- Correct answer → green pulse
- Wrong answer → red shake
- XP earned → number flies up
- Level up → confetti explosion

### Share Word Card

Generate a PNG card with:
- Word in Anywaa
- Translation
- Image
- "Learn Dha Anywaa" footer

Share via WhatsApp (matches how you distribute the app):

```dart
import 'package:share_plus/share_plus.dart';
import 'dart:ui' as ui;

Future<void> shareWordCard(String anywaa, String english, String imagePath) async {
  // Generate PNG using CustomPainter
  // ... render card ...
  await Share.shareXFiles([XFile(pngPath)], text: 'Learn Dha Anywaa with me!');
}
```

## Troubleshooting

### "Words not showing in Daily 5"
- Check `WordRepository.getAllWordIds()` returns non-empty list
- Check word IDs are unique
- Add debug print: `print('All word IDs: ${allIds.length}');`

### "Daily 5 completed immediately resets"
- Check date format is consistent (YYYY-MM-DD)
- Check time zone handling
- Add debug: `print('Today: ${_today()}');`

### "XP not increasing"
- Check `GamificationService.onLessonComplete()` is called
- Check `SharedPreferences` keys match
- Add debug: `print('XP awarded: $xp');`

### "Streak broken unexpectedly"
- Check freeze count (starts with 1)
- Check date comparison logic
- Add debug: `print('Last active: $lastActive, Today: $today');`

## Next Steps

1.  Learning engine created
2.  Daily 5 page created
3.  Gamification integrated
4. ⬜ Connect to your word data
5. ⬜ Add Daily 5 card to home
6. ⬜ Add streak/XP display
7. ⬜ Add topic mastery rings
8. ⬜ Test with real users
9. ⬜ Add audio (record with community)
10. ⬜ Collect 10k reviews → evaluate FSRS upgrade

## Questions?

Read `LEARNING_ALGORITHM.md` for the full science behind the system.

**You now have the most effective spaced repetition algorithm for endangered language learning. Go make it work! **
