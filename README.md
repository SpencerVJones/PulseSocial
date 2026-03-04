# Pulse

Pulse is an iOS social app built with SwiftUI, Firebase, and Cloudinary. It includes short-form posts, media attachments, ranked feed controls, and direct messaging with request-style inbox behavior.

## Current Features

- Email/password authentication
- Create posts with text, image, and voice clip attachments
- Repost, like, react, and comment on posts
- Follow/unfollow and people discovery
- Circles, prompts, and boards/collections
- Profile editing with avatar updates
- Activity feed + Firebase Messaging integration
- Direct messages with 1:1 deterministic thread IDs
- Group chat threads
- Message requests and blocked states
- Cloudinary-backed media messages (image/audio)
- Offline write queue with pending sync states
- Feed ranking v1 + user feed controls
- Unit and UI test targets

## Stack

- Swift 5
- SwiftUI
- Firebase Auth
- Cloud Firestore
- Firebase Messaging
- Cloudinary
- PhotosUI / AVFoundation
- XCTest / XCUITest

## Repository Layout

```text
.
├── docs/
│   └── ranking.md
├── firebase.json
├── firestore.rules
├── README.md
└── Pulse/
    ├── Pulse.xcodeproj
    ├── Pulse/
    │   ├── App/
    │   ├── Assets.xcassets/
    │   ├── Core/
    │   ├── Extensions/
    │   ├── Model/
    │   ├── Services/
    │   └── Utils/
    ├── PulseTests/
    └── PulseUITests/
```

## Setup

### Prerequisites

- Xcode 16+
- iOS Simulator or iPhone
- Firebase project
- Cloudinary account + upload preset

### 1) Clone

```bash
git clone <your-repo-url>
cd <your-repo-folder>
```

### 2) Open Project

```bash
xed Pulse/Pulse.xcodeproj
```

If `xed` is not installed:

```bash
open -a Xcode Pulse/Pulse.xcodeproj
```

### 3) Firebase Configuration

Register an iOS app in Firebase with bundle ID:

```text
makesspence.Pulse
```

Place your Firebase plist at:

```text
Pulse/Pulse/GoogleService-Info.plist
```

`GoogleService-Info.plist` is intentionally gitignored and should stay local only.

Enable these products in Firebase Console:

- Authentication
- Firestore
- Messaging

### 4) Cloudinary Configuration

Copy:

```text
Pulse/Pulse/Config/Cloudinary.local.example.xcconfig
```

to:

```text
Pulse/Pulse/Config/Cloudinary.local.xcconfig
```

Then set:

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`

The app reads runtime Info.plist keys:

- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_UPLOAD_PRESET`

### 5) Build / Run

```bash
xcodebuild -project Pulse/Pulse.xcodeproj -scheme Pulse -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

Run from Xcode with `Cmd+R`.

## Firestore Rules

Rules file:

```text
firestore.rules
```

Current rules include chat-focused access control for:

- `chats/{chatId}`
- `chats/{chatId}/members/{memberId}`
- `chats/{chatId}/messages/{messageId}`
- `chats/{chatId}/invites/{inviteId}`
- `userChats/{uid}/chats/{chatId}`
- `blocks/{uid}/blocked/{blockedUid}`

Deploy rules:

```bash
firebase deploy --only firestore:rules
```

## Tests

Targets:

- `PulseTests`
- `PulseUITests`

Run all tests from CLI:

```bash
xcodebuild -project Pulse/Pulse.xcodeproj -scheme Pulse -destination 'platform=iOS Simulator,name=<Simulator Name>,OS=latest' test
```

Or run from Xcode with `Cmd+U`.

## Notes

- Media uploads use Cloudinary, not Firebase Storage.
- Feed ranking notes are in `docs/ranking.md`.
- Push notification behavior on physical devices depends on Apple signing, APNs, and Firebase setup.
- Free Apple developer accounts can limit push testing capabilities.

## Roadmap

- Timeline fan-out strategy + cursor pagination hardening
- Signed Cloudinary upload flow
- Moderation + abuse controls
- Feature flags / experiments
- Expanded contract + emulator-backed integration tests

## Contributing

1. Fork the repo
2. Create a branch
3. Commit changes
4. Push branch
5. Open a pull request


## Contact

- Spencer Jones
- Email: `SpencerVJones@outlook.com`
- GitHub: `https://github.com/SpencerVJones`
