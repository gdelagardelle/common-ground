# Uploading to TestFlight

Automated upload via [scripts/upload-testflight.sh](../scripts/upload-testflight.sh).

## One-time setup

### 1. App Store Connect API key

1. Go to [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Create a key with **App Manager** or **Developer** role
3. Download the `.p8` file (only available once)
4. Note the **Key ID** and **Issuer ID**

### 2. Local secrets

Create `.env.local` in the project root (already gitignored):

```bash
DEVELOPMENT_TEAM=YOUR_TEAM_ID
ASC_KEY_ID=XXXXXXXXXX
ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
ASC_KEY_PATH=/Users/you/keys/AuthKey_XXXXXXXXXX.p8
```

Find your Team ID in Xcode → Settings → Accounts, or the Apple Developer portal.

### 3. Xcode capabilities

Before uploading, enable in Xcode for the **CommonGround** target:

- Signing & Capabilities → Team set
- Optional: HealthKit, iCloud, Location (When In Use)

## Upload

```bash
chmod +x scripts/upload-testflight.sh
./scripts/upload-testflight.sh 2
```

The optional argument is the build number (`CURRENT_PROJECT_VERSION`).

## Manual alternative

1. Xcode → Product → Archive
2. Window → Organizer → Distribute App → App Store Connect → Upload

## After upload

1. Wait for processing in App Store Connect → TestFlight
2. Add internal testers (no review) or external testers (requires Beta App Review)
3. Use metadata from [metadata.md](metadata.md)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `altool` authentication failed | Verify Key ID, Issuer ID, and `.p8` path |
| Missing compliance | `ITSAppUsesNonExemptEncryption` is set to `false` in Info.plist |
| Provisioning errors | Open Xcode, set Team, let automatic signing resolve profiles |
| HealthKit / Location rejected | Add usage descriptions in Info.plist (already included) |
