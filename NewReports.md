# Dha Anywaa application audit report

Date: 2026-11-13  
Scope: source, Android configuration, Firebase Analytics configuration, tests,
documentation, and release-adjacent project configuration. OTA implementation
is intentionally excluded from the findings at the owner's request.

## Executive summary

The app has a strong offline-first foundation and a substantial vocabulary/data
set. The main engineering risk is **duplication**: two learning/FSRS systems
and two XP/streak systems coexist, but only one of each is connected to the
main Daily 5 experience. This causes inconsistent progression, inaccurate XP
shown to learners, and unfinished code paths. The next priorities are to
consolidate progress into one system, correct Firebase Analytics event names,
repair notification/retention behavior, and update the privacy/documentation
claims.

## High-priority defects

### 1. Daily 5 awards and displays different XP values

**Location:** `lib/pages/daily_five_page.dart`, `_onAnswer()` and
`_finishSession()`.

The page calculates its own per-card XP (`2` for a correct answer, `1` for an
incorrect answer, plus combo values) and displays that amount. It then calls
`GamificationService.onLessonComplete()`, which awards a separate fixed `5`
XP, regardless of whether the answer was correct. At session completion it
also calls `onQuizFinish()`, adding another quiz-style reward.

**Impact:** displayed XP, stored XP, daily goal progress, level progress, and
analytics can disagree. Repeating Daily 5 can also earn rewards intended for
whole lessons and quizzes.

**Recommended fix:** create one `completeDailyFive()` operation in the single
progress service. Pass the session results to it once, calculate the final
award there, persist it transactionally, and use the returned award in the
summary and analytics. Do not use lesson or quiz reward APIs for a Daily 5
session.

### 2. Two incompatible spaced-repetition and progress systems exist

**Locations:**

- Active flow: `lib/services/learning_engine.dart` and
  `lib/services/gamification_service.dart`
- Dormant parallel flow: `lib/learning/learning_service.dart`,
  `lib/learning/card_repository.dart`, `lib/progress/xp_system.dart`, and
  `lib/progress/mastery_tracker.dart`

The active Daily 5 page records cards under `fsrs_word_states_v1`. The newer
`LearningService` stores a separate set of cards, reviews, and XP under other
keys. These systems calculate levels and streaks differently. The newer
`DailyFiveSessionPage` still uses `Placeholder` / `Translation` rather than
real vocabulary data.

**Impact:** progress can split across stores, a future screen can show a level
or mastery count that conflicts with the home screen, and changes to one FSRS
implementation do not affect the other.

**Recommended fix:** select one card model, one scheduler, and one progress
store. Migrate existing `fsrs_word_states_v1` data once; delete or fully wire
the unused implementation only after migration. Make Daily 5 use the same
service that provides mastery, due counts, XP, and streaks.

### 3. Comeback-bonus eligibility is race-prone and not consumed explicitly

**Locations:** `lib/home_page.dart`, `_checkComebackBonus()`;
`lib/services/retention_engine.dart`, `onAppOpen()` and `claimComebackBonus()`.

`HomePage.initState()` starts `onAppOpen()` and `_checkComebackBonus()` without
awaiting either. `onAppOpen()` writes the latest-open timestamp, while the
bonus check reads that same value. Depending on timing, a valid bonus can be
lost or evaluated against stale data. `claimComebackBonus()` writes
`retention_comeback_eligible`, but no code reads that key to prevent reuse.

**Recommended fix:** expose one atomic `recordOpenAndClaimComebackBonus()`
method that reads eligibility, records the open time, records a claim, and
returns the result. The UI should call only that method once.

### 4. Firebase drops the custom `app_update` event

**Location:** `lib/services/analytics_service.dart`, `logAppUpdate()`.

`app_update` is a reserved Firebase Analytics event name. Custom events using
reserved names are dropped rather than reported.

**Recommended fix:** rename it to an app-specific custom event such as
`update_download_started`, then update dashboards and documentation.

