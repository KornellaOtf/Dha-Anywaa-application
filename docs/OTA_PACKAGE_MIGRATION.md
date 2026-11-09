# OTA Package Migration Strategy

**Version:** 1.0  
**Last Updated:** November 9, 2026  
**Affects:** v1.2.26 release

---

## Executive Summary

The Dha Anywaa application underwent a package name change from `com.bellaTech.dha_anywaaa` to `com.kornellaotf.learn_dha_anywaa` in v1.2.26. This document explains the technical reasons, user impact, and migration strategy.

---

## The Problem

### What Happened

**Timeline:**
- **v1.0.0 - v1.2.22:** Package name `com.bellaTech.dha_anywaaa`
- **v1.2.23 - v1.2.24:** Package name changed to `com.kornellaotf.learn_dha_anywaa`
- **v1.2.25 (cancelled):** Attempted revert to old package
- **v1.2.26:** Finalized new package with migration strategy

### Why It Matters

**Android Package Name Rules:**
1. Package name is the **unique identifier** for an app
2. Google Play Store uses it to identify apps
3. **Cannot update** between different package names
4. Must uninstall old app to install new package

**User Impact:**
```
User with v1.2.22 (old package) 
     ↓
Tries to install v1.2.26 (new package)
     ↓
Android Error: "Package appears invalid"
     ↓
Installation blocked
```

---

## Root Cause Analysis

### Why Was the Package Changed?

**Original Package:** `com.bellaTech.dha_anywaaa`
- Created early in development
- Company name: BellaTech
- App name: dha_anywaaa (with underscores)

**New Package:** `com.kornellaotf.learn_dha_anywaa`
- Updated organization: kornellaotf
- Better naming: learn_dha_anywaa
- Aligns with Firebase project

### When Was It Changed?

**Commit:** `7f67e04` (Nov 4, 2026)
```
Android: rename applicationId to com.kornellaotf.learn_dha_anywaa 
and move MainActivity
```

**Files Affected:**
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/...MainActivity.kt`

### Why Wasn't It Caught?

1. **No OTA Testing:** Package change broke OTA updates but wasn't tested
2. **No User Testing:** v1.2.23-v1.2.24 likely not distributed widely
3. **Firebase Setup:** Firebase was configured with new package, worked fine
4. **Build Success:** App built and ran successfully, no errors

---

## Decision: Keep New Package

### Options Considered

#### Option A: Revert to Old Package
```
Pros:
  ✓ Existing users can update via OTA
  ✓ No data loss for users
  ✓ Smoother transition

Cons:
  ✗ Firebase needs reconfiguration
  ✗ Must download new google-services.json
  ✗ Old naming convention
  ✗ Misaligned with current Firebase project
```

#### Option B: Keep New Package (CHOSEN)
```
Pros:
  ✓ Firebase already configured
  ✓ Better naming convention
  ✓ Aligns with organization
  ✓ No future Firebase issues

Cons:
  ✗ Users must uninstall/reinstall
  ✗ Data loss (one-time)
  ✗ User inconvenience
```

**Decision Rationale:**
- Firebase already set up with new package
- Better long-term naming
- One-time pain for long-term gain
- v1.2.23-v1.2.24 had limited distribution

---

## Migration Strategy

### Phase 1: Preparation (v1.2.26)

#### 1. Update Manifest

```json
{
  "version": "1.2.26",
  "mandatory": true,  // ← Mark as mandatory
  "releaseNotes": "IMPORTANT: Package name changed. Please uninstall old app first, then install this version. Future updates will work automatically."
}
```

**Key Changes:**
- `mandatory: true` - Signals critical update
- Clear release notes explaining migration
- Honest about data loss

#### 2. Create Detailed Release Notes

**GitHub Release Template:**
```markdown
## ⚠️ Important: Clean Install Required

This release updates the app package name for better organization.

### Installation Steps (One-Time Only)

1. **Uninstall** the current "Learn Dha Anywaa" app
2. **Download** the APK from this release
3. **Install** the new version

**Note:** Your learning progress will be reset. This is a one-time 
inconvenience - all future updates will work seamlessly!

### What's New
- [List features and fixes]

