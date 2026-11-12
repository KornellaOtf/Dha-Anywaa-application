# Learning System Design for Dha Anywaa
## Habit-forming + loved through how the system works

This document outlines the complete system for transforming Dha Anywaa into a habit-forming language learning app built on scientific principles and ethical design.

---

## 1. Core Learning Engine (FSRS-6)

**Algorithm: FSRS-6** (Free Spaced Repetition Scheduler)
- **Desired retention**: 0.90 (90% recall probability)
- **Storage per word**:
  - `stability` (S): How long the memory lasts
  - `difficulty` (D): How hard the item is for this user
  - `due_date`: When next review is scheduled
  - `last_review`: Timestamp of last review
  - `state`: New / Learning / Review / Relearning
  - `reps`: Total review count
  - `lapses`: Number of times forgotten

**Review logging** (append-only):
- Every rating
- Timestamp
- Response time (when available)
- Card state before/after

**Rating mapping** (current binary UI):
```dart
Rating mapUserAnswerToRating({
  required bool wasCorrect,
  Duration? responseTime,
  Duration? averageResponseTime,
}) {
  if (!wasCorrect) {
    return Rating.again;  // 1 - failure
  }
  
  // Future upgrade path: response-time based grading
  if (responseTime != null && averageResponseTime != null) {
    final ratio = responseTime.inMilliseconds / averageResponseTime.inMilliseconds;
    if (ratio < 0.6) return Rating.easy;   // 4 - very fast
    if (ratio > 1.8) return Rating.hard;   // 2 - struggled
  }
  
  return Rating.good;  // 3 - normal success (default)
}
```

**FSRS Ratings**:
- **Again (1)**: Forgot → Stability drops, difficulty rises, goes to relearning
- **Hard (2)**: Struggled but got it → Small stability gain, difficulty rises
- **Good (3)**: Normal recall → Solid stability growth (default path)
- **Easy (4)**: Effortless → Largest stability gain, difficulty drops

**Learning steps**: 1m → 10m before full FSRS scheduling kicks in
**Maximum interval**: 365 days
**Interval fuzzing**: Light randomization to spread reviews naturally

---

## 2. Daily 5 Session (The Heart of the Habit)

**Always the top action on Home screen**

**Session structure**:
- Target: **5 cards** (slightly flexible)
- **High early success rate**: First 2-3 cards biased toward easier/recently successful items
- Mix of new cards + due reviews
- Ends quickly with a clear win
- Session summary: "X words got stronger today"

**Why 5?**
- Short enough to do every day
- Long enough to feel meaningful
- Completes in ~2-3 minutes
- Low barrier to starting

**Card selection algorithm**:
1. Check for due cards (retrievability < 90%)
2. Include 1-2 easy cards if this is first session of day
3. Mix in new cards if < 5 due
4. Sort by: overdue > ease > random
5. First 2-3 cards weighted toward recent successes

---

## 3. Progress & Competence Feedback

### XP + Level System
- **Honest**: Tied to real reviews, not fake metrics
- XP per review: 10 XP (correct), 5 XP (incorrect but reviewed)
- Level thresholds: exponential growth (100, 250, 500, 1000...)

### Visual Progress Rings
- **Level ring**: Overall progress to next level
- **Daily goal ring**: Reviews completed today / daily target
- **Category mastery rings**: % of category words in "mature" state (stability > 21 days)

### Immediate Feedback After Every Review
- **Correct**: "This word is now more stable" + new due date
- **Incorrect**: "This word will return sooner" (no shame language)
- End-of-session summary:
  - "5 words reviewed"
  - "3 words got stronger"
  - "2 words need more practice"
  - Next review time for each

### Visible Progress Everywhere
- Home screen: rings + streak + level
- After session: gains summary
- Profile: total reviews, words learned, mastery by category

---

## 4. Forgiving Streak System

**Streak definition**: Consecutive days with ≥1 completed Daily 5

**Streak protection**:
- **1 free freeze** (earn more over time)
- Freeze activates automatically on first miss
- Additional freezes: 1 per 7-day streak milestone

**Language & tone**:
- **Never shame**: No "You broke your streak"
- **No pressure**: No "Your streak is dying"
- **Warm recovery**: "Welcome back. Your words are still here."
- **Protective framing**: "Your freeze kept your streak safe"

**After a break**:
- Show how many words are waiting
- Gentle re-entry: "Ready to pick up where you left off?"
- First session after break: extra easy cards

