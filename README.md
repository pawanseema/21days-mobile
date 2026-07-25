# 21Days

Sahaja Yoga Meditation hub — live sessions, mentors, and recorded wisdom.

## Run

```bash
flutter pub get
flutter run
```

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
