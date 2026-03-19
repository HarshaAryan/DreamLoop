# 🌙 DreamLoop

> *A shared AI-generated adventure for two people — wherever they are.*

DreamLoop is a mobile app for long-distance couples and friends to explore an infinite AI-generated story world together. Both players receive story events, make independent choices, and watch the narrative evolve based on their combined decisions — asynchronously, at their own pace.

---

## ✨ What It Is

Two people. One shared world. Infinite stories.

DreamLoop creates a **daily ritual of shared curiosity and connection**. Each day brings a new story event — a glowing cave, a mysterious traveler, a dragon blocking the path. Both players choose what to do. Once both choose, the story moves forward.

The experience feels like:
- 🏕️ A cozy pixel game
- 📖 A collaborative bedtime story  
- 🌌 A shared dream you both shape

---

## 🎮 Core Loop

```
1. Two users connect via an invite link
2. AI generates a story event with 3 choices
3. Both users make their choice (asynchronously)
4. Story progresses once both decide
5. Repeat — infinitely
```

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (iOS-first) |
| Auth | Firebase Authentication (Apple & Google Sign-In) |
| Database | Cloud Firestore (real-time sync) |
| Notifications | Firebase Cloud Messaging |
| AI | OpenAI API (story + decision generation) |

---

## 📱 MVP Screens

- **Login** — Apple / Google Sign-In
- **Onboarding** — Character creation
- **Invite** — Generate / join a partner session
- **Story** — Current event + choice cards
- **History** — Past story events

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (`>=3.0.0`)
- Xcode (for iOS builds)
- Firebase project with iOS app configured

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/HarshaAryan/DreamLoop.git
cd DreamLoop/dreamloop_app

# 2. Install dependencies
flutter pub get

# 3. Add your secrets (NOT committed to git)
#    - Place GoogleService-Info.plist in ios/Runner/
#    - Create .env with your OpenAI API key

# 4. Run the app
flutter run
```

### Environment Variables

Create `dreamloop_app/.env`:

```
OPENAI_API_KEY=your_key_here
```

> ⚠️ `GoogleService-Info.plist` and `.env` are gitignored and must never be committed.

---

## 📂 Project Structure

```
DreamLoop/
├── dreamloop_app/        # Flutter app
│   ├── lib/
│   │   ├── screens/      # App screens
│   │   ├── services/     # Firebase, AI, Auth services
│   │   ├── models/       # Data models
│   │   ├── widgets/      # Reusable UI components
│   │   └── config/       # Theme & app config
│   └── ios/              # iOS native layer
└── docs/                 # Product & technical design docs
```

---

## 🗺️ Roadmap

- [x] Auth (Apple & Google Sign-In)
- [x] Partner invite system
- [x] AI story event generation
- [x] Real-time decision sync
- [x] Push notifications
- [x] Home screen widget (iOS)
- [ ] Pixel world visual layer
- [ ] AI-generated scene images
- [ ] Apple Watch support
- [ ] Rare & seasonal events

---

## 📄 Docs

Full product and technical design is in [`/docs`](./docs/).

---

*Built with 💙 by Harsha*