Reference: [Firebase Analytics event names](https://firebase.google.com/docs/reference/android/com/google/firebase/analytics/FirebaseAnalytics.Event).

## Medium-priority defects

### 5. Daily reminder time can be scheduled in UTC, not the user's local time

**Locations:** `lib/main.dart` and `lib/services/retention_engine.dart`.

Timezone data is initialized, but the app does not set `tz.local` to the
device timezone before calling `zonedSchedule`. A user-selected 7 PM reminder
can therefore be scheduled relative to UTC rather than local time.

**Recommended fix:** obtain the device timezone through a supported platform
API, call `tz.setLocalLocation(...)`, and add tests around local midnight and
daylight-saving transitions.

### 6. Notification taps do not perform their advertised action

**Location:** `lib/services/notification_service.dart`.

The notification response handler only logs the payload. Payloads such as
`open_update_page` and `install_update` do not navigate or trigger an action.

**Recommended fix:** route notification responses through a navigator key or
a small app-intent service after app initialization. Handle cold-start
notification payloads too.

### 7. Retention settings accept an unchecked reminder hour

**Location:** `lib/services/retention_engine.dart`, `enableNotifications()`.

`preferredHour` is stored without ensuring it is in `0..23`.

**Recommended fix:** validate at the service boundary and fall back to the
default hour if persisted data is invalid.

### 8. Firebase Analytics documentation and implementation disagree

**Locations:** `README.md`, `PRIVACY.md`, and
`lib/services/analytics_service.dart`.

The README claims `check_for_update`, `notification_shown`, and
`notification_opened` are analytics events. The code emits `check_update` and
does not define the notification events. The Privacy Policy says there is no
analytics or tracking, while the app initializes Firebase Analytics, sets a
user ID/property, and emits usage events.

**Recommended fix:** make the privacy policy and README describe the actual
collection, provide an analytics opt-out if appropriate for the distribution,
and either implement or remove each documented event.

### 9. The analytics user ID is derived from a low-entropy personal value

**Location:** `lib/services/analytics_service.dart`, `setUser()`.

The identifier is an unsalted SHA-256 hash of a learner name. Hashing does not
make common names anonymous because they can be guessed and hashed again.

**Recommended fix:** generate and persist a random installation ID instead;
never derive an analytics identifier from a user-entered name.

## UI and UX issues

### 11. Daily 5 feedback has a contrast problem

**Location:** `lib/pages/daily_five_page.dart`, `_buildFeedback()`.

The answer word is rendered in white inside a very light, translucent
green/red panel. This can have poor contrast and be difficult to read.

**Recommended fix:** use the theme's dark text color on light feedback panels,
or use a fully dark panel when rendering white text. Verify WCAG contrast in
both light and dark contexts.

### 12. Daily 5 reward language and behavior do not match

The screen presents a compact learning session but rewards individual cards as
full lesson completions and the session as a quiz. This makes the progression
model feel arbitrary rather than trustworthy.

**Recommended fix:** name and reward the activity consistently: recall XP per
card, a small completion bonus once, and an optional accuracy/mastery bonus.

### 13. The new session screen is not production-ready

**Location:** `lib/pages/daily_five_session_page.dart`.

It renders literal placeholder terms and does not connect card IDs to
`WordData`. It should not be linked from navigation until it is fully wired.

**Recommended fix:** either remove it from the active roadmap temporarily or
inject a word repository and make it display real image, Anywaa, English, and
audio content before use.

### 14. Naming and product identity are inconsistent

Examples include `Dha Anywaaa` in iOS metadata/package identifiers versus
`Dha Anywaa` in Android and app titles, plus typo-derived classes such as
`Shpae` and `wraper.dart`.

**Recommended fix:** preserve existing package IDs where migration would be
risky, but standardize user-visible names and rename internal symbols during a
planned refactor.

## Bible feature audit

### 15. Release blocker: the Bible page does not compile

**Location:** `lib/pages/bible_page.dart`.

Focused analysis of this file reports **43 issues**, including undefined
`_player`, `_playing`, `_buffering`, `_loadedUrl`, `_doneSub`, and `_stateSub`
identifiers; a missing `UrlSource`/`PlayerState` import; and a missing
`_AudioComingSoon` widget. The page references audio code but does not declare
the associated player state or import the audio API. `_AudioBar` is also
defined but unused.

**Impact:** the current application cannot produce a clean release build while
this file is included.

**Recommended fix:** either complete the audio implementation in one change
(imports, `AudioPlayer`, fields, subscriptions, dispose cleanup, visible
control, and error states) or remove the unfinished audio code until it is
ready. Add a build/analyzer gate before release.

### 16. Bible loading performs a large synchronous parse on the UI isolate

**Location:** `lib/pages/bible_page.dart`, `_loadData()`;
`assets/bible.json`.

The bundled Bible JSON is approximately **11.2 MB** and contains the full
verse collection. It is loaded as one string, decoded, and mapped into every
`BibleVerse` object on the main isolate. This can cause a visible freeze or
long loading state on lower-memory/older Android devices.

**Recommended fix:** parse using `compute`/a background isolate, or pre-split
the dataset by book/chapter and load only the selected content. Keep a compact
book/chapter index for the library screen.

### 17. Search rescans every verse on each keystroke

**Location:** `lib/pages/bible_page.dart`, `_search()`.

Every input change iterates through the complete verse list and lowercases both
Anywaa and English text before taking the first 100 results. With more than
31,000 verses, this can make typing lag and does unnecessary allocations.

**Recommended fix:** debounce typing (about 200–300 ms), precompute normalized
search fields once after loading, and move the search/index work off the UI
isolate if profiling shows dropped frames.

### 18. Bible data failure leaves the user with an empty library

**Location:** `lib/pages/bible_page.dart`, `_loadData()`.

The catch block only clears the loading indicator. If JSON parsing or asset
loading fails, the user gets a blank Bible library with no error, retry, or
support action.

**Recommended fix:** retain a load-error state, show a clear message and Retry
button, and log a non-content diagnostic event. Validate the bundled JSON in
CI before building.

### 19. Testament classification depends on JSON ordering

**Location:** `lib/pages/bible_page.dart`, `_buildMeta()`.

The first 39 distinct books are assumed to be Old Testament and the remainder
New Testament. This silently misclassifies books if the source data is
reordered, incomplete, or contains a duplicate/alternate book name.

**Recommended fix:** store a `testament` field or maintain an explicit,
versioned canonical book-order list and validate the complete 66-book set on
build.

### 20. Bible audio design is incomplete and changes the privacy/offline model

**Location:** `lib/pages/bible_page.dart`, `_audioUrl()`.

The intended audio URL points to Firebase Storage, which requires network
access and sends a request to a third party. That conflicts with the current
policy's statement that the app has only an update-related outbound request;
the public UI currently says audio is coming soon while incomplete playback
code remains in the source.

**Recommended fix:** decide explicitly whether Bible audio is online-only,
downloadable for offline use, or omitted. Document the resulting network use,
provide an offline/error state, and add playback tests before exposing the
control.

### 21. The Bible feature has no automated regression coverage

No test currently validates the asset schema, the 66-book/31,000+ verse
expectation, chapter navigation boundaries, search results, preference
restoration, or error state.

**Recommended fix:** add data-schema unit tests and widget tests for opening a
book, selecting chapters, searching, navigating first/last chapters, toggling
English/night/font settings, and handling a failed asset load.

## Security, privacy, and platform risks

### 22. Sensitive Android permission footprint needs a release-policy review

**Location:** `android/app/src/main/AndroidManifest.xml`.

The application requests notification, exact-alarm, foreground-service,
package-installation, and network permissions. Some are justified by current
features, but exact-alarm and package-install permissions are sensitive and
can require additional store-policy justification.

**Recommended fix:** request permissions only at the point of feature use,
remove any unused permission, explain each requested permission in the privacy
policy, and verify the target distribution's policy requirements before each
release.

### 23. Local learner data is stored in plain SharedPreferences

Names, progress, XP, and analytics identifiers are stored locally without
encryption. This is normal for non-sensitive learning progress, but it should
not be described as protected or used for sensitive data in the future.

**Recommended fix:** keep only non-sensitive data there. If accounts,
contact details, or other sensitive data are added, move secrets/tokens to a
platform secure-storage solution and document retention/deletion behavior.

### 24. Firebase configuration key exposure is not itself a secret leak

`android/app/google-services.json` contains a Firebase API key. Firebase
Android configuration keys are normally embedded in client apps; do not rotate
it solely because it is visible. Security instead depends on Firebase project
restrictions, enabled APIs, authentication rules, and not placing server
secrets in the client.

**Recommended action:** audit Firebase project API restrictions and confirm no
privileged server credential has been committed.

## Maintainability and release-quality issues

### 25. Documentation is stale and internally inconsistent

`pubspec.yaml` currently reports version `1.6.2+184`; README and app
documentation report older versions. Privacy and Firebase descriptions also
conflict with the source.

**Recommended fix:** generate version, feature, permission, and analytics
sections from a single release checklist/source of truth before publishing.

### 26. Duplicate imports and legacy paths add maintenance risk

`lib/home_page.dart` imports `learning_engine.dart` twice. Several older and
newer systems coexist without a documented ownership boundary.

**Recommended fix:** run formatter/analyzer in CI, remove duplicate imports,
and add an architecture note naming the one supported learning/progress path.

### 27. Automated coverage misses core persistence and retention behavior

Current tests strongly cover the offline dictionary and theme persistence but
do not cover Daily 5 scheduling, review persistence, XP consistency, streaks,
comeback eligibility, notification scheduling, or analytics event names.

**Recommended fix:** add unit tests for FSRS state transitions and session
selection; use SharedPreferences mocks for rewards/streaks; add widget tests
for Daily 5 summary values; and add a release CI job for `flutter analyze` and
`flutter test`.

## Recommended implementation order

1. Repair the Bible compile errors and add a release analyzer gate.
2. Make Daily 5 use one learning/progress service and write migration tests.
3. Correct Daily 5 XP persistence/display consistency and close the comeback
   bonus race.
4. Parse/search Bible data off the UI thread and provide a load-error state.
5. Rename the reserved Analytics event; reconcile event docs and privacy text.
6. Fix local-time notification scheduling and notification-response routing.
7. Remove/finish placeholder learning screens and clean duplicate/legacy code.
8. Add CI checks and regression tests for every issue above.

## Verification note

The report is based on direct source inspection. A focused
`flutter analyze lib/pages/bible_page.dart` run completed and found 43 issues,
including compile errors. A full-project analyzer/test run has not yet been
completed; it should be required before treating a release build as verified.



I’ve read the full audit report for the Dha Anywaa app. Here is a quick summary of where it stands and what I’d do first.

The picture overall: the app has a solid offline-first base and a large vocabulary dataset. The problems come from unfinished or duplicated systems rather than from the core design. Two parallel FSRS/progress systems exist and only one is wired to Daily 5, and the Bible page is mid-implementation.

Blockers and highest-impact items

    Bible page doesn’t compile (#15). The audio code references _player, _playing, _buffering and similar fields that are never declared, plus missing imports and a missing _AudioComingSoon widget. Nothing can ship until this is fixed. The fastest path is to strip the unfinished audio code and show a “coming soon” label, since audio would also change your offline and privacy model (#20).
    Daily 5 XP mismatch (#1, #12). The page shows one XP amount but awards a different one through the lesson-complete and quiz-finish APIs. A single completeDailyFive() method in the progress service fixes this and the analytics together.
    Two progress systems (#2). Choose one card model, one scheduler and one store. Migrate fsrs_word_states_v1 once, then delete or wire the dormant lib/learning/ code. Do this before adding any new progress features.
    app_update event is dropped by Firebase (#4). This is a one-line rename, for example to update_download_started.
    Privacy policy contradicts the code (#8, #9, #20). PRIVACY.md says there is no analytics, but the app uses Firebase Analytics with a user ID derived from a hashed learner name. Replace that with a random installation ID and update the policy. This matters most if you publish to the Play Store.

Quick wins: the reminder-hour validation (#7), the duplicate import (#26), the Daily 5 feedback contrast (#11), and the Bible search debounce (#17).

Suggested order, which matches the report’s own list: fix the Bible compile errors and add a flutter analyze gate, unify the progress system with a migration test, fix XP and the comeback race, move Bible parsing off the UI thread, correct the analytics and privacy items, then fix notification timezone and tap routing.

I can start on any of these. The most useful first steps would be a patch for the Bible page compile errors, or a design for the unified completeDailyFive() service and the one-time migration. Which would you like?

suggest the best fixes
Settling on fixes for the audio, daily-five, and comeback code

Here are the fixes I’d choose, with the reasoning for each. Where the report offers options, I’ve picked one.
1. Bible page compile errors (#15): remove the audio code for now

Finishing audio would add network use, a privacy-policy change and an offline story you haven’t decided on (#20). Removing it is the smallest change and unblocks the release.

    Delete _audioUrl(), _AudioBar, and every reference to _player, _playing, _buffering, _loadedUrl, _doneSub and _stateSub.
    Replace the control with a static label such as Chip(label: Text('Audio coming soon')).
    Re-run flutter analyze lib/pages/bible_page.dart; it should drop from 43 issues to near zero.

Add audio back later as a separate change: download per book into app storage, play from the local file, and update the privacy text at the same time.
2. Progress systems (#2): keep the active one, delete the dormant one

The report suggests migrating, but the cheaper path is to keep learning_engine.dart and gamification_service.dart, because real user data lives in fsrs_word_states_v1. The dormant lib/learning/ and lib/progress/ code is still on placeholder data, so there is likely nothing worth migrating.

    Search for imports of learning_service.dart, card_repository.dart, xp_system.dart, mastery_tracker.dart and daily_five_session_page.dart.
    If nothing live uses them, delete them, along with the placeholder session page (#13).
    Check the keys they write in SharedPreferences. If a few beta users have data there, copy it once; otherwise skip it.

3. Daily 5 XP (#1, #12): one award, computed in one place

Remove the per-card onLessonComplete() and the onQuizFinish() calls. The page only collects results, and the service decides the award.
dart

class DailyFiveResult {
  final int correct, total, comboXp;
  const DailyFiveResult(this.correct, this.total, this.comboXp);
}

class DailyFiveAward {
  final int recallXp, completionBonus, accuracyBonus;
  const DailyFiveAward(this.recallXp, this.completionBonus, this.accuracyBonus);
  int get total => recallXp + completionBonus + accuracyBonus;
}

// in GamificationService
Future<DailyFiveAward> completeDailyFive(DailyFiveResult r) async {
  final recall = r.correct * 2 + (r.total - r.correct) * 1 + r.comboXp;
  const completion = 5;
  final accuracy = (r.total > 0 && r.correct / r.total >= 0.8) ? 5 : 0;
  final award = DailyFiveAward(recall, completion, accuracy);
  await _addXp(award.total);       // one write: XP, daily goal, level, streak
  await _analytics.logDailyFiveComplete(award.total, r.correct, r.total);
  return award;
}

The summary screen shows award.total, so the displayed and stored values always match. During the session, show running XP as a preview only and persist nothing per card.
4. Comeback bonus race (#3)

Make it one awaited method and call it once.
dart

Future<bool> recordOpenAndClaimComebackBonus() async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final lastMs = prefs.getInt('retention_last_open');
  final eligible = lastMs != null &&
      now.difference(DateTime.fromMillisecondsSinceEpoch(lastMs)).inDays >= 3; // keep your current threshold
  await prefs.setInt('retention_last_open', now.millisecondsSinceEpoch);
  if (eligible) await prefs.setInt('retention_comeback_claimed_at', now.millisecondsSinceEpoch);
  return eligible;
}

Because the open time is written in the same call, the bonus can’t fire twice for the same gap. In HomePage, do final got = await retention.recordOpenAndClaimComebackBonus(); inside a single async init method and remove the separate onAppOpen() call.
5. Analytics and privacy (#4, #8, #9)

    Rename app_update to update_download_started.
    Replace the name-hash user ID with a random install ID generated once:

dart

  final id = prefs.getString('install_id') ??
      (() { final v = const Uuid().v4(); prefs.setString('install_id', v); return v; })();
  await FirebaseAnalytics.instance.setUserId(id: id);

    Fix the docs so they match the code: check_update in the README, and delete the notification events from it unless you implement them.
    Rewrite PRIVACY.md to say that Firebase Analytics collects usage events tied to a random install ID, and add an opt-out switch in Settings (setAnalyticsCollectionEnabled).

6. Bible performance and reliability (#16–19, #21)

    Parse off the UI thread: final verses = await compute(_parseBible, rawJson); with _parseBible as a top-level function. The longer-term fix is to split the 11 MB file into 66 per-book files plus a small index.json, so only the open book loads.
    Search: build a lowerAnywaa/lowerEnglish field once at load, add a 250 ms Timer debounce in onChanged, and cap results at 100.
    Error state: add a _loadError flag with a message and a Retry button that calls _loadData().
    Testament: use an explicit canonical list of 66 book names in code and look each book up in it, instead of assuming the first 39 distinct books are the Old Testament. Add a unit test that asserts all 66 books are found.

7. Notifications (#5–7)

    Timezone: add flutter_timezone, then final name = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(name)); before any zonedSchedule. Newer versions of the package return an object rather than a string, so check which one your version gives you.
    Hour validation: final h = (preferredHour >= 0 && preferredHour <= 23) ? preferredHour : 19;
    Tap routing: add a global GlobalKey<NavigatorState>, have the response handler call navigatorKey.currentState?.pushNamed(...) by payload, and also check getNotificationAppLaunchDetails() at startup for cold starts.

8. Cheap guardrails

    Fix Daily 5 feedback contrast (#11) by using the theme’s dark text color on the light panel.
    Remove the duplicate import (#26).
    Request exact-alarm and package-install permissions only when the feature is used, and remove any that are unused (#22).
    Add a CI gate so the compile error can’t come back:

yaml

  - run: flutter pub get
  - run: flutter analyze --fatal-infos
  - run: flutter test

Order of work

    Bible audio removal plus the CI gate (one sitting, unblocks everything).
    Delete the dormant progress code, then completeDailyFive() with tests.
    Comeback bonus and analytics rename, install ID and privacy text.
    Bible parsing, search and error state.
    Notification fixes.

If you give me daily_five_page.dart and gamification_service.dart, I can write the exact patch for steps 2–3. If you’d rather start with the Bible page, send bible_page.dart and I’ll produce the cleaned-up file.


