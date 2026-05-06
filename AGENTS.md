# Repository Guidelines

## Project Structure & Modules
- `lib/`: Main Flutter application code (widgets, state, services).
- `test/`: Dart/Flutter tests mirroring structure under `lib/`.
- `assets/`: Images, fonts, and static resources referenced in `pubspec.yaml`.
- `functions/`: Firebase Cloud Functions (Node.js) and related config.
- `android/`, `ios/`, `web/`: Platform-specific host projects; avoid editing unless required.

## Build, Test & Development
- `flutter pub get`: Install/update Dart dependencies.
- `flutter run -d chrome` (or device id): Run the app locally.
- `flutter test`: Run unit/widget tests under `test/`.
- `flutter build web` / `flutter build apk`: Production builds for web/Android.
- `cd functions && npm install`: Install Cloud Functions dependencies.
- `cd functions && npm test` (if configured): Run backend tests/lint.

## Coding Style & Naming
- Follow `analysis_options.yaml` and fix all `flutter analyze` warnings.
- Use 2-space indentation for Dart and keep files formatted via `dart format .`.
- Dart: `lowerCamelCase` for methods/variables, `UpperCamelCase` for classes/widgets, `snake_case.dart` filenames.
- Keep widgets small and composable; reuse shared logic in `lib/` services/helpers.

## Testing Guidelines
- Place tests in `test/` with filenames matching the source, e.g., `lib/features/auth/login_page.dart` → `test/features/auth/login_page_test.dart`.
- Prefer fast unit/widget tests; mock Firebase/network where possible.
- Ensure new features include at least basic happy‑path coverage.

## Commits & Pull Requests
- Use Conventional Commits: e.g., `feat: ...`, `fix: ...`, `chore: ...`, `docs: ...`.
- Write PRs with a clear summary, linked issues, and screenshots/GIFs for UI changes.
- Keep PRs focused and small; note any breaking changes or required migrations (e.g., Firestore rules, Cloud Functions updates).

## Agent-Specific Notes
- When modifying code, respect this structure and avoid editing Firebase config/rules unless explicitly required.
- Prefer minimal, targeted changes that align with existing patterns and tooling.

