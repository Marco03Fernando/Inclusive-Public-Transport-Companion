# colombo_pal

A new Flutter project.

## Running locally

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (this project targets Dart `^3.13.1` — see `pubspec.yaml`)
- [Android Studio](https://developer.android.com/studio) — even if you don't use it as your editor, installing it once gets you the Android SDK, `adb`, and an emulator, all needed to build/run on Android
- A Firebase project with **Email/Password** + **Anonymous** Authentication enabled and a **Firestore** database created (see [docs/TESTING.md](docs/TESTING.md) for the full walkthrough)

### Setup

```bash
git clone <this-repo-url>
cd colombo_pal
flutter pub get
```

This project uses Firebase (Auth + Firestore) for sign up/login, profile, and the Request Assistance feature, so `lib/firebase_options.dart` must be generated before the app will build. From the repo root:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
flutterfire configure
```

Pick your Firebase project when prompted, select the platforms you need (Android/iOS/Web), and it will generate `lib/firebase_options.dart` and wire up the platform config files automatically. Full details, including exact console click-paths, are in [docs/TESTING.md](docs/TESTING.md).

### Run it

```bash
flutter devices        # see what's available: Chrome, Windows/macOS/Linux desktop, a connected phone, an emulator...
flutter run -d chrome   # or -d windows, -d <device-id> for a phone/emulator
```

Once running, in the terminal: `r` = hot reload, `R` = hot restart, `q` = quit.

To run on a physical Android phone: enable Developer Options + USB debugging on the phone, connect via USB, confirm it shows up in `flutter devices`, then `flutter run -d <device-id>`. See [docs/TESTING.md](docs/TESTING.md) for the full device-setup and troubleshooting steps (driver issues, missing Android SDK, etc).

### Verify it's working

```bash
flutter analyze
```

should come back clean once `flutterfire configure` has run. For a full test plan covering sign up/login, profile, SOS, and Request Assistance, see [docs/TESTING.md](docs/TESTING.md); for how those features are implemented, see [docs/MY_FEATURES.md](docs/MY_FEATURES.md).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
