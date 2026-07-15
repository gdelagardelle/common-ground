# Common Ground

**The operating system for raising children across multiple households.**

A native SwiftUI co-parenting platform designed to feel as polished as Apple Reminders, Calendar, Health, and Notes — combined. Built for divorced parents, separated parents, blended families, grandparents, legal guardians, and foster care.

---

## Product Vision

Common Ground is not a custody calendar. It is the single source of truth for everything about your children — health, school, expenses, documents, communication, and milestones — shared securely across households.

### Competitive Positioning

| | OurFamilyWizard | AppClose | **Common Ground** |
|---|---|---|---|
| **Feel** | Functional, dated UI | Modern but generic | Apple-native, premium |
| **Price** | $99+/parent/year | Free | Free core, pro legal tier |
| **AI** | Tone rewriting only | None | Answers across all data |
| **Child focus** | Parent-centric | Parent-centric | Child-centric OS |
| **Offline** | Limited | Sync delays | Offline-first |
| **Court records** | Gold standard | Basic | Immutable + signed export |

**Our insight:** Competitors solve co-parent *conflict*. We solve co-parent *coordination* — while still providing court-grade records when needed.

---

## Architecture

```
CommonGround/
├── CommonGround/              # App target (entry, intents, assets)
├── CommonGroundWidgets/       # WidgetKit + Live Activities
├── CommonGroundWatch/         # watchOS companion
├── Packages/
│   ├── CommonGroundCore/      # Models, services, sync, security
│   ├── CommonGroundDesign/    # Design tokens, components
│   └── CommonGroundFeatures/  # Feature modules (MVVM views)
└── Tests/
```

### Stack

- **UI:** SwiftUI, iOS 18+ (forward-compatible with iOS 27 APIs)
- **Persistence:** SwiftData with CloudKit private database
- **Architecture:** MVVM + modular packages + dependency injection
- **Security:** Face ID / Touch ID, Keychain, encrypted documents
- **Sync:** Local-first with CloudKit conflict resolution
- **Testing:** Swift Testing (unit) + snapshot test infrastructure

### Core Modules

| Module | Description |
|--------|-------------|
| **Child Profiles** | Photo, vitals, allergies, sizes, emergency info |
| **Calendar** | Custody schedules, school, sports, drag-and-drop |
| **Expenses** | Split tracking, receipts, outstanding balances |
| **Medical** | Records, medications, growth, vaccinations |
| **School** | Teachers, classes, homework, permission slips |
| **Messages** | Immutable, court-admissible, tamper-evident audit trail |
| **Documents** | Passport, insurance, reports — searchable |
| **Timeline** | Milestones, achievements, firsts |
| **AI Assistant** | Natural language across all stored data |
| **Checklists** | Packing lists, homework, routines |

---

## Design Principles

1. **Zero learning curve** — Every screen obvious on first open
2. **Two-tap actions** — Most tasks complete in ≤2 taps
3. **Progressive disclosure** — Advanced features hidden until needed
4. **Accessibility first** — Dynamic Type, VoiceOver, high contrast
5. **Offline-first** — Works on a plane, syncs when connected
6. **Secure by default** — Biometric lock, granular permissions

---

## Getting Started

### Requirements

- Xcode 16+
- iOS 18+ device or simulator
- Apple Developer account (for CloudKit)

### Setup

```bash
# Generate Xcode project (requires xcodegen)
brew install xcodegen
cd "Common Ground"
xcodegen generate

# Open in Xcode
open CommonGround.xcodeproj
```

If xcodegen is unavailable, open `Package.swift` in Xcode and add the app target manually.

### Configuration

1. Set your Development Team in Signing & Capabilities
2. Optional: Enable CloudKit container `iCloud.com.germaind.CommonGround`
3. Optional: Enable App Group `group.com.germaind.CommonGround`
4. Run on simulator — use onboarding or DEBUG demo data

See [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md) for App Store Connect and TestFlight steps.

See [docs/app-store/SUBMISSION.md](docs/app-store/SUBMISSION.md) for the full App Store submission checklist.

**Privacy policy & support:** [gdelagardelle.github.io/common-ground](https://gdelagardelle.github.io/common-ground/) (GitHub Pages from `/docs`)

---

## Security Model

- **Biometric unlock** on every cold start
- **Keychain** for sensitive fields (SSN, passport numbers)
- **Immutable messages** with cryptographic audit hashes
- **Role-based permissions** (parent, grandparent, professional)
- **Court export** with signed PDF + raw data archive
- **Complete audit log** of all actions

---

## Siri & Shortcuts

Pre-built App Intents:

- *"When is the next exchange in Common Ground?"*
- *"Show unpaid expenses in Common Ground"*
- *"Ask Common Ground about my family"*

---

## Roadmap

- [x] Live Activities for custody exchanges
- [x] Calendar sync (Apple Calendar two-way)
- [x] On-device LLM for private AI queries (iOS 26 + Apple Intelligence)
- [x] Apple Health integration (growth charts)
- [x] School portal stub (announcements + homework)
- [x] Optional location sharing at exchanges
- [x] Digital custody agreement signing
- [x] Professional portal (attorney/GAL access)
- [x] Real-time co-parent CloudKit sharing
- [x] Co-parent family code join (local)

---

## License

Proprietary. All rights reserved.
