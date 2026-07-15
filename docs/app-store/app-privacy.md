# App Store Connect — App Privacy Answers

Use when completing **App Privacy** in App Store Connect for **Common Ground Co-Parent**.

## Summary

| Question | Answer |
|----------|--------|
| Do you or your third-party partners collect data from this app? | **No** |

Common Ground does not operate backend servers that collect user data. Family content stays on-device (and optionally in the user's private iCloud via CloudKit when they enable sync).

---

## If Apple asks about on-device / optional APIs

These are **not** "collected" by the developer unless you operate servers receiving that data. Answer **No** to collection for all categories below.

| Data type | Collected? | Notes |
|-----------|------------|-------|
| Contact Info | No | Email entered for co-parent display only; not sent to developer |
| Health & Fitness | No | Optional Apple Health **read** on device; not transmitted to developer |
| Financial Info | No | Expenses stored locally / iCloud only |
| Location | No | Optional when-in-use for exchange sharing; not sent to developer servers |
| User Content | No | Messages, photos, documents stay on device / user's iCloud |
| Identifiers | No | No advertising ID, no analytics SDK |
| Usage Data | No | No third-party analytics |
| Diagnostics | No | No custom crash reporter; optional Apple crash logs only if user opts in system-wide |

**Tracking:** No — `NSPrivacyTracking` is `false` in `PrivacyInfo.xcprivacy`.

---

## Required Reason API (Privacy Manifest)

Already declared in `CommonGround/PrivacyInfo.xcprivacy`:

| API | Reason |
|-----|--------|
| User Defaults | CA92.1 — app functionality preferences |
| File timestamp | C617.1 — document/metadata ordering |

---

## Privacy Policy URL

https://gdelagardelle.github.io/common-ground/privacy/
