# Roadmap: Dha Anywaa Learning System Implementation

This roadmap transforms the current Leitner box system into a habit-forming, scientifically-backed learning engine.

---

## Current State (v1.4.12)

**Existing system:**
- Leitner box spaced repetition (5 boxes)
- Binary correct/incorrect answers
- Quiz mode with 10 random questions
- Basic category browsing
- Audio playback
- No streak system
- No progress visualization
- No Daily 5 concept

**Technical debt:**
- Word state stored in Hive boxes
- No review event logging
- No retention tracking
- No individual difficulty tracking

---

## Phase 1: Foundation (v1.5.0)
**Goal**: Replace Leitner with FSRS, add Daily 5, basic progress feedback

### 1.1 FSRS Engine Implementation
**Files to create:**
- `lib/learning/fsrs_engine.dart` - Core FSRS-6 algorithm
- `lib/learning/card_state.dart` - New card model
- `lib/learning/review_event.dart` - Review logging
- `lib/learning/rating_mapper.dart` - Binary → FSRS mapper

**Card state migration:**
```dart
class CardState {
  final String wordId;
  final double stability;        // NEW: S parameter
  final double difficulty;       // NEW: D parameter
  final DateTime dueDate;        // MIGRATED from Leitner
  final DateTime lastReview;     // MIGRATED from Leitner
  final CardStateType state;     // NEW: New/Learning/Review/Relearning
  final int reps;                // MIGRATED from Leitner
  final int lapses;              // NEW: count of "Again" ratings
}
```

**Migration strategy:**
```dart
// Map Leitner box → approximate FSRS stability
double migrateBoxToStability(int box) {
  const intervals = [0.0, 1.0, 3.0, 7.0, 14.0, 30.0];
  return intervals[min(box, 5)];
}

// Initial difficulty for all words
const double initialDifficulty = 5.0;  // FSRS default
```

**Tasks:**
- [ ] Implement FSRS algorithm (stability, difficulty, retrievability calculations)
- [ ] Create new SQLite table for card states
- [ ] Create append-only review_events table
- [ ] Write migration script Leitner → FSRS
- [ ] Test: verify interval calculations match expected behavior
- [ ] Test: verify migration preserves user progress

### 1.2 Daily 5 Session Builder
**Files to create:**
- `lib/learning/session_builder.dart` - Card selection logic
- `lib/pages/daily_five_session_page.dart` - UI

**Session builder algorithm:**
```dart
Future<List<Card>> buildDaily5Session() async {
  final cards = <Card>[];
  
  // 1. Get overdue cards (retrievability < 0.90)
  final overdue = await getOverdueCards();
  
  // 2. Bias first 2-3 toward easier cards
  final easy = overdue.where((c) => c.difficulty < 6.0).toList();
  cards.addAll(easy.take(2));
  
  // 3. Add remaining due cards
  cards.addAll(overdue.skip(2).take(3 - cards.length));
  
  // 4. Fill with new cards if needed
  if (cards.length < 5) {
    final newCards = await getNewCards(limit: 5 - cards.length);
    cards.addAll(newCards);
  }
  
  return cards;
}
```

**UI changes:**
- Replace home quiz button with large "Daily 5" card
- Show due count + progress ring
- Session flow:
  1. Card presentation
  2. User answer
  3. Immediate feedback ("This word is now more stable")
  4. Next card
  5. Session summary after 5 cards

**Tasks:**
- [ ] Implement session builder with early-success bias
- [ ] Create Daily 5 session UI
- [ ] Replace home quiz button with Daily 5
- [ ] Add session summary screen
- [ ] Test: verify first 2-3 cards are easier
- [ ] Test: verify session completes in ~2-3 minutes

### 1.3 Progress & Feedback
**Files to create:**
- `lib/progress/xp_system.dart` - XP + Level
- `lib/progress/mastery_tracker.dart` - Category mastery
- `lib/widgets/progress_ring.dart` - Circular progress indicator

**XP System:**
```dart
class XPSystem {
  static const int xpPerCorrect = 10;
  static const int xpPerIncorrect = 5;  // Still rewarded for reviewing
  
  static const List<int> levelThresholds = [
    0, 100, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000
  ];
  
  int getLevel(int totalXP) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (totalXP >= levelThresholds[i]) return i;
    }
    return 0;
  }
}
```

