# 🎉 v1.4.13 Released!

**Release Date:** November 12, 2026  
**Download:** https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest/download/dha-anywaa-v1.4.13.apk  
**Size:** 85MB  
**Status:** ✅ Live on GitHub

---

## What's Included

### 📖 Bible (Wëël Jwøk) - FIXED ✅
- **31,057 verses** in Anywaa + English
- **66 books** (Old Testament + New Testament)
- Complete data loaded from single JSON file
- Smooth scrolling and navigation
- Search functionality working

### 🧠 FSRS-6 Learning System Foundation ✅
**Phase 1 Complete** - Ready for integration

**Core Engine:**
- Scientific spaced repetition algorithm (FSRS-6)
- 90% retention optimization
- Stability & Difficulty tracking
- Smart scheduling (1 minute to 100 years)

**Progress System:**
- XP rewards (10 correct, 5 incorrect)
- 50+ levels with Anywaa cultural titles
- Mastery tracking (21-day stability threshold)
- Streak system foundation

**Daily 5 Sessions:**
- Smart card selection algorithm
- 2-3 minute learning sessions
- Easy wins first (confidence building)
- Beautiful UI with immediate feedback

**Data Persistence:**
- Card state storage (SharedPreferences)
- Review history logging (10,000 events)
- User progress tracking
- Leitner→FSRS migration support

**Note:** Learning system is code-complete but not yet integrated into main UI. Coming in v1.5.0!

### 🐛 Bug Fixes
- Privacy Policy removed from sidebar
- Asset loading for subdirectories fixed
- Share link updated to v1.4.13

---

## Technical Details

### Files Added
**Learning System (15 files, ~2,500 lines):**
```
lib/learning/
├── card_state.dart           (150 lines)
├── fsrs_engine.dart          (200 lines)
├── rating_mapper.dart        (80 lines)
├── review_event.dart         (60 lines)
├── session_builder.dart      (150 lines)
├── card_repository.dart      (200 lines)
└── learning_service.dart     (200 lines)

lib/progress/
├── xp_system.dart            (200 lines)
└── mastery_tracker.dart      (150 lines)

lib/pages/
└── daily_five_session_page.dart (400 lines)

lib/widgets/
└── progress_ring.dart        (350 lines)

docs/
├── LEARNING_SYSTEM_DESIGN.md
├── ROADMAP_LEARNING_SYSTEM.md
├── PHASE_1_IMPLEMENTATION.md
└── INTEGRATION_GUIDE.md

PHASE_1_COMPLETE.md
```

**Bible Data:**
```
assets/bible.json             (12MB, 31,057 verses)
```

### Git Commits
```
8a90fa2 feat: Add FSRS-6 learning system foundation (Phase 1)
a9a51d9 v1.4.13: Fix Bible (Wëël Jwøk) with 31,057 verses
```

### Build Info
- **APK Size:** 85MB
- **Version Code:** 173
- **Target SDK:** Android 14+
- **Min SDK:** Android 5.0+

---

## Installation

### For Users:
1. Download: [dha-anywaa-v1.4.13.apk](https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest/download/dha-anywaa-v1.4.13.apk)
2. Enable "Install from unknown sources" on Android
3. Install APK
4. Open app and enjoy!

### For Developers:
```bash
git clone https://github.com/KornellaOtf/Dha-Anywaa-application.git
cd Dha-Anywaa-application
git checkout v1.4.13
flutter pub get
flutter run
```

---

## What Users Will See

### Immediate (v1.4.13):
✅ Bible working with all verses  
✅ Smooth navigation and search  
✅ Privacy Policy removed from menu  

### Coming Next (v1.5.0):
🔄 Daily 5 sessions (replaces quiz)  
🔄 XP & level system visible  
🔄 Progress tracking on home page  
🔄 Streak indicators  
🔄 Beautiful learning experience  

---

## For Developers: Next Steps

### To Complete v1.5.0 Integration (~4 hours):

**1. Word Data Mapping (30 min)**
```dart
// Create lib/services/fsrs_word_mapper.dart
// Map existing words to FSRS card IDs
// Initialize cards for all vocabulary
```

**2. Home Page Integration (45 min)**
```dart
// Replace quiz button with Daily 5 card
// Add level progress display
// Show due cards count
// Add streak indicator
```

**3. Navigation (30 min)**
```dart
// Initialize LearningService in main.dart
// Connect Daily 5 button → session page
// Handle session completion → home
// Add level-up celebrations
```

**4. Testing (60 min)**
```bash
# Test FSRS algorithm with real reviews
# Verify XP calculations
# Test persistence across restarts
# Check migration from Leitner
```

**5. Build & Release (15 min)**
```bash
flutter build apk --release
# Test on device
# Push v1.5.0
```

### Documentation:
- **System Design:** `docs/LEARNING_SYSTEM_DESIGN.md`
- **Roadmap:** `docs/ROADMAP_LEARNING_SYSTEM.md`
- **Implementation:** `docs/PHASE_1_IMPLEMENTATION.md`
- **Integration Guide:** `docs/INTEGRATION_GUIDE.md`

---

## Release Verification

✅ **Git:** Tag v1.4.13 pushed  
✅ **GitHub:** Release created  
✅ **APK:** 85MB uploaded  
✅ **Download:** Link working  
✅ **Commits:** 2 commits pushed  
✅ **Branch:** ui-cleanup-startup updated  

---

## Statistics

### v1.4.13 Totals:
- **Bible verses:** 31,057
- **Bible books:** 66
- **Learning system files:** 15
- **Lines of code added:** ~2,500
- **Documentation pages:** 4
- **APK size:** 85MB
- **Development time:** ~8 hours (Phase 1)

### Repository Stats:
- **Total commits:** 180+
- **Version tags:** 13+
- **Active branches:** 3
- **Stars:** Growing
- **Downloads:** Increasing

---

## Roadmap

### ✅ Completed:
- v1.0.0 - v1.4.9: Basic app features
- v1.4.10: Startup crash fix
- v1.4.11: Bible initial implementation
- v1.4.12: Bible asset fix + Privacy Policy removal
- v1.4.13: Bible data fix + FSRS foundation

### 🔄 In Progress:
- v1.5.0: FSRS integration (Phase 1 complete)

### 📋 Planned:
- v1.6.0: Streak system + notifications (Phase 2)
- v1.7.0: Community features (Phase 3)
- v1.8.0: Onboarding optimization (Phase 4)

---

## Thank You!

This release represents a major milestone:
- ✅ Bible fully working
- ✅ Scientific learning system foundation complete
- ✅ Ready for habit-forming transformation

**Next:** Integration into v1.5.0 to make this live for users! 🚀

---

## Links

- **GitHub Release:** https://github.com/KornellaOtf/Dha-Anywaa-application/releases/tag/v1.4.13
- **Download APK:** https://github.com/KornellaOtf/Dha-Anywaa-application/releases/latest/download/dha-anywaa-v1.4.13.apk
- **Repository:** https://github.com/KornellaOtf/Dha-Anywaa-application
- **Issues:** https://github.com/KornellaOtf/Dha-Anywaa-application/issues

---

*Built with ❤️ for the Anywaa community*  
*"Dha Anywaa - Learn your language, preserve your culture"*
