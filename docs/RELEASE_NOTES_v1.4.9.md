# Release Notes - v1.4.9 (build 169)

Released: 2026-11-11
Branch: ui-cleanup-startup
Tag: v1.4.9

## Download

- APK: 86.2MB
- SHA256: `05d755f43665fbfb6bee06077f138ee115bf065ba963a5fc105838647c9a747d`
- URL: https://github.com/KornellaOtf/Dha-Anywaa-application/releases/download/v1.4.9/dha-anywaa-v1.4.9.apk

## What's New

### 1. Redesigned Welcome Screen (NameEntry)

The first screen users see has been completely redesigned:

- Gradient hero section with brand logo glow effect
- 3 feature pills: Audio, Offline, Quizzes (quick value proposition)
- Cleaner single-column form layout (replaced verbose two-section layout)
- Removed unnecessary spacing and old header band

### 2. Redesigned Quit Quiz Dialog

When a user tries to leave a quiz in progress:

- Side-by-side "Quit" and "Keep going" buttons (was stacked vertically)
- Pause icon instead of running person icon
- Calmer tone: "Take a break?" instead of "Quit the quiz?"
- Less warning-heavy, more encouraging

### 3. Daily 5 Now Works

Previously showed "coming soon" message. Now fully functional:

- Connected to 38 real vocabulary words via WordAggregator service
- Categories included: Animals (14), Birds (12), Colors (8), Shapes (4)
- Uses LearningEngine spaced repetition (Leitner box model)
- Mix of due (60%), weak (30%), and new (10%) words each session
- Picture-to-word format: shows image, user picks the correct Anywaa word
- XP rewards: 10 XP per correct answer, combo bonus at 3+ in a row
- Wrong answer dynamically generated from other words in the pool
- Session summary: words reviewed, XP earned, best combo
- Image error fallback shows placeholder icon if asset missing

### 4. Home Screen Shortcuts (App Shortcuts)

Long-press the app icon on the Android home screen to see shortcuts:

- "Take a Quiz" - opens quiz page directly
- "Ask Anywaa AI" - opens AI assistant directly
- "Share App" - triggers native share dialog

Implementation:
- Dynamic shortcuts via quick_actions package (set at app startup)
- Static shortcuts via shortcuts.xml for instant native display
- Navigator key added to MaterialApp for shortcut routing
- String resources in strings.xml for shortcut labels

### 5. Reminder System Fixes

Fixed multiple bugs in the notification/reminder system:

#### Critical: Date Calculation Bug
- `_timeUntilTomorrow()` used `DateTime(now.year, now.month, now.day + 1, targetHour)`
- This crashes at month boundaries (Jan 31 + 1 = Jan 32 = invalid)
- Fixed: uses `now.add(Duration(days: 1))` then extracts year/month/day

#### Critical: Missing Android 12+ Permissions
- Android 12+ requires SCHEDULE_EXACT_ALARM permission
- Without it, notifications don't fire when phone is in Doze mode
- Added SCHEDULE_EXACT_ALARM and USE_EXACT_ALARM to AndroidManifest.xml
- requestPermission() now requests both notification and exact alarm permissions

#### Toggle ON/OFF State Desync
- Switch showed ON even when permission was denied
- Now: only updates UI state after confirming permission granted
- If denied: switch stays OFF, shows "Please enable notifications in Settings" toast

#### No User Feedback
- Added toast messages for all toggle actions:
  - "Daily reminders enabled" (on success)
  - "Daily reminders disabled" (when turned off)
  - "Please enable notifications in Settings" (on denial)
  - "Reminder set for 7:00 PM" (when time changed)

#### Time Picker Permission Leak
- User could change reminder time without having notification permission
- Now re-requests permission before applying the new time

### 6. Share Link Updated

- APK URL in share_helper.dart updated from v1.4.8 to v1.4.9
- Netlify website link completely removed (GitHub APK only, per user request)

## Files Changed

