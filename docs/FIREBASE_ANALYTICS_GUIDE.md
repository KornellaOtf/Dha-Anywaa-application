# Firebase Analytics Guide — Dha Anywaa App

**Last Updated:** November 9, 2026
**Implemented from:** v1.2.26 (user tracking), v1.2.27 (events)

---

## Overview

Firebase Analytics is integrated into the app to track how users interact with it. This document explains what is tracked, where to find the data, and how to interpret it.

---

## Firebase Console Access

**URL:** https://console.firebase.google.com/project/learn-dha-anywaa/analytics/overview

**Account:** kornellaotf@gmail.com

---

## What Is Tracked

### User Identity

Every user gets a stable, anonymous ID derived from their name:

```
"John" → SHA-256 hash → "a8cfde6331bd59eb2ac96f8911c4b666"
```

- The original name is never sent to Firebase
- Same name always produces the same ID (consistent tracking across sessions)
- Logging out clears the ID

This means Firebase can tell "this is the same person as yesterday" without knowing who they are.

### User Properties

| Property | Values | Set When |
|---|---|---|
| `user_type` | `registered` / `guest` | Name entered / logout |

---

## Events Reference

### Learning Events

#### `play_lesson_audio`
Fired every time a user taps the play button in a lesson.

| Parameter | Type | Example |
|---|---|---|
| `category` | string | `"alphabet"`, `"animal"`, `"numbers"` |
| `item_id` | string | `"A"`, `"Cow"`, `"3"` |

**Where it fires:**
- Alphabet screen (page1.dart) — per letter
- All vocabulary screens via DetailScreen (detail_screen.dart) — per word

---

#### `complete_lesson`
Fired when a user taps "Mark as learned" on a word or letter.

| Parameter | Type | Example |
|---|---|---|
| `category` | string | `"alphabet"`, `"animal"` |
| `item_id` | string | `"B"`, `"Lion"` |

**Note:** Only fires when marking AS learned, not when unmarking.

---

#### `finish_quiz`
Fired when the quiz ends and the result screen appears.

| Parameter | Type | Example |
|---|---|---|
| `score` | int | `24` |
| `total` | int | `31` |

**Use this to see:** average quiz scores, how many users finish the quiz, score distribution.

---

### App Update Events

#### `check_update`
Fired every time the app checks for an OTA update.

| Parameter | Type | Example |
|---|---|---|
| `forced` | int | `1` (manual check), `0` (automatic) |

---

#### `download_update`
Fired when an OTA APK finishes downloading and passes verification.

| Parameter | Type | Example |
|---|---|---|
| `from_version` | string | `"1.2.26"` |
| `to_version` | string | `"1.2.27"` |

---

#### `install_update`
Fired when the user taps the Install button (before Android installer opens).

| Parameter | Type | Example |
|---|---|---|
| `to_version` | string | `"1.2.27"` |

---

### Settings Events

#### `change_theme`
Fired when user changes the app theme.

| Parameter | Type | Example |
|---|---|---|
| `mode` | string | `"dark"`, `"light"`, `"system"` |

---

#### `toggle_sound`
Fired when user toggles sound on or off.

| Parameter | Type | Example |
|---|---|---|
| `enabled` | int | `1` (on), `0` (off) |

---

### Automatic Events (Firebase Built-in)

These fire automatically without any code — provided by `FirebaseAnalyticsObserver`:

| Event | What it tracks |
|---|---|
| `screen_view` | Every screen the user visits |
| `session_start` | Each new app session |
| `first_open` | First time app is launched after install |
| `app_update` | When user opens app after updating |
| `os_update` | When user updates their Android OS |

---

## Where to Find Each Metric in Firebase Console

### How many people use the app

**Analytics → Dashboard**

- **Daily Active Users (DAU):** Number of unique users per day
- **Monthly Active Users (MAU):** Unique users in the last 30 days
- **Active users right now:** Bottom of the dashboard, real-time
- **Top countries:** Which countries users are in (Kenya expected)

---

### What users are doing

**Analytics → Events**

Lists all events with total count. Click any event to see:
- Event count over time
- Parameter breakdown (e.g. which categories get most audio plays)
- User count vs event count

**Most useful views:**
- `play_lesson_audio` → see which categories/words are most popular
- `finish_quiz` → see quiz scores distribution
- `complete_lesson` → see learning progress
- `screen_view` → see which screens users visit most

---

### Are users coming back?

**Analytics → Retention**

Shows what percentage of users return after their first session:
- Day 1 retention (came back the next day)
- Day 7 retention
- Day 30 retention

A healthy language learning app should aim for:
- Day 1: 30-50%
- Day 7: 15-25%
- Day 30: 8-15%

---

### User cohorts

**Analytics → Audiences**

You can create audience segments, e.g.:
- Users who completed at least 10 lessons
- Users who finished the quiz
- Users who changed theme (engaged users)

---

### Which version users are on

**App Distribution → Releases**

Shows each release with:
- Number of users on that version
- Download count
- Release date

This is how you track migration from v1.2.26 to v1.2.27+.

---

### Crashes

**Crashlytics** (left sidebar)

If the app crashes on any device:
- Full stack trace
- Device model and OS version
- How many users affected
- Whether it's a new or recurring issue

---

## Data Delay

Firebase Analytics has a processing delay:

| Data type | Delay |
|---|---|
| Real-time active users | Instant |
| Event counts | Up to 24 hours |
| Retention curves | Up to 48 hours |
| User properties | Up to 24 hours |

Don't worry if you don't see events immediately after a user installs the app.

---

## Privacy

- No personally identifiable information (PII) is sent to Firebase
- User names are SHA-256 hashed before being used as IDs
- Users can clear their ID by logging out
- Compliant with GDPR (anonymous data, user control)

See `docs/USER_TRACKING_IMPLEMENTATION.md` for full technical details.

---

## Useful Firebase Console Bookmarks

| What | URL |
|---|---|
| Analytics overview | https://console.firebase.google.com/project/learn-dha-anywaa/analytics/overview |
| Events list | https://console.firebase.google.com/project/learn-dha-anywaa/analytics/events |
| Retention | https://console.firebase.google.com/project/learn-dha-anywaa/analytics/retention |
| App Distribution | https://console.firebase.google.com/project/learn-dha-anywaa/appdistribution |
| Crashlytics | https://console.firebase.google.com/project/learn-dha-anywaa/crashlytics |
| Realtime | https://console.firebase.google.com/project/learn-dha-anywaa/analytics/realtime |

---

## Adding New Events

To track something new, add a method to `lib/services/analytics_service.dart`:

```dart
Future<void> logNewEvent(String param) => _fa.logEvent(
  name: 'my_event_name',
  parameters: {'param': param},
);
```

Then call it in the relevant UI file:

```dart
AnalyticsService.instance.logNewEvent('value');
```

Event names must be:
- Lowercase with underscores
- Max 40 characters
- No spaces or special characters

---

**Document Version:** 1.0
**Last Updated:** November 9, 2026
