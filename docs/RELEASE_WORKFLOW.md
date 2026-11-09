# Release Workflow — Dha Anywaa App

**Last Updated:** November 9, 2026

---

## Overview

Every release does three things automatically:
1. Builds the APK
2. Uploads to **Firebase App Distribution** (keeps Firebase console accurate)
3. Creates a **GitHub Release** (provides OTA download URL)

---

## Prerequisites

Before releasing, make sure:
- Firebase CLI logged in as `kornellaotf@gmail.com`
- `gh` CLI authenticated with GitHub
- `android/upload-keystore.jks` present
- `android/key.properties` configured correctly

Check with:
```bash
firebase login:list       # should show kornellaotf@gmail.com
gh auth status            # should show logged in
ls android/upload-keystore.jks  # should exist
```

---

## Step-by-Step Release Process

### 1. Make your code changes

Edit whatever files you need. Test locally.

### 2. Bump the version in pubspec.yaml

```yaml
# Format: MAJOR.MINOR.PATCH+BUILDNUMBER
version: 1.2.28+128
```

Rules:
- Patch (`1.2.x`): bug fixes, small improvements
- Minor (`1.x.0`): new features
- Major (`x.0.0`): breaking changes, major rewrites
- Build number: always increment by 1

### 3. Update CHANGELOG.md

Add an entry at the top:

```markdown
## 1.2.28 (build 128)

Released: YYYY-MM-DD

### Fixed
- Description of bug fix

### Added
- Description of new feature

### Changed
- Description of change
```

### 4. Commit your changes

```bash
git add -A
git commit -m "chore: bump to v1.2.28"
git push origin ui-cleanup-startup
```

### 5. Run the distribute script

```bash
./scripts/distribute.sh "Short description of what changed"
```

That's it. The script handles everything else automatically:
- Builds the APK
- Computes SHA-256 hash
- Updates manifest.json
- Uploads to Firebase App Distribution
- Creates GitHub release with APK + manifest

---

## What the distribute.sh Script Does

```bash
./scripts/distribute.sh "Release notes"
```

**Internally:**

```
1. Read version from pubspec.yaml (e.g. 1.2.28+128)
2. flutter build apk --release
3. Compute SHA-256 and file size
4. Write manifest.json with new version info
5. firebase appdistribution:distribute → uploads APK to Firebase
6. gh release create v1.2.28 → creates GitHub release with APK + manifest
7. Clean up temp files
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Building  : 1.2.28+128
 Tag       : v1.2.28
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
→ Building release APK...
→ APK SHA-256 : abc123...
→ APK size    : 100123456 bytes
→ Updating manifest.json...
→ Uploading to Firebase App Distribution...
→ Creating GitHub release v1.2.28...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 ✓ Done! v1.2.28 distributed.
 Firebase: https://console.firebase.google.com/...
 GitHub  : https://github.com/KornellaOtf/...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## OTA Update Flow (How Users Get Updates)

```
Developer releases v1.2.28
        ↓
GitHub Release created with APK + manifest.json
        ↓
User opens app (any version)
        ↓
App calls OtaService.checkForUpdate() on startup
        ↓
Downloads manifest.json from GitHub API
        ↓
Compares versionCode: remote (128) > local (127)?
        ↓ YES
Shows "Update available" notification/prompt
        ↓
User taps Download
        ↓
App downloads APK, verifies SHA-256
        ↓
User taps Install → Android installer opens
        ↓
App updated to v1.2.28
```

**OTA cache:** The app caches the update check for 6 hours to avoid hammering GitHub API. Use "Check for updates" in Settings to force an immediate check.

---

## Mandatory vs Optional Updates

In `manifest.json`:

```json
{
  "mandatory": false   // optional update, user can dismiss
  "mandatory": true    // forced update, shown prominently
}
```

Use `mandatory: true` for:
- Security fixes
- Breaking changes (like the v1.2.26 package migration)
- Critical bug fixes

The `distribute.sh` script defaults to `mandatory: false`. Edit `manifest.json` manually after running the script if you need a mandatory release.

---

## Signing Configuration

**Keystore:** `android/upload-keystore.jks`
**Key properties:** `android/key.properties`

```properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=../upload-keystore.jks
```

**Keystore details:**
- Valid: 2026-11-04 to 2056-10-27
- SHA-256: `92:AD:5B:4B:...`

⚠️ Never commit `key.properties` or `upload-keystore.jks` to git. They are in `.gitignore`.

---

## Version History

| Version | Build | Date | Type | Notes |
|---|---|---|---|---|
| 1.2.27 | 127 | 2026-11-09 | Fix | Analytics events connected |
| 1.2.26 | 126 | 2026-11-09 | Breaking | Package migration, user tracking |
| 1.2.24 | 124 | 2026-11-09 | Fix | Body parts image restored |
| 1.2.23 | 123 | 2026-11-09 | Fix | Dictionary data quality |
| 1.2.22 | 122 | 2026-11-09 | Feature | Body parts SVG redesign |
| 1.2.20 | 120 | 2026-11-08 | Feature | Firebase Analytics integration |
| 1.2.18 | 118 | 2026-11-08 | Fix | Notification permissions |

---

## Troubleshooting

### Build fails
```bash
flutter clean && flutter pub get
./scripts/distribute.sh "..."
```

### Firebase upload fails (auth error)
```bash
firebase login --reauth
# Sign in as kornellaotf@gmail.com
./scripts/distribute.sh "..."
```

### GitHub release fails (auth error)
```bash
gh auth login
./scripts/distribute.sh "..."
```

### Wrong version in APK
Check `pubspec.yaml` — make sure `version:` is updated before running the script.

### Keystore error
Make sure `android/upload-keystore.jks` exists and `android/key.properties` has correct paths and passwords.

---

## Firebase App Distribution

After uploading, view the release at:
```
https://console.firebase.google.com/project/learn-dha-anywaa/appdistribution
```

To share the app with a specific person, add them as a tester:
1. Go to App Distribution in Firebase console
2. Click "Testers & Groups"
3. Add their email
4. They'll get an email with an install link

---

## Related Documentation

- `docs/FIREBASE_ANALYTICS_GUIDE.md` — what analytics tracks and where to find it
- `docs/USER_TRACKING_IMPLEMENTATION.md` — how user IDs work
- `docs/OTA_PACKAGE_MIGRATION.md` — why v1.2.26 needed a clean install

---

**Document Version:** 1.0
**Last Updated:** November 9, 2026
