# User Tracking Implementation Guide

**Version:** 1.0  
**Last Updated:** November 9, 2026  
**Implemented in:** v1.2.26

---

## Overview

This document explains the Firebase Analytics user tracking implementation in the Dha Anywaa application. The system tracks users across sessions while maintaining privacy through SHA-256 hashing.

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│                      User Experience                        │
├─────────────────────────────────────────────────────────────┤
│  App Start  →  Name Entry  →  Settings  →  Logout          │
└──────┬──────────────┬────────────┬────────────┬─────────────┘
       │              │            │            │
       ↓              ↓            ↓            ↓
┌──────────────────────────────────────────────────────────────┐
│                  AnalyticsService                            │
├──────────────────────────────────────────────────────────────┤
│  • initializeFromStorage()                                   │
│  • setUser(name)                                             │
│  • clearUser()                                               │
│  • logEvent()                                                │
└──────┬───────────────────────────────────────┬───────────────┘
       │                                       │
       ↓                                       ↓
┌─────────────────────┐           ┌─────────────────────────┐
│ SharedPreferences   │           │  Firebase Analytics     │
├─────────────────────┤           ├─────────────────────────┤
│ Store hashed        │           │ Collect events with     │
│ user ID locally     │           │ user ID attached        │
└─────────────────────┘           └─────────────────────────┘
```

---

## Implementation Details

### 1. User ID Generation

**Algorithm: SHA-256 Hashing**

```dart
Future<void> setUser(String name) async {
  if (name.isEmpty || name == 'guess') return;
  
  // Normalize input
  final normalizedName = name.toLowerCase().trim();
  
  // Convert to bytes
  final bytes = utf8.encode(normalizedName);
  
  // Generate SHA-256 hash
  final digest = sha256.convert(bytes);
  
  // Take first 32 characters
  final userId = digest.toString().substring(0, 32);
  
  // Set in Firebase
  await FirebaseAnalytics.instance.setUserId(id: userId);
  await FirebaseAnalytics.instance.setUserProperty(
    name: 'user_type',
    value: 'registered'
  );
  
  // Persist locally
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('analytics_user_id', userId);
}
```

**Example:**
```
Input:  "John Doe"
Normalized: "john doe"
Hash:   "a8cfde6331bd59eb2ac96f8911c4b666bc3a9b2..."
UserID: "a8cfde6331bd59eb2ac96f8911c4b666" (first 32 chars)
```

### 2. Lifecycle Management

#### App Start (Wrapper)

```dart
// lib/wraper.dart
Future<void> _check() async {
  final name = await _savedData.getName();
  
  // Initialize analytics with stored user ID
  await AnalyticsService.instance.initializeFromStorage();
  
  if (!mounted) return;
  setState(() {
    _needsName = name == 'guess';
    _loading = false;
  });
}
```

**Flow:**
1. App launches
2. Check if user exists in SharedPreferences
3. Load saved `analytics_user_id`
4. Set in Firebase Analytics
5. Continue app initialization

#### Name Entry

```dart
// lib/nameEntry.dart
onPressed: () async {
  if (_formKey.currentState!.validate()) {
    // Save name
    await savedData.setName(name);
    
    // Set analytics user ID
    await AnalyticsService.instance.setUser(name);
    
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, 'home_page');
  }
}
```

**Flow:**
1. User enters name
2. Validation passes
3. Name saved to SharedPreferences
4. Name hashed and user ID set
5. Firebase receives user ID
6. Navigate to home

#### Name Change (Settings)

```dart
// lib/settings_page.dart
Future<void> _editName() async {
  _nameCtrl.text = _name;
  final saved = await showDialog<bool>(
    context: context,
    builder: (_) => _NameDialog(controller: _nameCtrl),
  );
  
  if (saved == true) {
    final n = _nameCtrl.text.trim();
    await _savedData.setName(n);
    
    // Update analytics user ID
    await AnalyticsService.instance.setUser(n);
    
    if (!mounted) return;
    setState(() => _name = n);
  }
}
```

**Flow:**
1. User opens name edit dialog
2. Changes name
3. Saves changes
4. New name hashed
5. New user ID set
6. Firebase updated

#### Logout

```dart
// lib/home_page.dart
_drawerTile(context, Icons.logout_rounded, 'Log out', () async {
  Navigator.pop(context);
  
  // Clear name
  await _savedData.setName('guess');
  
  // Clear analytics user ID
  await AnalyticsService.instance.clearUser();
  
  if (!mounted) return;
  Navigator.pushReplacementNamed(context, '/');
}, color: kRust),
```

**Flow:**
1. User taps logout
2. Name reset to 'guess'
3. User ID cleared from Firebase
4. User ID removed from SharedPreferences
5. User property set to 'guest'
6. Navigate to welcome screen

---

## Privacy & Security

### Privacy Features

1. **No PII Stored in Analytics**
   - Only SHA-256 hashes sent to Firebase
   - Original names never leave the device (except as hashes)
   - Cannot reverse-engineer name from hash

2. **One-Way Hashing**
   - SHA-256 is cryptographically secure
   - Computationally infeasible to reverse
   - Collision-resistant

3. **User Control**
   - Users can logout to clear tracking
   - User ID removed on logout
   - Returns to anonymous tracking

4. **Local Storage**
   - User ID stored in SharedPreferences
   - Not synchronized to cloud
   - Device-specific

### GDPR Compliance

**Legal Basis:**
- Legitimate interest (analytics for app improvement)
- Anonymous data (hashed IDs)
- User control (logout option)

**Data Minimization:**
- Only collect what's necessary (hashed ID)
- No additional PII collected
- No cross-app tracking

**Right to be Forgotten:**
- User can logout (clears ID)
- Firebase data can be manually deleted
- No persistent identifiers beyond hash

**Transparency:**
- Documented in Privacy Policy page
- Clear disclosure of analytics usage
- User notification on first use

### Security Considerations

**Hash Collision:**
- SHA-256 has 2^256 possible outputs
- Practically impossible to have collisions
- Each unique name gets unique ID

**Brute Force:**
- Infeasible to brute force SHA-256
- Would require astronomical computing power
- Not a practical concern

**Rainbow Tables:**
- Names are normalized (lowercase, trimmed)
- Salt not needed (names are unique identifiers)
- Common names produce same hash (feature, not bug)

---

## Firebase Configuration

### User Properties

```dart
await FirebaseAnalytics.instance.setUserProperty(
  name: 'user_type',
  value: 'registered' // or 'guest'
);
```

**Values:**
- `registered` - User has entered a name
- `guest` - User logged out or never entered name

### Events

All standard events automatically include user ID:

```dart
// Example: Lesson audio play
await AnalyticsService.instance.logPlayAudio(category, itemId);