---

## 5. Notifications (Minimal & Respectful)

**One optional local reminder per day**:
- User chooses exact time
- Easy to turn off (in settings, always visible)
- Message style: gentle and useful
  - ✅ "Time for your Daily 5?"
  - ✅ "Your words are ready"
  - ❌ "Don't break your streak!"
  - ❌ "You're losing progress"

**No multiple pushes**
**No "streak dying" urgency**
**No guilt**

---

## 6. Relatedness & Cultural Features

### Community Audio
- **Every word** recorded by Anywaa community speakers
- **Clear credit**: Speaker name shown on every audio card
- High-quality recordings from multiple speakers (regional variations)

### Share-a-Word Card
- Optimized for WhatsApp sharing
- Contains:
  - Word in Dha Anywaa
  - English/Arabic meaning
  - Audio player
  - "Learn with Dha Anywaa" branding
- One-tap share button

### Family-Oriented Progress
- "I can now say these things" shareable summary
- Category completion badges: "I know all family words"
- Content respects Anywaa identity and culture

---

## 7. First-Session / Onboarding Wins

**First 3 minutes heavily weighted toward success**:
- Start with 3 easy, common words
- Visual + audio reinforcement
- Immediate positive feedback
- First correct answer celebrated clearly

**Milestone celebrations**:
- ✅ First correct answer: "You got your first word!"
- ✅ First session complete: "You completed your first Daily 5!"
- ✅ First streak day: "Day 1 streak started!"

**Very low friction**:
- No long tutorial
- Jump straight into learning
- Immediate feeling: "I can do this"

---

## 8. Autonomy Supports

**User controls**:
- Reminder time (or off)
- Daily target (5/10/15 cards)
- Audio on/off
- Streak freeze use (manual trigger option)

**Transparency**:
- Show why a card came back: "You struggled with this word 2 days ago"
- Show stability: "This word is getting stronger"
- Show next review: "You'll see this again in 3 days"

**No forced paths**:
- Can stop session early (partial XP awarded)
- Can skip categories
- Can review extra if desired

**Easy recovery**:
- Re-enter after break without penalty
- Streak freeze mechanics clearly explained
- No hidden controls or manipulative patterns

---

## 9. Technical / Data Rules

### Offline-first
- All core learning works offline
- Sync when online
- Audio cached locally after first play

### Injectable clock for testing
```dart
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  DateTime now() => DateTime.now();
}

class TestClock implements Clock {
  DateTime _now;
  DateTime now() => _now;
  void advance(Duration d) => _now = _now.add(d);
}
```

### Append-only review events
```dart
class ReviewEvent {
  final String cardId;
  final DateTime timestamp;
  final Rating rating;
  final Duration? responseTime;
  final double stabilityBefore;
  final double stabilityAfter;
  final double difficulty;
}
```

### Migration path from Leitner → FSRS
```dart
// Approximate stability from Leitner box level
double estimateStability(int boxLevel) {
  const boxIntervals = [0, 1, 3, 7, 14, 30];
  return boxIntervals[min(boxLevel, 5)].toDouble();
}
```

### Stable public API
```dart
// learning_engine.dart public interface
abstract class LearningEngine {
  Future<List<Card>> getDueCards();
  Future<Card?> getNextCard();
  Future<void> recordReview(String cardId, Rating rating);
  Future<SessionSummary> completeSession();
}
```

---

## 10. Ethical Guardrails (Non-Negotiable)

### No guilt
- ❌ "You broke your streak"
- ❌ "You're falling behind"
- ❌ "Don't give up now"
- ✅ "Welcome back"
- ✅ "Your words are ready"

### No fear-of-loss pressure
- No countdown timers
- No "last chance" messaging
- No artificial scarcity

### No fake urgency
- No red badges for overdue cards
- No "friends are ahead of you"
- No comparison leaderboards

### No empty gamification
- XP tied to real learning
- Levels reflect actual progress
- Badges for real milestones only

### Trust > short-term metrics
- Optimize for long-term retention
- User autonomy over engagement tricks
- Honest progress over inflated numbers

### Progress must be honest
- Never fake mastery
- Show real retention rates
- Admit when algorithm doesn't know yet

---

## Priority Order to Build