### New Files
- `lib/services/word_aggregator.dart` - Unified word data model and aggregator
- `android/app/src/main/res/xml/shortcuts.xml` - Static app shortcuts
- `android/app/src/main/res/values/strings.xml` - Shortcut label strings
- `docs/RELEASE_NOTES_v1.4.9.md` - This file
- `REMINDER_FIXES.md` - Detailed reminder fix documentation

### Modified Files
- `lib/main.dart` - QuickActions initialization, MyApp converted to StatefulWidget
- `lib/home_page.dart` - Daily 5 navigation connected to WordAggregator, imports added
- `lib/settings_page.dart` - Toggle permission checks, toast feedback, time picker fix
- `lib/services/retention_engine.dart` - Date calculation fix, permission request fix, canScheduleExactAlarms method
- `lib/services/share_helper.dart` - APK URL updated to v1.4.9
- `lib/pages/daily_five_page.dart` - Removed duplicate WordData, import unified model, field name fixes, wrong choice generation
- `lib/nameEntry.dart` - Welcome screen redesign
- `lib/pages/page4.dart` - Quit quiz dialog redesign
- `android/app/src/main/AndroidManifest.xml` - Exact alarm permissions, shortcuts meta-data
- `pubspec.yaml` - Added quick_actions ^1.0.8
- `manifest.json` - Updated to v1.4.9

## Dependencies Added
- `quick_actions: ^1.0.8` (with quick_actions_android, quick_actions_ios, quick_actions_platform_interface)

## Testing Checklist

### Welcome Screen
- [ ] App opens to redesigned welcome screen
- [ ] Gradient hero with logo glow is visible
- [ ] 3 feature pills show: Audio, Offline, Quizzes
- [ ] Form is single column, no extra spacing
- [ ] "Get started" button works

### Quit Quiz Dialog
- [ ] Start a quiz, press back
- [ ] Dialog shows "Take a break?" with pause icon
- [ ] Two buttons side-by-side: Quit and Keep going
- [ ] Quit exits the quiz
- [ ] Keep going returns to quiz

### Daily 5
- [ ] Tap Daily 5 pill on home screen
- [ ] Opens Daily Five page (not "coming soon" message)
- [ ] Shows 5 questions with images
- [ ] Tap correct answer -> green feedback, XP awarded
- [ ] Tap wrong answer -> red feedback, shows correct word
- [ ] Combo counter appears at 3+ correct
- [ ] After 5 questions -> session summary with stats
- [ ] Tap Continue -> returns to home

### Home Screen Shortcuts
- [ ] Long-press app icon on home screen
- [ ] Menu shows: Take a Quiz, Ask Anywaa AI, Share App
- [ ] Tap "Take a Quiz" -> opens quiz directly
- [ ] Tap "Ask Anywaa AI" -> opens AI page directly
- [ ] Tap "Share App" -> opens native share dialog

### Reminder Toggle
- [ ] Go to Settings > Daily reminder
- [ ] Toggle ON -> permission dialog appears
- [ ] Grant permission -> "Daily reminders enabled" toast, switch shows ON
- [ ] Toggle OFF -> "Daily reminders disabled" toast, switch shows OFF
- [ ] Toggle ON -> Deny permission -> switch stays OFF, "Please enable notifications in Settings" toast
- [ ] Tap reminder time -> time picker opens
- [ ] Change time -> "Reminder set for X:00 PM" toast

### Share
- [ ] Open drawer -> tap "Share Dha Anywaa" -> native share sheet
- [ ] Go to Settings -> tap "Invite a Friend" -> native share sheet
- [ ] Share message contains GitHub APK link only (no netlify)
- [ ] Link points to v1.4.9

## Notes for Users

If notifications still don't work after toggling ON in the app, users may need to manually enable in Android Settings:

1. Open Android Settings
2. Go to Apps > Learn Dha Anywaa
3. Tap Notifications -> Enable "All Learn Dha Anywaa notifications"
4. Tap "Alarms & reminders" -> Enable

This is required on some Android 12+ devices that restrict exact alarms by default.