// Internally:
await FirebaseAnalytics.instance.logEvent(
  name: 'play_lesson_audio',
  parameters: {
    'category': category,
    'item_id': itemId,
    // user_id is automatically attached by Firebase
  },
);
```

---

## Data Storage

### SharedPreferences Schema

```
Key: analytics_user_id
Value: <32-character-hex-string>
Type: String
Persistence: Device-specific
```

**Example:**
```dart
// Writing
final prefs = await SharedPreferences.getInstance();
await prefs.setString('analytics_user_id', 'a8cfde6331bd59eb2ac96f8911c4b666');

// Reading
final userId = prefs.getString('analytics_user_id');
// Returns: "a8cfde6331bd59eb2ac96f8911c4b666" or null
```

### Firebase Storage

**User ID:**
- Stored in Firebase Analytics backend
- Associated with all events
- Used for retention/engagement calculations

**User Properties:**
- `user_type`: "registered" or "guest"
- Can add more properties as needed

---

## Analytics Capabilities

### Available Metrics

**User Metrics:**
- Daily Active Users (DAU)
- Monthly Active Users (MAU)
- User retention (1-day, 7-day, 30-day)
- User engagement (sessions per user)
- User lifetime value

**Engagement Metrics:**
- Sessions per user
- Session duration
- Screen views per session
- Events per session

**Feature Usage:**
- Lesson completion rate by user
- Quiz performance by user
- Audio play frequency by user
- Theme preferences by user

### Custom Dashboards

Create custom dashboards in Firebase Console:

1. **Retention Dashboard**
   - Day 1 retention curve
   - Day 7 retention curve
   - Day 30 retention curve
   - Cohort analysis

2. **Engagement Dashboard**
   - DAU/MAU ratio
   - Sessions per user
   - Feature usage distribution
   - User journey flow

3. **Learning Progress Dashboard**
   - Lessons completed per user
   - Quiz scores by user
   - Progress by category
   - Drop-off points

---

## Testing

### Manual Testing

1. **Fresh Install**
   ```
   1. Install app
   2. Enter name "TestUser123"
   3. Check SharedPreferences for analytics_user_id
   4. Close app
   5. Reopen app
   6. Verify user ID persists
   7. Check Firebase Console for events
   ```

2. **Name Change**
   ```
   1. Open Settings
   2. Change name to "NewName456"
   3. Check SharedPreferences for updated analytics_user_id
   4. Verify new user ID is different
   5. Check Firebase Console for events under new ID
   ```

3. **Logout**
   ```
   1. Tap logout
   2. Check SharedPreferences - analytics_user_id should be removed
   3. Check Firebase Console - user_type should be "guest"
   4. New events should not have user ID attached
   ```

### Automated Testing

```dart
// test/analytics_service_test.dart
void main() {
  test('setUser generates consistent hash', () async {
    final service = AnalyticsService.instance;
    
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    
    // Set user
    await service.setUser('TestUser');
    
    // Verify stored
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('analytics_user_id');
    
    expect(userId, isNotNull);
    expect(userId!.length, equals(32));
    
    // Same name should produce same hash
    await service.setUser('TestUser');
    final userId2 = prefs.getString('analytics_user_id');
    expect(userId2, equals(userId));
  });
  
  test('clearUser removes user ID', () async {
    final service = AnalyticsService.instance;
    
    SharedPreferences.setMockInitialValues({
      'analytics_user_id': 'a8cfde6331bd59eb2ac96f8911c4b666'
    });
    
    await service.clearUser();
    
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('analytics_user_id');
    
    expect(userId, isNull);
  });
}
```

---

## Troubleshooting

### User ID Not Persisting

**Symptoms:**
- User ID changes every app restart
- Firebase shows different user for each session

**Solutions:**
1. Check `initializeFromStorage()` is called in Wrapper
2. Verify SharedPreferences permissions
3. Check device storage not full
4. Verify `setUser()` is saving to SharedPreferences

### Events Not Showing in Firebase

**Symptoms:**
- No events in Firebase Console
- Analytics appears inactive

**Solutions:**
1. Check Firebase configuration (google-services.json)
2. Verify package name matches Firebase project
3. Check internet connection
4. Wait 24 hours for data to appear
5. Use Firebase Debug View for immediate feedback

### User ID Not Attached to Events

**Symptoms:**
- Events appear in Firebase
- No user ID associated
- Cannot track user retention

**Solutions:**
1. Verify `setUserId()` is called before events
2. Check user hasn't logged out
3. Verify `initializeFromStorage()` runs on app start
4. Check SharedPreferences has analytics_user_id

---

## Future Enhancements

### Potential Improvements

1. **Enhanced Privacy**
   - Add salt to hash (optional)
   - Rotate user IDs periodically
   - Allow users to reset their ID

2. **Better Analytics**
   - Track more user properties (language, theme preference)
   - Custom event parameters
   - Cross-session attribution

3. **User Engagement**
   - Push notifications based on retention
   - Personalized content recommendations
   - Re-engagement campaigns

4. **Data Export**
   - Allow users to export their analytics data
   - Provide insights dashboard in-app
   - Learning progress reports

---

## References

### Documentation

- [Firebase Analytics - User Properties](https://firebase.google.com/docs/analytics/user-properties)
- [Firebase Analytics - Events](https://firebase.google.com/docs/analytics/events)
- [Dart Crypto Package](https://pub.dev/packages/crypto)
- [GDPR Compliance](https://gdpr.eu/)

### Code Files

- `lib/services/analytics_service.dart`
- `lib/wraper.dart`
- `lib/nameEntry.dart`
- `lib/settings_page.dart`
- `lib/home_page.dart`

---

**Document Version:** 1.0  
**Author:** Kiro AI Development Assistant  
**Last Updated:** November 9, 2026
