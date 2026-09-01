# 21Days

Sahaja Yoga Meditation hub — live sessions, mentors, and recorded wisdom.

## Run

```bash
flutter pub get
flutter run
```

For **production API** (Cloud Run):

```bash
flutter run --dart-define=API_BASE_URL=https://na21days-media-api-2g62ryauoq-uc.a.run.app
```

## App Store / TestFlight

See **[docs/APPLE_REVIEW.md](docs/APPLE_REVIEW.md)** for the full checklist, review notes, and listing copy.

**Release IPA:**

```bash
chmod +x scripts/ios_release.sh   # once
./scripts/ios_release.sh
```

**Privacy policy URL:** https://www.explore21days.org/privacy (hosted from `21days-media-resources`; deploy backend before submit).

Demo login works with any valid email + password (≥6 chars), or **Continue with Google** (mock).

## Structure

```
lib/
  models/      # User, session, recording, mentor, wisdom
  views/       # Auth + Live / Resources / Mentor / Wisdom
  services/    # Auth, search, notifications, session, mentor
  providers/   # Provider state
  theme/       # Serene teal / soft-orange theme
```

## Backend

Resources search always calls the live API (no mocks):

`POST {API_BASE_URL}/search`

| Target | Command |
|--------|---------|
| Local Flask (`:5005`) | `flutter run -d chrome` (default) |
| Cloud Run | `flutter run -d chrome --dart-define=API_BASE_URL=https://na21days-media-api-2g62ryauoq-uc.a.run.app` |

Keep Flask running locally, or point `API_BASE_URL` at Cloud Run.

## Tests

```bash
flutter test
```
