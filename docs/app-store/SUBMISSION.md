# App Store Submission Checklist

Use this after TestFlight build **4** (launch readiness audit fixes) is **Ready to Test**.

## 1. App Store Connect — App Information

| Field | Value |
|-------|-------|
| Name | Common Ground Co-Parent |
| Subtitle | Co-parenting, coordinated |
| Privacy Policy | https://gdelagardelle.github.io/common-ground/privacy/ |
| Support URL | https://gdelagardelle.github.io/common-ground/support/ |
| Marketing URL | https://gdelagardelle.github.io/common-ground/ |
| Primary Category | Lifestyle |
| Secondary Category | Productivity |
| Price | Free |

Copy description, keywords, and promotional text from [metadata.md](metadata.md).

## 2. App Privacy

See [app-privacy.md](app-privacy.md) for exact questionnaire answers.

Summary:

- **Data linked to you:** None collected by developer servers
- **Tracking:** No
- If asked about Health, Calendar, Location, Photos — only when user grants permission on device

## 3. Age Rating

Complete the questionnaire. Expected result: **4+** (no restricted content).

## 4. Screenshots (6.7" display required)

```bash
./scripts/capture-screenshots.sh
```

Upload PNGs from `docs/app-store/screenshots/` to the **6.7" iPhone** slot (iPhone 16 Pro Max).

Optional **6.5"** set: run `./scripts/prepare-app-store.sh` (generates `screenshots-6.5/`).

Recommended order:

1. `01-home.png` — Family dashboard
2. `02-calendar.png` — Custody calendar
3. `03-children.png` — Child profile
4. `04-messages.png` — Co-parent messaging
5. `05-more.png` — Integrations (Calendar, Health, export)

## 5. TestFlight — External beta (optional)

1. **TestFlight** → **External Testing** → create group
2. Paste privacy policy URL (above)
3. **What to Test:** copy from [testflight-beta-notes.md](testflight-beta-notes.md)
4. Submit for **Beta App Review** (~24–48 hours)

## 6. App Review submission

1. **App Store** → **+ Version** → `1.0.0`
2. Select build **2** (or latest)
3. Paste **Review Notes** from [review-notes.txt](review-notes.txt) (or [metadata.md](metadata.md))
4. **Export Compliance:** uses encryption → **Yes**, exempt (standard Apple OS only)
5. Submit for Review

## 7. Re-upload after fixes

```bash
cp .env.local.example .env.local   # fill in values once
./scripts/upload-testflight.sh 3   # increment build number each upload
```

## Quick links

- Repo: https://github.com/gdelagardelle/common-ground
- TestFlight guide: [../TESTFLIGHT.md](../TESTFLIGHT.md)
- Upload automation: [upload.md](upload.md)
