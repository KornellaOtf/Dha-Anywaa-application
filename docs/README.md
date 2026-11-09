# Dha Anywaa Documentation

This directory contains comprehensive documentation for the Dha Anywaa Flutter application.

---

## 📚 Documentation Index

### Release Documentation

#### [RELEASE_NOTES_v1.2.26.md](./RELEASE_NOTES_v1.2.26.md)
Complete documentation for v1.2.26 release including:
- Executive summary and breaking changes
- New features and fixes
- Technical implementation details
- Build information and dependencies
- Testing checklist and troubleshooting
- Future considerations

**Read this first** for an overview of the v1.2.26 release.

### Feature Documentation

#### [USER_TRACKING_IMPLEMENTATION.md](./USER_TRACKING_IMPLEMENTATION.md)
Detailed guide to Firebase Analytics user tracking:
- Architecture and components
- SHA-256 hashing implementation
- Lifecycle management (app start, name entry, logout)
- Privacy and security features
- GDPR compliance
- Analytics capabilities
- Testing and troubleshooting

**Read this** if you need to understand or modify the user tracking system.

### Migration Documentation

#### [OTA_PACKAGE_MIGRATION.md](./OTA_PACKAGE_MIGRATION.md)
Package name migration strategy and lessons learned:
- Problem analysis and root cause
- Decision rationale (keep new package)
- User migration strategy
- Technical implementation
- Verification and testing
- Lessons learned and best practices

**Read this** to understand why users must uninstall/reinstall for v1.2.26.

---

## 🚀 Quick Start

### For Developers

1. **Understanding the Release:**
   ```
   Start with: RELEASE_NOTES_v1.2.26.md
   ```

2. **Modifying User Tracking:**
   ```
   Read: USER_TRACKING_IMPLEMENTATION.md
   Focus on: "Implementation Details" section
   ```

3. **Troubleshooting OTA:**
   ```
   Read: OTA_PACKAGE_MIGRATION.md
   Focus on: "Verification & Testing" section
   ```

### For Users

**Installing v1.2.26:**
1. Uninstall old "Learn Dha Anywaa" app
2. Download APK from GitHub releases
3. Install new version
4. Future updates will work automatically

**GitHub Release:**
https://github.com/KornellaOtf/Dha-Anywaa-application/releases/tag/v1.2.26

---

## 📋 What Changed in v1.2.26

### Major Changes

1. **User Tracking Fixed** 🎯
   - Firebase Analytics now properly tracks users
   - Privacy-preserving SHA-256 hashed IDs
   - Persists across app restarts

2. **Package Name Changed** 📦
   - Old: `com.bellaTech.dha_anywaaa`
   - New: `com.kornellaotf.learn_dha_anywaa`
   - **Requires clean install** (one-time)

3. **UI Improvements** ✨
   - Body parts screen with better image fit
   - Dictionary data cleanup

### Breaking Change

⚠️ **Users must uninstall old app and reinstall v1.2.26**

This is a **one-time inconvenience**. All future updates (v1.2.27+) will work seamlessly via OTA.

---

## 🔧 Technical Stack

### Framework & Language
- **Flutter:** Latest stable
- **Dart:** Latest stable
- **Kotlin:** 2.2.20

### Backend Services
- **Firebase Analytics:** 11.6.0
- **Firebase Core:** 3.15.2

### Build System
- **Gradle:** 8.14.2
- **Android Gradle Plugin:** 8.11.1
- **NDK:** 28.2.13676358

### Key Dependencies
- `shared_preferences`: 2.4.0 (local storage)
- `crypto`: 3.0.6 (SHA-256 hashing)
- `http`: 1.3.0 (OTA updates)
- `package_info_plus`: 8.3.1 (version info)

---

## 📊 Analytics & Privacy

### What We Track

**User-Level Metrics:**
- Daily/Monthly Active Users
- Retention rates (day 1, 7, 30)
- Sessions per user
- Feature usage per user

**Events:**
- Lesson audio plays
- Lesson completions
- Quiz performance
- Theme/sound preferences
- Update checks

### Privacy Features

✅ **SHA-256 Hashing:** Only hashed IDs sent to Firebase  
✅ **No PII:** Cannot reverse-engineer user names  
✅ **User Control:** Logout clears tracking  
✅ **GDPR Compliant:** Anonymous data, user control  

---

## 🧪 Testing

### Manual Testing Checklist

**Fresh Install:**
- [ ] App installs successfully
- [ ] User can enter name
- [ ] Firebase receives user ID
- [ ] App restarts preserve user ID

**Name Change:**
- [ ] Settings allow name change
- [ ] New user ID generated
- [ ] Firebase updated

**Logout:**
- [ ] User ID cleared
- [ ] Returns to guest mode
- [ ] New events are anonymous

### Automated Tests

Run tests:
```bash
flutter test
```

---

## 🐛 Troubleshooting

### Common Issues

**User ID Not Persisting:**
- Check `initializeFromStorage()` in Wrapper
- Verify SharedPreferences permissions

**Events Not in Firebase:**
- Verify google-services.json matches package
- Check internet connection
- Wait 24 hours for data

**OTA Updates Not Working:**
- Ensure package name matches across builds
- Verify signing configuration
- Check manifest.json URL

### Getting Help

- **GitHub Issues:** [Create an issue](https://github.com/KornellaOtf/Dha-Anywaa-application/issues)
- **Documentation:** See detailed docs above
- **Code:** Check source files referenced in docs

---

## 📝 Contributing

### Documentation Standards

When updating documentation:
1. Keep technical accuracy
2. Include code examples
3. Add troubleshooting sections
4. Update version numbers
5. Cross-reference related docs

### Code Comments

Follow these patterns:
```dart
/// Brief description of what this does.
///
/// More detailed explanation if needed.
///
/// Example:
/// ```dart
/// await analytics.setUser('John');
/// ```
Future<void> setUser(String name) async {
  // Implementation
}
```

---

## 📈 Metrics & Monitoring

### Firebase Console

View analytics at:
https://console.firebase.google.com/

**Key Dashboards:**
- Analytics Overview
- User Retention
- Event Details
- User Properties

### Build Monitoring

Track:
- Build success rate
- APK size trends
- Dependency updates
- Security vulnerabilities

---

## 🎯 Roadmap

### v1.2.27 (Next Release)

**Planned:**
- Monitor user tracking metrics
- Address any migration issues
- Clean up unused dependencies

**Potential:**
- Data export/import
- Cloud backup
- Enhanced analytics

### Future Versions

**Under Consideration:**
- Gradle upgrade (9.1.0+)
- Dependency updates
- Performance optimizations
- New learning features

---

## 📞 Contact

### Project Repository
https://github.com/KornellaOtf/Dha-Anywaa-application

### Releases
https://github.com/KornellaOtf/Dha-Anywaa-application/releases

### Issues
https://github.com/KornellaOtf/Dha-Anywaa-application/issues

---

## 📄 License

See LICENSE file in repository root.

---

## 🙏 Acknowledgments

- Firebase for analytics platform
- Flutter team for framework
- Open source contributors

---

**Last Updated:** November 9, 2026  
**Documentation Version:** 1.0  
**App Version:** 1.2.26 (build 126)
