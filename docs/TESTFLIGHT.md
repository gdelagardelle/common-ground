# TestFlight Release Checklist

Use this guide to ship **Common Ground** build 1.0 to TestFlight.

## Prerequisites

- Apple Developer Program membership
- Xcode 16+ with iOS 18 SDK (iOS 26 SDK for on-device AI features)
- Bundle ID: `com.germaind.CommonGround` registered in App Store Connect

## 1. App Store Connect setup

1. Create a new app in [App Store Connect](https://appstoreconnect.apple.com)
2. Set **Bundle ID** to `com.germaind.CommonGround`
3. Fill in metadata:
   - **Name:** Common Ground Co-Parent
   - **Subtitle:** Co-parenting, coordinated
   - **Category:** Lifestyle (primary), Productivity (secondary)
   - **Privacy Policy URL:** (required before external testing)
4. Complete **App Privacy** questionnaire — no data collected off-device by default

## 2. Xcode signing

1. Open `CommonGround.xcodeproj`
2. Select the **CommonGround** target → **Signing & Capabilities**
3. Set your **Team**
4. Capabilities are preconfigured in the repo (regenerate after `project.yml` changes):
   - **iCloud** → CloudKit → container `iCloud.com.germaind.CommonGround`
   - **App Groups** → `group.com.germaind.CommonGround`
   - In Xcode, open **Signing & Capabilities** and confirm both appear without errors
5. Optional for Apple Health:
   - Add **HealthKit** capability → enable read for Height and Body Mass
6. Regenerate project after `project.yml` changes:
   ```bash
   xcodegen generate
   ```

## 3. Version numbers

| Field | Value |
|-------|-------|
| Marketing Version | 1.0.0 |
| Build Number | Increment for each upload |

Update in `project.yml` or Xcode → General.

## 4. Archive & upload

```bash
# Clean build
xcodebuild -scheme CommonGround -destination 'generic/platform=iOS' \
  -configuration Release clean archive \
  -archivePath build/CommonGround.xcarchive

# Upload (requires App Store Connect API key or Xcode Organizer)
xcodebuild -exportArchive \
  -archivePath build/CommonGround.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist
```

Or use **Product → Archive** in Xcode, then **Distribute App → App Store Connect**.

For automated uploads, see [docs/app-store/upload.md](app-store/upload.md) and run:

```bash
./scripts/upload-testflight.sh 2
```

## 5. TestFlight groups

1. **Internal testing** — up to 100 team members, no review
2. **External testing** — requires Beta App Review + [privacy policy URL](https://gdelagardelle.github.io/common-ground/privacy/)

Suggested test plan:

- [ ] Onboarding → create family + child
- [ ] Build custody schedule → verify calendar export
- [ ] Apple Calendar sync (More → Apple Calendar Sync)
- [ ] Add expense → settle up
- [ ] Court export PDF + JSON
- [ ] AI assistant (on-device on iOS 26 + Apple Intelligence)
- [ ] Live Activity on exchange day (physical device)
- [ ] Face ID lock toggle

## 6. Export compliance

The app uses standard HTTPS only for invite links (`commonground.app`). No custom encryption beyond Apple platform APIs.

In App Store Connect, answer **Export Compliance**:

> Does your app use encryption? → Yes, exempt (uses only standard Apple OS encryption)

## 7. Known limitations (beta)

- iCloud sync requires CloudKit entitlements in Xcode (off by default)
- On-device AI requires iOS 26 + Apple Intelligence enabled
- Live Activities require a physical device
- Co-parent invite uses family code (full CloudKit sharing coming later)

## 8. Screenshots (6.7" required)

Capture on iPhone 15 Pro Max or 16 Pro Max simulator:

1. Home dashboard
2. Calendar + custody schedule
3. AI assistant
4. Expenses settle-up
5. Child profile / medical
6. More → integrations

---

**Bundle IDs**

| Target | Bundle ID |
|--------|-----------|
| App | `com.germaind.CommonGround` |
| Widgets | `com.germaind.CommonGround.widgets` |
| Watch | `com.germaind.CommonGround.watchkitapp` |
