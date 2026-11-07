# 🤖 ReEz AI - Flutter AI Chatbot Application

A modern, fast, cross-platform AI Chatbot application powered by **Google Gemini AI** (`gemini-3.5-flash-lite`), integrated with **Firebase Authentication** and **Cloud Firestore**.

🔗 **GitHub Repository**: [https://github.com/reezmahanan/Flutter-AI-Chatbot-Application.git](https://github.com/reezmahanan/Flutter-AI-Chatbot-Application.git)

---

## 🌟 Key Features

- **⚡ ReEz AI Engine**:
  - Powered by **Google Gemini AI** with low-latency streaming responses.
  - Multi-turn conversational context memory.
  - Real-time token streaming &mdash; answers appear live as they are generated.
- **🔐 Firebase Authentication**:
  - Email & Password registration with full user profile (`displayName`).
  - Seamless login with password visibility toggle.
  - Reactive `AuthGate` session management that auto-switches between chat and login.
  - Clean, user-friendly error messages.
- **💾 Cloud Persistence & Safe Fallbacks**:
  - Messages saved per-user in **Cloud Firestore** (`users/{uid}/messages`).
  - Offline-safe error handling so in-memory chatting continues even without internet.
- **🎨 Sleek Material 3 UI**:
  - Clean message bubbles (user on the right in theme color, ReEz AI on the left).
  - Animated "Thinking..." state indicator while waiting for the model.
  - One-tap quick starter prompt chips for instant chatting.
  - Option to clear conversation history.
  - Smooth auto-scrolling to the latest message.
- **📱 True Cross-Platform**:
  - Supports **Android**, **Web (Chrome / Edge)**, **Windows Desktop**, **iOS**, and **macOS**.

---

## 🏗️ Project Architecture

```
lib/
├── config/
│   └── api_config.dart          # Gemini API Key configuration
├── models/
│   └── chat_message.dart        # ChatMessage data model with Firestore serialization
├── screens/
│   ├── chat_screen.dart         # ReEz AI chat interface with streaming
│   ├── login_screen.dart        # User sign-in screen
│   └── register_screen.dart     # User registration screen
├── services/
│   ├── ai_chat_service.dart     # ReEz AI core engine (Gemini / Vertex AI & Firestore)
│   └── auth_service.dart        # Firebase Auth wrapper (login, register, logout)
├── firebase_options.dart        # FlutterFire CLI generated configuration
└── main.dart                    # App entry point, Firebase init & AuthGate
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version $\ge$ 3.12.0)
- A Google account to obtain a free [Google AI Studio API key](https://aistudio.google.com/app/apikey)
- Firebase project configured (already linked in `firebase_options.dart`)

### 1. Clone & Install Dependencies

```bash
git clone https://github.com/reezmahanan/Flutter-AI-Chatbot-Application.git
cd Flutter-AI-Chatbot-Application
flutter pub get
```

### 2. Configure Gemini API Key (Kept Local)

Get a free Gemini API key from [Google AI Studio](https://aistudio.google.com/app/apikey).

Set your key either in `lib/config/api_config.dart`:

```dart
class ApiConfig {
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  ...
}
```

Or pass it at runtime without changing the code:

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

> **Security Note**: Never commit your private API keys to GitHub! Keep your keys local or inject them using `--dart-define`.

### 3. Run the App

#### Web (Chrome)
```bash
flutter run -d chrome
```

#### Windows Desktop
```bash
flutter run -d windows
```

#### Android Emulator
```bash
flutter emulators --launch Medium_Phone
flutter run
```

---

## 🛠️ Tech Stack & Packages

| Package | Version | Purpose |
| :--- | :--- | :--- |
| **`flutter`** | SDK | Core UI Framework |
| **`google_generative_ai`** | `^0.4.7` | Google Gemini AI SDK for model inference & streaming |
| **`firebase_core`** | `^5.1.0` | Firebase initialization & platform configurations |
| **`firebase_auth`** | `^7.0.1` | User authentication & session management |
| **`cloud_firestore`** | `^7.1.0` | Cloud database for chat history persistence |
| **`firebase_ai`** | `^5.1.0` | Firebase Vertex AI integration support |

---

## 📋 Verification & Testing

To verify project code and linter status:

```bash
flutter analyze
```

Expected output:
```
Analyzing ai_chat_app...
No issues found!
```

---

## 📄 License

This project is licensed under the MIT License - feel free to customize and extend it!
