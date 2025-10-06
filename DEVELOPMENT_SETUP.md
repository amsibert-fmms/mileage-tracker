# Development Setup Notes

## Toolchain
- Flutter 3.19+ (confirm with `flutter --version`).
- Dart SDK bundled with Flutter.
- Android Studio or VS Code for debugging.
- Android SDK Platform 34, Web support enabled (`flutter config --enable-web`).

## Environment Preparation
1. Install Flutter and run `flutter doctor` to verify dependencies.
2. Accept Android licenses via `flutter doctor --android-licenses`.
3. Add desired emulators or connect physical devices.
4. Enable Chrome or Edge for web testing.

## Project Initialization
- Clone repository: `git clone git@github.com:<org>/mileage-tracker.git`.
- Fetch packages: `flutter pub get`.
- Run code generation (reserved for future if needed).

## Branching Strategy
- `main`: stable releases.
- `develop`: integration branch for ongoing work.
- Feature branches: `feature/<short-description>` from `develop`.

## Local Development Commands
- `flutter run -d chrome` – quick web preview.
- `flutter run -d emulator-5554` – Android emulator run.
- `flutter test` – execute unit/widget tests.
- `flutter format lib test` – enforce formatting before commits.

## Continuous Integration
- GitHub Actions workflow planned for pull requests and main branch builds.
- Add caching for Flutter SDK and pub packages to reduce build times.

## Release Checklist (Android)
1. Update version in `pubspec.yaml`.
2. Run `flutter build apk --release`.
3. Sign the APK via Play Console or key store.
4. Smoke test on physical device prior to submission.

## Release Checklist (Web)
1. Run `flutter build web`.
2. Deploy `build/web` to GitHub Pages via Actions workflow.
3. Validate service worker caching and offline support (if enabled).

