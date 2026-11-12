# Reminder System Fixes - v1.4.9

## Issues Found and Fixed

### 1. Date Calculation Bug (CRITICAL)
**Problem**: `_timeUntilTomorrow()` used `DateTime(now.year, now.month, now.day + 1, targetHour)` which breaks at month boundaries (e.g., Jan 31 + 1 = crash).

**Fix**: Changed to use `now.add(const Duration(days: 1))` for proper date handling.

```dart
// Before (BROKEN at month boundaries)
final tomorrow = DateTime(now.year, now.month, now.day + 1, targetHour);

// After (FIXED)
final tomorrow = now.add(const Duration(days: 1));
final targetTime = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, targetHour);
```

### 2. Missing Exact Alarm Permissions (Android 12+)
**Problem**: Android 12+ requires explicit permission to schedule exact alarms. Without it, notifications don't fire.

**Fix**: Added permissions to AndroidManifest.xml:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

### 3. Permission Request Logic
**Problem**: Only requested POST_NOTIFICATIONS, not SCHEDULE_EXACT_ALARM.

**Fix**: Updated `requestPermission()` to request both:
```dart
final notificationPermission = await androidImpl.requestNotificationsPermission();
final exactAlarmPermission = await androidImpl.requestExactAlarmsPermission();
return (notificationPermission ?? false) && (exactAlarmPermission ?? true);
```

### 4. Toggle UI State Bug
**Problem**: When user toggles notifications ON, the UI updated immediately even if permission was denied. Switch showed ON but notifications didn't work.

**Fix**: Only update UI after confirming permission:
```dart
if (enabled) {
  // Request permission first
  final permissionGranted = await RetentionEngine.instance.requestPermission();
  
  if (!permissionGranted) {
    _toast('Please enable notifications in Settings');
    return; // Don't update UI state
  }
  
  await RetentionEngine.instance.enableNotifications(preferredHour: _reminderHour);
  setState(() => _notificationsEnabled = true); // Only update if successful
  _toast('Daily reminders enabled');
}
```

### 5. No User Feedback
**Problem**: User had no idea if toggle worked or failed.

**Fix**: Added toast messages:
- "Daily reminders enabled" on success
- "Daily reminders disabled" when turned off
- "Please enable notifications in Settings" on permission denial
- "Reminder set for 7:00 PM" when time changed

### 6. Time Picker Permission Bug
**Problem**: User could change time even if they had denied permission earlier. This would silently fail.

**Fix**: Re-request permission when changing time:
```dart
Future<void> _pickReminderTime() async {
  final picked = await showTimePicker(...);
  if (picked != null && mounted) {
    // Re-check permission
    final permissionGranted = await RetentionEngine.instance.requestPermission();
    if (!permissionGranted) {
      _toast('Please enable notifications in Settings');
      return;
    }
    // ... rest of logic
  }
}
```

### 7. Share Link Issue
**Problem**: Share helper included netlify website link. User requested GitHub APK only.

**Fix**: Removed `_website` constant and netlify link from all share messages. Updated APK URL to v1.4.9.

## Testing Checklist

### On Physical Device (Android):
1. Open Settings > Daily reminder toggle
2. Toggle ON → should show permission dialog
3. Grant permission → should show "Daily reminders enabled" toast
4. Close app completely
5. Wait for scheduled time → notification should fire
6. Toggle OFF → should show "Daily reminders disabled" toast
7. Change reminder time → should re-request permission if needed

### Edge Cases:
- Toggle ON → Deny permission → Switch should stay OFF
- Toggle ON → Grant permission → Toggle OFF → Toggle ON again (should not re-prompt if already granted)
- Change time without toggling (if notifications already enabled)
- Test at month boundary (set device date to Jan 31, then wait for Feb 1)

### Android Versions:
- Android 11 and below: Only POST_NOTIFICATIONS needed
- Android 12+: SCHEDULE_EXACT_ALARM needed
- Android 13+: POST_NOTIFICATIONS runtime permission needed

## What Users Need to Do

If notifications still don't work after toggling ON in the app, users need to manually enable in Android Settings:

1. Open Android Settings
2. Go to Apps > Learn Dha Anywaa
3. Tap Notifications → Enable "All Learn Dha Anywaa notifications"
4. Tap "Alarms & reminders" → Enable

This is required on some Android 12+ devices that restrict exact alarms by default.