### Phase 1: Foundation (v1.5.0)
1. **FSRS engine + review logging**
   - Implement FSRS-6 algorithm
   - Card state management
   - Review event logging
   - Rating mapper (binary → FSRS)

2. **Daily 5 session builder**
   - Card selection algorithm (high early success)
   - Session state management
   - Mix new + due cards
   - Session summary

3. **Immediate progress feedback**
   - XP system
   - Level system
   - Post-review feedback messages
   - Session summary screen

### Phase 2: Habit Formation (v1.6.0)
4. **Forgiving streak + warm recovery**
   - Streak counter
   - Freeze system
   - Break recovery messaging
   - Streak protection UI

5. **One user-controlled reminder**
   - Local notification
   - Time picker
   - Easy disable
   - Gentle message copy

### Phase 3: Community & Culture (v1.7.0)
6. **Community audio credits**
   - Speaker attribution
   - Regional audio variants
   - Audio caching

7. **Share-a-word**
   - WhatsApp-optimized card
   - Audio embedding
   - One-tap share

### Phase 4: Onboarding Excellence (v1.8.0)
8. **First-session win design**
   - Easy starting cards
   - Milestone celebrations
   - Low-friction entry
   - Immediate success feeling

---

## Scientific Foundation

### Ebbinghaus Forgetting Curve (1885)
- Memory decays rapidly in first hours/days
- Steep early drop, then flattens
- Meaningful material lasts longer than nonsense
- **Key insight**: Timely review prevents decay

### SM-2 Algorithm (1987)
- First practical computer spaced repetition
- Per-item difficulty tracking (E-Factor)
- Expanding intervals based on performance
- Foundation of modern SRS software

### FSRS-6 (Modern)
- Richer memory model: Difficulty + Stability + Retrievability
- Schedules review when R drops to target (e.g. 90%)
- Fewer reviews needed for same retention vs SM-2
- Adapts to individual forgetting curves

**Why FSRS for Dha Anywaa:**
- More efficient than Leitner boxes
- Adapts to individual learners
- Open-source and well-documented
- Proven results in language learning apps

---

## Success Metrics (Ethical)

### Primary metrics:
- **Retention rate**: % of cards correctly recalled
- **Daily return rate**: % of users who complete Daily 5
- **28-day retention**: % of users still active after 28 days

### Secondary metrics:
- Average session length
- Cards reviewed per user per week
- Streak distribution (median, 90th percentile)

### What we DON'T optimize for:
- Time spent in app (we want efficient learning)
- Notification open rate (we want respect, not manipulation)
- Streak anxiety (we want protection, not pressure)

---

## Message Copy Guide

### ✅ Good Copy
- "Welcome back. Your words are still here."
- "5 words got stronger today"
- "This word is now more stable"
- "Time for your Daily 5?"
- "Your freeze kept your streak safe"

### ❌ Bad Copy
- "Don't break your streak!"
- "You're losing progress"
- "Last chance to save your streak"
- "Friends are ahead of you"
- "You forgot this word again"

**Tone**: Warm, respectful, competence-building, culturally aware

---

## File Structure (Proposed)

```
lib/
├── learning/
│   ├── fsrs_engine.dart          # FSRS-6 implementation
│   ├── card_state.dart           # Card model + state
│   ├── review_event.dart         # Review logging
│   ├── session_builder.dart      # Daily 5 logic
│   └── rating_mapper.dart        # Binary → FSRS rating
├── progress/
│   ├── xp_system.dart            # XP + Level
│   ├── streak_system.dart        # Streak + Freeze
│   └── mastery_tracker.dart      # Category mastery
├── notifications/
│   └── reminder_service.dart     # Local notifications
├── audio/
│   ├── audio_player.dart         # Community audio
│   └── audio_cache.dart          # Offline caching
└── sharing/
    └── share_card.dart           # WhatsApp share
```

---

## References

- [FSRS Algorithm](https://github.com/open-spaced-repetition/fsrs4anki/wiki/The-Algorithm)
- [Ebbinghaus (1885) - Memory: A Contribution to Experimental Psychology](https://psychclassics.yorku.ca/Ebbinghaus/memory.htm)
- [SM-2 Algorithm](https://www.supermemo.com/en/archives1990-2015/english/ol/sm2)
- [Murre & Dros (2015) - Replication of Ebbinghaus' forgetting curve](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0120644)

---

**Document Version**: 1.0  
**Last Updated**: November 2026  
**Status**: Design complete, ready for implementation
