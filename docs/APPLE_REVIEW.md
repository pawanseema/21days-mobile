# Apple App Store review — 21Days (iOS)

Checklist and copy for TestFlight / App Store submission.

**Bundle ID:** `com.sahajayoga.twentyOneDays`  
**App Store name** (App Store Connect — must be globally unique): **Explore 21 Days**  
**Icon label on iPhone** (`CFBundleDisplayName` in `Info.plist`): **21Days**  
**Version:** see `pubspec.yaml` (`version: x.y.z+build`)

### Naming (store vs home screen)

| Where | Value | Set in |
|-------|--------|--------|
| App Store listing / search | Explore 21 Days | App Store Connect when you create the app (not in the IPA) |
| Name under the icon | 21Days | `ios/Runner/Info.plist` → already `21Days` — no change needed |

You do **not** need a new IPA just to use **Explore 21 Days** on the store. Create the app record with that name and your existing upload (same bundle ID) should appear in TestFlight after processing.

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

`ios/Runner/Info.plist` includes:

- `NSUserNotificationsUsageDescription` — shown when the user turns on the Upcoming reminder (not at app launch).
- `ITSAppUsesNonExemptEncryption` = `false` — standard HTTPS only; skips repeated export-compliance prompts on upload.

If no permission dialog appears when toggling the reminder, check **Settings → 21Days → Notifications** (permission may already be granted or previously denied).

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

**During App Store review:** keep Cloud Run warm so reviewers avoid cold starts — set `RUN_MIN_INSTANCES=1` in `21days-media-resources/scripts/gcp/config.env` and run `./scripts/gcp/deploy.sh --no-build`. See `../21days-media-resources/scripts/gcp/README.md` (section “Keep one warm instance during App Store review”). Revert to `0` after approval.

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