**Progress rings:**
- Level ring (home screen)
- Daily goal ring (home screen)
- Category mastery rings (category pages)

**Immediate feedback messages:**
- Correct: "✓ This word is now more stable" + stability gain
- Incorrect: "This word will return sooner" + no shame
- Session summary: "5 words reviewed. 3 got stronger. 2 need practice."

**Tasks:**
- [ ] Implement XP system
- [ ] Create level calculation
- [ ] Add progress rings to home screen
- [ ] Show immediate feedback after each card
- [ ] Create session summary with progress stats
- [ ] Test: verify XP awards correctly
- [ ] Test: verify level progression

**Estimated time**: 3-4 weeks  
**Release**: v1.5.0

---

## Phase 2: Habit Formation (v1.6.0)
**Goal**: Add streak system, reminder, warm recovery

### 2.1 Forgiving Streak System
**Files to create:**
- `lib/progress/streak_system.dart` - Streak logic + freeze
- `lib/widgets/streak_indicator.dart` - UI component

**Streak logic:**
```dart
class StreakSystem {
  int currentStreak;
  DateTime lastCompletedDate;
  int freezesAvailable;
  bool freezeUsedToday;
  
  Future<void> recordSessionComplete() async {
    final today = DateTime.now().startOfDay;
    final yesterday = today.subtract(Duration(days: 1));
    
    if (lastCompletedDate == yesterday) {
      // Continue streak
      currentStreak++;
    } else if (lastCompletedDate == today) {
      // Already completed today
      return;
    } else if (freezesAvailable > 0 && !freezeUsedToday) {
      // Use freeze
      freezesAvailable--;
      freezeUsedToday = true;
      currentStreak++;  // Streak protected
    } else {
      // Streak broken - warm reset
      currentStreak = 1;
    }
    
    lastCompletedDate = today;
    
    // Earn freeze every 7 days
    if (currentStreak % 7 == 0) {
      freezesAvailable++;
    }
  }
}
```

**Recovery messaging:**
- Break detected: "Welcome back. Your words are still here."
- Freeze used: "Your freeze kept your streak safe."
- Never: "You broke your streak!" ❌

**Tasks:**
- [ ] Implement streak counter
- [ ] Add freeze system (1 initial + earn more)
- [ ] Create warm recovery messages
- [ ] Add streak indicator to home screen
- [ ] Show freeze status
- [ ] Test: verify streak counts correctly
- [ ] Test: verify freeze mechanics work
- [ ] Test: verify no shame language

### 2.2 Respectful Reminder
**Files to create:**
- `lib/notifications/reminder_service.dart` - Local notification

**Reminder system:**
- One notification per day maximum
- User chooses exact time
- Easy to disable (always visible in settings)
- Gentle message: "Time for your Daily 5?" or "Your words are ready"

**Tasks:**
- [ ] Implement local notification
- [ ] Add time picker in settings
- [ ] Add enable/disable toggle
- [ ] Write gentle message copy
- [ ] Test: verify single daily reminder
- [ ] Test: verify disable works
- [ ] Test: verify time picker saves correctly

**Estimated time**: 2-3 weeks  
**Release**: v1.6.0

---

## Phase 3: Community & Culture (v1.7.0)
**Goal**: Speaker attribution, share feature, cultural respect

### 3.1 Community Audio Credits
**Files to update:**
- `lib/services/audio_service.dart` - Add speaker metadata
- Database: Add `speakers` table

**Speaker attribution:**
```dart
class AudioMetadata {
  final String speakerName;
  final String region;         // Optional: Gambela, Ethiopia, etc.
  final DateTime recordedDate;
}
```

**UI changes:**
- Show speaker name on audio card
- "Recorded by [Name]" below audio button
- Optional: Speaker profile page (future)

**Tasks:**
- [ ] Add speakers table to database
- [ ] Associate audio files with speakers
- [ ] Show speaker credit on cards
- [ ] Update audio service with metadata
- [ ] Test: verify credits display correctly

### 3.2 Share-a-Word Feature
**Files to create:**
- `lib/sharing/share_card.dart` - WhatsApp optimized share

