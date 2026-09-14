# Google Play — release & testing checklist

**Package / applicationId:** `com.sahajayoga.twenty_one_days`  
**Version:** see `pubspec.yaml` (`version: x.y.z+build` → versionName / versionCode)  
**Min SDK:** API 24 (Android 7.0)  
**Privacy:** https://www.explore21days.org/privacy  
**Support:** https://www.explore21days.org/support (`sahajabayarea@gmail.com`)  
**About (in-app):** https://us.sahajayoga.org/21days/

---

## 1. Commit what you want to ship

Work from `main`, with production API ready on Cloud Run.

## 2. Create an upload keystore (once per app)

```bash
keytool -genkey -v \
  -keystore "$HOME/upload-keystore.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Back up the `.jks` file and both passwords. Losing them blocks future updates signed with this key.

## 3. Wire release signing (required before Play upload)

Play rejects AABs signed with the **debug** key. Do this once on your machine:

### 3a. Create `android/key.properties`

```bash
cd /Users/pawansaxena/playpen/21days-mobile
cp android/key.properties.example android/key.properties
```

Edit `android/key.properties` (this file is **gitignored** — never commit it):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=/Users/pawansaxena/upload-keystore.jks
```

Use the **absolute path** to your `.jks` in `storeFile`.  
`keyAlias` must match the alias you used in `keytool` (example uses `upload`).

### 3b. Gradle already reads that file

`android/app/build.gradle.kts` loads `android/key.properties` and signs **release** with it when the file exists.  
If `key.properties` is missing, release falls back to debug signing (local only — not for Play).

No extra manual Gradle edits are needed after you create `key.properties`.

### 3c. Confirm (optional)

```bash
# Should fail with a clear error if key.properties is missing:
./scripts/android_release.sh
```

## 4. Choose version

In `pubspec.yaml`, e.g. `1.0.1+3` or bump to `1.0.2+4` for a new Play upload.  
Every Play upload needs a **higher** `+build` (versionCode).

## 5. Build the App Bundle

```bash
./scripts/android_release.sh
```

Or:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://na21days-media-api-2g62ryauoq-uc.a.run.app
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 6. Internal testing (developers)

1. Play Console → app → **Testing → Internal testing**
2. Create release → upload the `.aab`
3. **Testers** → add email list → copy **opt-in link** → send to developers
4. They open the link, accept, install from Play

## 7. Production review

1. Finish store listing, Data safety, content rating, privacy/support URLs
2. **Production** → create/promote release from the same AAB
3. Submit for review

---

## Common failures

| Problem | Fix |
|---------|-----|
| “Signed with debug key” / upload rejected | Create `android/key.properties` (step 3) |
| Missing `key.properties` | Copy from `key.properties.example` |
| Wrong `storeFile` path | Use absolute path to the `.jks` |
| App talks to localhost | Always use `android_release.sh` or the production `--dart-define` |
| versionCode already used | Bump `+N` in `pubspec.yaml` |
