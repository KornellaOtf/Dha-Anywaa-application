#!/bin/bash
#
# Dha Anywaa - Release Script
#
# This script builds the APK, computes the correct SHA256 and size,
# writes manifest.json, commits, tags, pushes, and creates the GitHub
# release with the APK + manifest attached.
#
# USAGE:
#   ./scripts/release.sh 1.4.2 162
#   (version=1.4.2, versionCode=162)
#
# The SHA256 in manifest.json is ALWAYS computed from the actual built APK
# file AFTER the build finishes. This prevents the OTA verification failure
# that happened in v1.4.0 (wrong hash was manually copied).
#
set -e

# ── Args ────────────────────────────────────────────────────────────────────
VERSION="${1:?Usage: ./scripts/release.sh <version> <versionCode>}"
BUILD="${2:?Usage: ./scripts/release.sh <version> <versionCode>}"

# ── Config ──────────────────────────────────────────────────────────────────
REPO="KornellaOtf/Dha-Anywaa-application"
PACKAGE="com.kornellaotf.learn_dha_anywaa"
BRANCH="ui-cleanup-startup"
APK_NAME="dha-anywaa-v${VERSION}.apk"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
MANIFEST="manifest.json"

echo "=== Dha Anywaa Release: v${VERSION} (build ${BUILD}) ==="
echo ""

# ── Step 1: Bump version in pubspec.yaml ────────────────────────────────────
echo "[1/8] Bumping pubspec.yaml to ${VERSION}+${BUILD}..."
sed -i "s/^version: .*/version: ${VERSION}+${BUILD}/" pubspec.yaml
grep "^version:" pubspec.yaml

# ── Step 2: Build the APK ───────────────────────────────────────────────────
echo ""
echo "[2/8] Building APK (--target-platform android-arm,android-arm64)..."
flutter build apk --release --target-platform android-arm,android-arm64
echo "Built: $(ls -lh ${APK_PATH} | awk '{print $5}')"

# ── Step 3: Compute SHA256 and size from the ACTUAL built APK ───────────────
echo ""
echo "[3/8] Computing SHA256 and file size..."
SHA256=$(shasum -a 256 "${APK_PATH}" | cut -d' ' -f1)
SIZE=$(wc -c < "${APK_PATH}")
echo "SHA256: ${SHA256}"
echo "Size:   ${SIZE} bytes ($((SIZE / 1048576)) MB)"

# ── Step 4: Write manifest.json with the CORRECT hash ───────────────────────
echo ""
echo "[4/8] Writing manifest.json..."
cat > "${MANIFEST}" << EOF
{
  "version": "${VERSION}",
  "versionCode": ${BUILD},
  "apkUrl": "https://github.com/${REPO}/releases/download/v${VERSION}/${APK_NAME}",
  "sha256": "${SHA256}",
  "sizeBytes": ${SIZE},
  "minSupportedVersionCode": 1,
  "mandatory": false,
  "releaseNotes": "Version ${VERSION}",
  "developer": "Kornella Otf"
}
EOF
cat "${MANIFEST}"

# ── Step 5: Verify the hash matches BEFORE committing ────────────────────────
echo ""
echo "[5/8] Verifying SHA256 matches..."
ACTUAL_SHA=$(shasum -a 256 "${APK_PATH}" | cut -d' ' -f1)
MANIFEST_SHA=$(python3 -c "import json; print(json.load(open('${MANIFEST}'))['sha256'])")
if [ "${ACTUAL_SHA}" != "${MANIFEST_SHA}" ]; then
  echo "ERROR: SHA256 mismatch! APK=${ACTUAL_SHA} manifest=${MANIFEST_SHA}"
  exit 1
fi
echo "OK - SHA256 matches"

# ── Step 6: Copy APK, commit, tag, push ──────────────────────────────────────
echo ""
echo "[6/8] Committing and pushing..."
# Remove any stale APK in /tmp to prevent uploading the wrong file
rm -f "/tmp/${APK_NAME}"
cp "${APK_PATH}" "/tmp/${APK_NAME}"
git add pubspec.yaml "${MANIFEST}"
git commit -m "release: v${VERSION}+${BUILD}" || echo "Nothing to commit"
git tag "v${VERSION}"
git push origin "${BRANCH}"
git push origin "v${VERSION}"

# ── Step 7: Create GitHub release with APK + manifest ───────────────────────
echo ""
echo "[7/8] Creating GitHub release..."
gh release create "v${VERSION}" \
  "${MANIFEST}" \
  "/tmp/${APK_NAME}" \
  --title "v${VERSION}" \
  --notes "Release v${VERSION}

Package: ${PACKAGE}
SHA-256: ${SHA256}
Size: $((SIZE / 1048576)) MB

Direct download: https://github.com/${REPO}/releases/download/v${VERSION}/${APK_NAME}" || echo "Release may already exist"

# ── Step 8: Verify the GitHub release has the APK ───────────────────────────
echo ""
echo "[8/8] Verifying GitHub release..."
gh release view "v${VERSION}" --json assets --jq '.assets[] | "\(.name) - \(.size) bytes"'

echo ""
echo "=== Release v${VERSION} complete ==="
echo ""
echo "OTA verification:"
echo "  Local APK SHA:   ${SHA256}"
echo "  Manifest SHA:    ${MANIFEST_SHA}"
echo "  GitHub APK size:  ${SIZE} bytes"
echo ""
echo "Download link:"
echo "  https://github.com/${REPO}/releases/download/v${VERSION}/${APK_NAME}"