**Share card content:**
- Word in Dha Anywaa
- English meaning
- Audio player (embedded or link)
- "Learn with Dha Anywaa" branding

**Tasks:**
- [ ] Create shareable card image generator
- [ ] Add share button to card review
- [ ] Optimize for WhatsApp dimensions
- [ ] Include audio link or embedded player
- [ ] Test: verify share works on Android
- [ ] Test: verify card displays well in WhatsApp

**Estimated time**: 2 weeks  
**Release**: v1.7.0

---

## Phase 4: Onboarding Excellence (v1.8.0)
**Goal**: First-time user success, immediate wins

### 4.1 First-Session Win Design
**Files to create:**
- `lib/onboarding/first_session.dart` - Onboarding flow

**First session algorithm:**
```dart
Future<List<Card>> buildFirstSession() async {
  // Handpicked easy, common words
  final easyWords = [
    'hello', 'thank you', 'yes', 'no', 'water'
  ];
  
  return getCardsForWords(easyWords);
}
```

**Onboarding flow:**
1. Welcome screen (1 screen, skip button visible)
2. Jump straight to first 5 words
3. First correct answer: "You got your first word!"
4. Session complete: "You completed your first Daily 5!"
5. Streak started: "Day 1 streak started!"

**Tasks:**
- [ ] Create handpicked easy starter words
- [ ] Build first-session special flow
- [ ] Add milestone celebrations
- [ ] Make skip button visible on welcome
- [ ] Test: verify first session has high success rate
- [ ] Test: verify celebrations trigger correctly

**Estimated time**: 1-2 weeks  
**Release**: v1.8.0

---

## Future Considerations (Post v1.8.0)

### Advanced Features
- Response-time based rating (Hard/Easy split)
- Explicit 4-button UI (Again/Hard/Good/Easy)
- Regional audio variants
- Speaker profiles
- Category mastery badges
- Family sharing progress

### Analytics & Optimization
- Retention rate tracking
- Algorithm parameter tuning
- A/B testing for onboarding
- User feedback collection

### Technical Improvements
- Cloud sync for multi-device
- Backup/restore
- Export review history
- FSRS parameter optimization from user data

---

## Success Criteria

### Phase 1 (v1.5.0)
- [ ] FSRS algorithm implemented and tested
- [ ] Daily 5 replaces old quiz mode
- [ ] Migration script successfully converts Leitner → FSRS
- [ ] Users see immediate progress feedback
- [ ] Session completes in <3 minutes

### Phase 2 (v1.6.0)
- [ ] Streak system working with freeze protection
- [ ] Zero shame language in all messaging
- [ ] One respectful reminder per day
- [ ] Warm recovery after breaks

### Phase 3 (v1.7.0)
- [ ] All audio has speaker attribution
- [ ] Share-a-word works on WhatsApp
- [ ] Cultural identity respected in all features

### Phase 4 (v1.8.0)
- [ ] First-time users complete first session successfully
- [ ] Onboarding < 1 minute to first word
- [ ] Immediate feeling: "I can do this"

---

## Timeline Estimate

- **Phase 1**: 3-4 weeks → v1.5.0 (FSRS + Daily 5 + Progress)
- **Phase 2**: 2-3 weeks → v1.6.0 (Streak + Reminder)
- **Phase 3**: 2 weeks → v1.7.0 (Audio credits + Share)
- **Phase 4**: 1-2 weeks → v1.8.0 (Onboarding)

**Total**: ~8-11 weeks to complete all 4 phases

---

## Risk Mitigation

### Technical Risks
- **FSRS complexity**: Start with reference implementation, test heavily
- **Migration bugs**: Write reversible migration, test on copy of production data
- **Performance**: Profile card selection algorithm, optimize queries

### User Risks
- **Algorithm change confusion**: Clear messaging, gradual rollout
- **Progress loss fear**: Preserve all existing progress, show continuity
- **Feature overload**: Roll out phases sequentially, gather feedback

### Mitigation Strategy
- Beta testing with small user group before each release
- Rollback plan for each phase
- User feedback survey after v1.5.0

---

**Document Version**: 1.0  
**Last Updated**: November 2026  
**Next Review**: After Phase 1 completion
