#!/usr/bin/env bash
# distribute.sh — Build and upload a release to Firebase App Distribution + GitHub Releases
#
# Usage:
#   ./scripts/distribute.sh "Release notes here"
#
# Requirements:
#   - firebase CLI logged in as kornellaotf@gmail.com
#   - gh CLI authenticated
#   - upload-keystore.jks in android/ directory
#   - key.properties configured

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
FIREBASE_APP_ID="1:741893789084:android:c37941cbe756ed3f92a459"
FIREBASE_PROJECT="learn-dha-anywaa"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# ── Args ──────────────────────────────────────────────────────────────────────
RELEASE_NOTES="${1:-"New release"}"

# ── Read version from pubspec.yaml ────────────────────────────────────────────
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f1)
BUILD=$(grep '^version:' pubspec.yaml | sed 's/version: //' | cut -d'+' -f2)
TAG="v${VERSION}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Building  : ${VERSION}+${BUILD}"
echo " Tag       : ${TAG}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Build ─────────────────────────────────────────────────────────────────────
echo "→ Building release APK..."
flutter build apk --release

# ── Hash ──────────────────────────────────────────────────────────────────────
SHA256=$(shasum -a 256 "$APK_PATH" | cut -d' ' -f1)
SIZE=$(wc -c < "$APK_PATH" | tr -d ' ')

echo "→ APK SHA-256 : $SHA256"
echo "→ APK size    : $SIZE bytes"

# ── Update manifest.json ──────────────────────────────────────────────────────
echo "→ Updating manifest.json..."
cat > manifest.json <<EOF
{
  "version": "${VERSION}",
  "versionCode": ${BUILD},
  "apkUrl": "https://github.com/KornellaOtf/Dha-Anywaa-application/releases/download/${TAG}/dha-anywaa-${TAG}.apk",
  "sha256": "${SHA256}",
  "sizeBytes": ${SIZE},
  "minSupportedVersionCode": 1,
  "mandatory": false,
  "releaseNotes": "${RELEASE_NOTES}",
  "developer": "Kornella Otf"
}
EOF

# ── Copy APK for GitHub release ───────────────────────────────────────────────
APK_NAMED="dha-anywaa-${TAG}.apk"
cp "$APK_PATH" "$APK_NAMED"

# ── Firebase App Distribution ─────────────────────────────────────────────────
echo "→ Uploading to Firebase App Distribution..."
firebase appdistribution:distribute "$APK_PATH" \
  --project "$FIREBASE_PROJECT" \
  --app "$FIREBASE_APP_ID" \
  --release-notes "${RELEASE_NOTES}"

# ── GitHub Release ────────────────────────────────────────────────────────────
echo "→ Creating GitHub release ${TAG}..."
gh release create "$TAG" \
  "$APK_NAMED" \
  manifest.json \
  --title "${TAG}" \
  --notes "${RELEASE_NOTES}"

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm "$APK_NAMED"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ✓ Done! ${TAG} distributed."
echo " Firebase: https://console.firebase.google.com/project/${FIREBASE_PROJECT}/appdistribution"
echo " GitHub  : https://github.com/KornellaOtf/Dha-Anywaa-application/releases/tag/${TAG}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
