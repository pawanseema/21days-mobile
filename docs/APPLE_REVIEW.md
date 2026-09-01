# Apple App Store review — 21Days (iOS)

Checklist and copy for TestFlight / App Store submission.

**Bundle ID:** `com.sahajayoga.twentyOneDays`  
**Display name:** 21Days  
**Version:** see `pubspec.yaml` (`version: x.y.z+build`)

---

## Before you upload

### 1. Production API in release builds

Debug builds default to `http://127.0.0.1:5005`. **Release builds must set the production API:**

```bash
./scripts/ios_release.sh
```

Override if needed:

```bash
API_BASE_URL=https://na21days-media-api-2g62ryauoq-uc.a.run.app ./scripts/ios_release.sh
```

(Default is already this Cloud Run URL.)

### 2. iOS permissions

`ios/Runner/Info.plist` includes `NSUserNotificationsUsageDescription` for the Upcoming session reminder.

### 3. Signing

- Xcode → Runner target → **Signing & Capabilities** → Team + Distribution profile
- Do **not** rely on debug signing for App Store upload
- Android note: `android/app/build.gradle.kts` still uses debug signing for release — fix before Play Store

### 4. URLs for App Store Connect

| Field | URL |
|-------|-----|
| **Privacy Policy** | https://www.explore21days.org/privacy |
| **Support** | https://www.explore21days.org/support |
| **Marketing** (optional) | https://www.explore21days.org/ |

**Support email** (shown on the support page; use for App Review contact if helpful): `sahajabayarea@gmail.com`

Deploy `21days-media-resources` so `/privacy` and `/support` are live before you submit.

### 5. App Privacy (nutrition labels)

For **version 1.0** (no login, no analytics):

- **Data not collected** for account/profile, or declare only what applies:
  - **Search queries** — sent to your server to return meditation content (not used for tracking if accurate)
  - **Device ID** — not collected by app code today
- **Notifications** — optional, on-device permission only

Reconcile with your final App Store Connect questionnaire.

### 6. Test on a physical iPhone (release)

```bash
flutter run --release -d <device-id> \
  --dart-define=API_BASE_URL=https://na21days-media-api-2g62ryauoq-uc.a.run.app
```

Verify:

- [ ] Explore → example chip → video plays
- [ ] Upcoming → session loads; reminder switch → iOS permission prompt
- [ ] Reminder tap (if testable) → opens **Upcoming** tab
- [ ] Recordings → expand session → play video
- [ ] About (header) → opens https://www.explore21days.org/ in Safari
- [ ] Live session → **Watch on YouTube** / **Join Zoom Meeting** when status is live

### 7. Screenshots

Capture on 6.7" iPhone (required): Explore results, Upcoming (session + reminder), Recordings expanded, in-app player.

---

## Build & upload

```bash
chmod +x scripts/ios_release.sh   # once
./scripts/ios_release.sh
```

Upload `build/ios/ipa/*.ipa` via **Transporter** or Xcode **Organizer**.

Bump `pubspec.yaml` build number (`+2`, `+3`, …) for each upload.

---

## App Review Notes (paste into App Store Connect)

```
21Days is a free companion for the public 21 Days Sahaja Yoga meditation course.

NO LOGIN REQUIRED: The app opens directly to Explore, Upcoming, and Recordings.

BACKEND: Content is loaded from our production API at:
https://na21days-media-api-2g62ryauoq-uc.a.run.app
(Public read-only endpoints; no test account.)

HOW TO TEST:
1. Explore → tap an example search chip (e.g. "Heart chakra meditation") → open a video.
2. Upcoming → pull to refresh; shows the next live or upcoming session when scheduled.
3. Recordings → expand a session → tap a video to play in the in-app player.
4. Notifications (optional): On Upcoming, turn on "Notify 5 minutes before the session starts" when a future session is listed. iOS will ask for notification permission. Tapping the reminder opens the Upcoming tab.

EXTERNAL LINKS:
- Live sessions: Watch on YouTube (in-app player) or Join Zoom Meeting (Zoom app).
- About in the header opens https://www.explore21days.org/
- Support: https://www.explore21days.org/support (sahajabayarea@gmail.com)

No in-app purchases. No user accounts in this version.
```

---

## Store listing copy

### Subtitle (≤30 chars)

`Sahaja Yoga meditation course`

### Description

21Days is the companion app for the online Sahaja Yoga Meditation course. Find meditation videos and handouts, see what is live or coming up, and browse recent session recordings.

**Explore** — Search meditation videos and handouts by topic, teacher, or theme.

**Upcoming** — See the next live or upcoming group meditation. When a session is live, join on YouTube or Zoom. Optional reminder 5 minutes before start.

**Recordings** — Browse the latest course year by session and watch with chapter markers when available.

Content is served from Sahaja Yoga meditation resources. Live sessions may open YouTube or Zoom.

### Keywords

`meditation,sahaja yoga,21 days,mindfulness,spiritual,yoga,handouts,live`

### What’s New (1.0.0)

```
Initial release.

• Explore meditation videos and handouts
• Upcoming live sessions with optional reminder
• Session recordings by year
• In-app YouTube player with chapters
```

---

## Common rejection risks

| Risk | Mitigation |
|------|------------|
| Empty app (localhost API) | Always use `ios_release.sh` or `--dart-define=API_BASE_URL=…` |
| Missing notification purpose string | `NSUserNotificationsUsageDescription` in Info.plist |
| Privacy URL broken | Deploy `/privacy` on production |
| Support URL broken | Deploy `/support` on production |
| Login without delete account | v1 has no login screen — keep it that way until delete flow ships |