### Technical Details
- Old Package: com.bellaTech.dha_anywaaa
- New Package: com.kornellaotf.learn_dha_anywaa
```

#### 3. Notify Users (if applicable)

**Communication Channels:**
- GitHub release notes (primary)
- App notification (if OTA check runs)
- Social media / website (if applicable)
- Email list (if applicable)

### Phase 2: User Experience

#### Scenario 1: User with Old App

```
1. User opens app (v1.2.22, old package)
2. OTA check runs (if enabled)
3. Finds v1.2.26 available
4. Shows notification: "Update available (mandatory)"
5. User taps "Update"
6. Attempts download
7. Attempts installation
8. ❌ Android error: "Package appears invalid"
9. User sees error message
10. Reads release notes
11. Understands need to uninstall
12. Uninstalls old app
13. Downloads v1.2.26 APK from GitHub
14. Installs new app
15. ✅ Success
```

**Pain Points:**
- Confusing error message from Android
- Must manually uninstall
- Lose learning progress
- Extra steps required

**Mitigations:**
- Clear release notes
- Detailed installation instructions
- Acknowledgment of inconvenience
- Promise of seamless future updates

#### Scenario 2: New User

```
1. Discovers app
2. Downloads v1.2.26 APK
3. Installs
4. ✅ Works perfectly
5. No migration concerns
```

### Phase 3: Post-Migration (v1.2.27+)

```
┌────────────────────────────────────────────────────┐
│         v1.2.26+ (New Package)                     │
│   com.kornellaotf.learn_dha_anywaa                 │
├────────────────────────────────────────────────────┤
│                                                    │
│  v1.2.27 → v1.2.28 → v1.2.29 → ...                │
│     ✅       ✅        ✅                           │
│  OTA works seamlessly                              │
│  No manual intervention needed                     │
│  Progress preserved                                │
│                                                    │
└────────────────────────────────────────────────────┘
```

**Benefits:**
- All future updates work via OTA
- No more manual installations
- User progress preserved
- Smooth update experience

---

## Technical Implementation

### Android Configuration

#### build.gradle

```gradle
android {
    namespace "com.kornellaotf.learn_dha_anywaa"
    
    defaultConfig {
        applicationId "com.kornellaotf.learn_dha_anywaa"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode 126
        versionName "1.2.26"
    }
}
```

#### MainActivity.kt

```kotlin
package com.kornellaotf.learn_dha_anywaa

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
```

**File Location:**
```
android/app/src/main/kotlin/
  └── com/
      └── kornellaotf/
          └── learn_dha_anywaa/
              └── MainActivity.kt
```

### Firebase Configuration

#### google-services.json

```json
{
  "project_info": {
    "project_id": "learn-dha-anywaa",
    "project_number": "741893789084"
  },
  "client": [{
    "client_info": {
      "mobilesdk_app_id": "1:741893789084:android:c37941cbe756ed3f92a459",
      "android_client_info": {
        "package_name": "com.kornellaotf.learn_dha_anywaa"
      }
    }
  }]
}
```

**Verification:**
```bash
# Check package name in google-services.json
cat android/app/google-services.json | jq '.client[0].client_info.android_client_info.package_name'
# Should output: "com.kornellaotf.learn_dha_anywaa"

# Check package name in build.gradle
grep applicationId android/app/build.gradle
# Should output: applicationId "com.kornellaotf.learn_dha_anywaa"

# They must match!
```

### OTA Service Enhancement

#### Optional: Detect Package Mismatch

```dart
// lib/services/ota_service.dart

Future<OtaCheckResult?> checkForUpdate({
  bool forceCheck = false,
  bool silent = false,
}) async {
  // ... existing code ...
  
  final manifest = json.decode(manifestRes.body) as Map<String, dynamic>;
  
  // Check for package mismatch
  final requiresUninstall = manifest['requiresUninstall'] as bool? ?? false;
  
  if (requiresUninstall) {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentPackage = packageInfo.packageName;
    
    // If user has old package, show special message
    if (currentPackage != 'com.kornellaotf.learn_dha_anywaa') {
      return OtaCheckResult(
        updateAvailable: true,
        mandatory: true,
        requiresUninstall: true,
        latestVersion: manifest['version'] as String,
        releaseNotes: manifest['releaseNotes'] as String,
        // ... other fields ...
      );
    }
  }
  
  // ... rest of existing code ...
}
```

#### Enhanced UI for Migration

```dart
// lib/ota_update_page.dart

Widget _buildMigrationNotice() {
  return Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.amber.withOpacity(0.1),
      border: Border.all(color: Colors.amber),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.amber),
            SizedBox(width: 8),
            Text('Clean Install Required',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'This update changes the app package name. You must:\n'
          '1. Uninstall the current app\n'
          '2. Download and install this version\n\n'
          'Your progress will be reset (one-time only).\n'
          'Future updates will work automatically.',
        ),
        SizedBox(height: 12),
        ElevatedButton.icon(
          icon: Icon(Icons.download),
          label: Text('Download APK'),
          onPressed: () {
            // Open browser to GitHub release
            launch(result.apkUrl);
          },
        ),
      ],
    ),
  );
}
```

---

## Verification & Testing

### Build Verification

```bash
# 1. Check package name in build
flutter build apk --release
cd build/app/outputs/flutter-apk

