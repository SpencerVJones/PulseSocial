<div align="center">
  <h2 align="center">PulseSocial</h2>
  <div align="left">

![Repo Views](https://visitor-badge.laobi.icu/badge?page_id=SpencerVJones/PulseSocial)

</div>

<p align="center">
  A lightweight iOS social app for short-form posting, messaging, and community interaction.  
  Built with <strong>Swift + SwiftUI</strong>, powered by <strong>Firebase</strong>, and using <strong>Cloudinary</strong> for media uploads.
  <br /><br />
  PulseSocial includes ranked feed controls, circles, prompts, boards, comments, reactions, and direct/group messaging.
  <br />
  <br />
  <a href="https://github.com/SpencerVJones/PulseSocial/issues">Report Bug</a>
    ·
    <a href="https://github.com/SpencerVJones/PulseSocial/issues">Request Feature</a>
  </p>
</div>

<!-- PROJECT SHIELDS -->
<div align="center">

![License](https://img.shields.io/badge/License-Proprietary-black?style=for-the-badge)
![Contributors](https://img.shields.io/github/contributors/SpencerVJones/PulseSocial?style=for-the-badge)
![Forks](https://img.shields.io/github/forks/SpencerVJones/PulseSocial?style=for-the-badge)
![Stargazers](https://img.shields.io/github/stars/SpencerVJones/PulseSocial?style=for-the-badge)
![Issues](https://img.shields.io/github/issues/SpencerVJones/PulseSocial?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/SpencerVJones/PulseSocial?style=for-the-badge)
![Repo Size](https://img.shields.io/github/repo-size/SpencerVJones/PulseSocial?style=for-the-badge)

![Platform](https://img.shields.io/badge/Platform-iOS-lightgrey.svg?style=for-the-badge&logo=apple&logoColor=white)
![Swift](https://img.shields.io/badge/Swift-5%2B-F05138?style=for-the-badge&logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Framework-0A84FF?style=for-the-badge&logo=swift&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Firestore](https://img.shields.io/badge/Firestore-Database-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Cloudinary](https://img.shields.io/badge/Cloudinary-Media-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-16%2B-147EFB?style=for-the-badge&logo=xcode&logoColor=white)

</div>

## 📑 Table of Contents
- [Overview](#overview)
- [Technologies Used](#technologies-used)
- [Architecture](#architecture)
- [Features](#features)
- [Demo](#demo)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [How to Run](#how-to-run)
- [Usage](#usage)
- [Roadmap](#roadmap)
- [License](#license)
- [Contact](#contact)

## Overview
**PulseSocial** is an iOS social experience focused on short-form content and conversations.  
It supports text/image/audio posts, reactions and comments, ranked feed behavior, and inbox-based messaging.

This repository is structured as a **native SwiftUI app** using **Firebase services** with a focused service-layer architecture.

## Technologies Used
- **Swift 5+**
- **SwiftUI**
- **Firebase Auth**
- **Cloud Firestore**
- **Firebase Messaging**
- **Cloudinary** (media uploads)
- **AVFoundation / PhotosUI**
- **XCTest / XCUITest**

## Architecture
- **Native iOS app** with SwiftUI-first UI composition
- **Service layer** for auth, feed, threads, comments, reactions, messaging, and social graph actions
- **Feature-driven folders** under `Core/` with dedicated view models
- **Firebase-backed data + notifications**, with Cloudinary media hosting

## Features
- 🔐 Email/password authentication
- ✍️ Create posts with text, images, and voice clips
- ❤️ Likes, reactions, comments, and reposting
- 👥 Follow/unfollow, circles, and people discovery
- 🧵 Boards/collections and posting prompts
- 💬 1:1 and group chat threads with inbox request behavior
- 📣 Activity feed and Firebase Messaging integration
- 🛰️ Offline write queue with pending sync states
- ⚙️ Feed ranking controls + test targets

## Demo
Public live demo is not currently published.  
Run locally with Xcode using the steps below.

## Project Structure
```bash
PulseSocial/
├── .github/workflows/                # CI / automation
├── docs/
│   └── ranking.md                    # Feed ranking notes
├── firebase.json                     # Firebase project config
├── firestore.rules                   # Firestore security rules
├── README.md
└── Pulse/
    ├── Pulse.xcodeproj/              # Xcode project
    ├── Pulse/                        # Main app target source
    │   ├── App/
    │   ├── Assets.xcassets/
    │   ├── Config/
    │   ├── Core/
    │   ├── Extensions/
    │   ├── Model/
    │   ├── Services/
    │   └── Utils/
    ├── PulseTests/                   # Unit tests
    └── PulseUITests/                 # UI tests
```

## Testing
Run tests from Xcode (`Cmd+U`) or with CLI:

```bash
xcodebuild -project Pulse/Pulse.xcodeproj -scheme Pulse -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' test
```

## Getting Started
### Prerequisites
- **macOS** with **Xcode 16+**
- iOS Simulator or physical iPhone
- Firebase project (Auth, Firestore, Messaging enabled)
- Cloudinary account + upload preset

### Installation
```bash
git clone https://github.com/SpencerVJones/PulseSocial.git
cd PulseSocial
open -a Xcode Pulse/Pulse.xcodeproj
```

### How to Run
1. Add Firebase config:
   - Register iOS app bundle ID: `makesspence.Pulse`
   - Place `GoogleService-Info.plist` at `Pulse/Pulse/GoogleService-Info.plist`
2. Add Cloudinary config:
   - Copy `Pulse/Pulse/Config/Cloudinary.local.example.xcconfig`
   - Create `Pulse/Pulse/Config/Cloudinary.local.xcconfig`
   - Set `CLOUDINARY_CLOUD_NAME` and `CLOUDINARY_UPLOAD_PRESET`
3. Build and run in Xcode (`Cmd+R`) or via CLI:

```bash
xcodebuild -project Pulse/Pulse.xcodeproj -scheme Pulse -configuration Debug -destination 'generic/platform=iOS Simulator' build
```

## Usage
- Sign in or create an account.
- Create posts with text, image, or voice attachments.
- Explore feed ranking options, engage with comments/reactions, and use 1:1 or group chats.

## Roadmap
- [ ] Timeline fan-out strategy + cursor pagination hardening
- [ ] Signed Cloudinary upload flow
- [ ] Moderation + abuse controls
- [ ] Feature flags / experimentation infrastructure
- [ ] Expanded contract + emulator-backed integration tests

See open issues for a full list of proposed features (and known issues).

## License
Copyright (c) 2026 Spencer Jones
<br>
All rights reserved.
<br>
Permission is granted to view this code for personal and educational purposes only.
<br>
No permission is granted to copy, modify, distribute, sublicense, or sell any portion of this code without explicit written consent from the author.

## Contact
Spencer Jones  
📧 [SpencerVJones@outlook.com](mailto:SpencerVJones@outlook.com)  
🔗 [GitHub Profile](https://github.com/SpencerVJones)  
🔗 [Project Repository](https://github.com/SpencerVJones/PulseSocial)
