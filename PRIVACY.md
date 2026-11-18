# Privacy Policy

Last updated: November 18, 2026

## What this app is

Learn Dha Anywaa is a language learning app for the Anywaa (Anuak) language.
It contains alphabet lessons, vocabulary with audio, reading exercises and a quiz.
The core lessons, dictionary, Bible, and quizzes work fully offline. No account is required.
The AI chat feature and update checks need an internet connection.

## What is stored on your device

The app stores the following data only on your device using Android SharedPreferences:

- Your name, so the home screen can greet you.
- Your last visited lesson, so the Continue card shows the right screen.
- Which items you have marked as learned, per category.
- Your sound effects preference (on or off).
- The timestamp of the last update check, to avoid checking more than once every 6 hours.

None of this data ever leaves your device except as described below.

## What leaves your device

The app makes one outbound network request: it checks for app updates by calling the
GitHub Releases API at api.github.com. This request includes your IP address as part
of normal HTTPS communication. No personal data from the app (your name, progress or
preferences) is sent with this request. The request is made at most once every 6 hours
and only when you are online.

## Permissions

The app requests these Android permissions:

- INTERNET: required to check for app updates.
- ACCESS_NETWORK_STATE: used to check whether your device is online before making the update request.
- REQUEST_INSTALL_PACKAGES: required to install a downloaded update APK directly from within the app.

## Children

This app is designed to be safe for all ages, including children.
It does not collect personal data, does not require an account,
and does not show advertising.

## Analytics and advertising

The app uses **Firebase Analytics** (Google) to collect anonymous usage
events such as lessons completed, quizzes finished, and feature usage.
These events contain no personal information. If you enter your name,
it is converted to a one-way SHA-256 hash before being used as the
analytics user ID — your actual name is never sent. Clearing the app's
data or reinstalling resets it.

There is no advertising and no sale of data.

## Third-party services

- **Firebase Analytics** (Google) — anonymous usage events, as above.
- **NVIDIA Nemotron / Groq** — when you use Anywaa AI chat, your
  messages are sent to these providers to generate replies. Do not
  share personal information in chat. Groq is used only as a fallback
  if Nemotron is unavailable.
- **GitHub** — update checks download the release manifest and APK
  from this app's public GitHub repository.
- **Google Fonts** — bundled inside the app, not loaded from the
  network.

## Data deletion

To delete all your data, clear the app storage in Android Settings,
or uninstall the app. No data is stored anywhere else.

## Contact

If you have questions about this policy, contact:
Kornellaotf@gmail.com

Developed by Kornella Otf