# 2. Extract and verify package name
aapt dump badging app-release.apk | grep package
# Should show: package: name='com.kornellaotf.learn_dha_anywaa'

# 3. Verify signing
jarsigner -verify -verbose -certs app-release.apk
# Should show: jar verified.
```

### Installation Testing

**Test Scenario 1: Fresh Install**
```bash
# Install v1.2.26 on clean device
adb install -r dha-anywaa-v1.2.26.apk
# Expected: Success

# Verify package
adb shell pm list packages | grep anywaa
# Expected: package:com.kornellaotf.learn_dha_anywaa
```

**Test Scenario 2: Update from Old Package**
```bash
# Install old version first
adb install dha-anywaa-v1.2.22.apk

# Try to install new version
adb install -r dha-anywaa-v1.2.26.apk
# Expected: INSTALL_FAILED_UPDATE_INCOMPATIBLE

# Uninstall old, install new
adb uninstall com.bellaTech.dha_anywaaa
adb install dha-anywaa-v1.2.26.apk
# Expected: Success
```

**Test Scenario 3: Future Updates**
```bash
# Install v1.2.26
adb install dha-anywaa-v1.2.26.apk

# Install v1.2.27 (when available)
adb install -r dha-anywaa-v1.2.27.apk
# Expected: Success (OTA update works)
```

---

## Lessons Learned

### What Went Wrong

1. **No OTA Testing**
   - Package change wasn't tested with actual OTA updates
   - Assumed build success = everything works
   
2. **No Gradual Rollout**
   - Changed package across all versions
   - Should have communicated change earlier

3. **Firebase First**
   - Set up Firebase with new package before considering OTA
   - Should have aligned package strategy first

### Best Practices for Future

1. **Test OTA Updates**
   - Always test update path from previous version
   - Verify package name compatibility
   - Check signing compatibility

2. **Version Strategy**
   - Major version changes for breaking changes
   - Increment: v1.x.x → v2.0.0 for package changes
   - Clear versioning semantics

3. **User Communication**
   - Announce breaking changes in advance
   - Provide migration guides
   - Set clear expectations

4. **Gradual Rollout**
   - Release to small percentage first
   - Monitor for issues
   - Expand gradually

5. **Data Migration**
   - Consider cloud backup before breaking changes
   - Provide export/import functionality
   - Minimize data loss

---

## Future Considerations

### Preventing Similar Issues

1. **Package Name Policy**
   ```
   RULE: Never change package name after first public release
   
   Exception: Major rewrite (v1.x → v2.0) with user notification
   ```

2. **Testing Checklist**
   ```
   Before Release:
   [ ] Fresh install works
   [ ] Update from previous version works
   [ ] OTA update path tested
   [ ] Package name matches Firebase
   [ ] Signing verified
   [ ] All tests pass
   ```

3. **User Data Protection**
   ```
   Future Enhancement:
   - Cloud backup (Firebase/Google Drive)
   - Export/import functionality
   - Data migration tools
   ```

### Monitoring

**Post-Release Metrics:**
- Track update adoption rate
- Monitor installation failures
- Survey user satisfaction
- Measure drop-off

**Firebase Analytics Events:**
```dart
// Track migration success
await FirebaseAnalytics.instance.logEvent(
  name: 'package_migration_complete',
  parameters: {
    'from_version': oldVersion,
    'to_version': '1.2.26',
    'migration_type': 'clean_install',
  },
);
```

---

## Conclusion

The package name change in v1.2.26 requires a one-time user migration (uninstall/reinstall) but establishes a stable foundation for future OTA updates. While inconvenient for existing users, it aligns the app with Firebase configuration and proper naming conventions.

**Key Takeaways:**
1. ✅ Package name now stable: `com.kornellaotf.learn_dha_anywaa`
2. ✅ Firebase properly configured
3. ✅ Future OTA updates will work seamlessly
4. ✅ Clear communication with users
5. ✅ Lessons learned for future releases

---

## References

### Documentation

- [Android Application ID](https://developer.android.com/studio/build/application-id)
- [Package Name Best Practices](https://developer.android.com/guide/topics/manifest/manifest-intro#package-name)
- [Firebase Android Setup](https://firebase.google.com/docs/android/setup)

### Related Files

- `android/app/build.gradle`
- `android/app/google-services.json`
- `lib/services/ota_service.dart`
- `manifest.json`

---

**Document Version:** 1.0  
**Author:** Kiro AI Development Assistant  
**Last Updated:** November 9, 2026
