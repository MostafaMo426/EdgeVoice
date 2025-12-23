# EdgeVoice 🎙️

**EdgeVoice** is a modern, AI-powered voice assistant application built using Flutter. The app features a futuristic "Cyberpunk/Dark Mode" aesthetic, utilizing custom gradients, vector assets, and a secure authentication flow to provide a premium user experience.

---

## 🚀 Features

### 🎨 Modern UI/UX
* **Dark Mode Aesthetic:** A sleek interface using deep gradients (`0xFF1E293B` to `0xFF5270A1`) and Cyan accents (`0xFF00F0FF`).
* **Responsive Layouts:** Optimized for various screen sizes using `Stack`, `Positioned`, and `SafeArea` widgets.
* **Custom Assets:** Integration of high-quality vector graphics and branding elements.

### 🔐 Authentication Flow
* **Welcome Screen:** A branded entry point with a custom logo and smooth navigation.
* **Sign Up:** Complete registration form with real-time validation:
    * Email format checking.
    * Password strength (Length + Uppercase requirements).
    * Password confirmation matching.
* **Login:** Secure email/password entry with "Remember Me" toggle and password visibility controls.

---

## 🛠️ Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Backend Integration:** Firebase Authentication (via `AuthService`)
* **Architecture:** MVC (Model-View-Controller)
* **State Management:** `StatefulWidget`

---

## 📂 Project Structure

```text
lib/
├── screens/
│   ├── welcome_screen.dart       # Landing/Splash page with Logo
│   ├── login_screen.dart         # User Sign-in Logic & UI
│   └── create_account_screen.dart # User Registration Logic & UI
├── services/
│   └── auth_service.dart         # Authentication logic (Firebase)
├── widgets/
│   └── custom_widgets.dart       # Reusable UI components (Inputs, Buttons)
└── main.dart                     # App entry point
```
---
## 📸 Screenshots

| Welcome Screen | Login Screen | Sign Up Screen |
|:---:|:---:|:---:|
| *(Add screenshot here)* | *(Add screenshot here)* | *(Add screenshot here)* |

## 🏁 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/MostafaMo426/edge-voice.git]
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Setup Assets:**
    * Ensure the `assets/images/` folder contains `Logo.jpg`, `Vector.png`, `rafiki.png`, and `rafiki2.png`.
4.  **Run the app:**
    ```bash
    flutter run
    ```
---
## 🗺️ Future Roadmap

We are currently in **Phase 1** of development. Here is the plan to evolve **EdgeVoice** into a fully functional AI assistant.

### 📍 Phase 1: Foundation & Security (Current Status: ✅ In Progress)
- [x] Design High-fidelity UI for Welcome, Login, and Sign Up screens.
- [x] Implement Input Validation (Email regex, Password strength).
- [ ] **Next Step:** Integrate Firebase Auth fully (Connect Sign Up/Login logic to real backend).
- [ ] Create a persistent "User Session" (Auto-login if the user returns).
- [ ] Build the basic `HomeScreen` layout.

### 🗣️ Phase 2: Voice & Audio Core
- [ ] Integrate **Speech-to-Text (STT):** Allow the app to listen to microphone input and convert it to strings.
- [ ] Integrate **Text-to-Speech (TTS):** Give EdgeVoice a voice to respond to the user.
- [ ] Add **Audio Visualizers:** Create a wave or orb animation that reacts to voice volume (UI Polish).
- [ ] Implement Permission Handling (Microphone access requests).

### 🧠 Phase 3: The "Brain" (AI Integration)
- [ ] Connect to an LLM API (OpenAI GPT-4 or Google Gemini).
- [ ] Send converted text (from STT) to the API and receive intelligent responses.
- [ ] Implement "Context Awareness" so the assistant remembers previous questions in the session.

### ⚙️ Phase 4: Personalization & Settings
- [ ] **Profile Management:** Allow users to update their name and profile picture.
- [ ] **Voice Settings:** Options to change the assistant's voice speed, pitch, or language.
- [ ] **Theme Toggle:** Switch between "Cyberpunk Dark" and "Minimalist Light" modes.

### 🚀 Phase 5: Deployment
- [ ] Optimize app performance (reduce asset sizes).
- [ ] Generate release APK/AAB bundles.
- [ ] Publish to Google Play Store.
---
## 👨‍💻 Contributors

* **[Mostafa Mohamed]** - *Initial Work & Development*

## 📄 License

This project is licensed under the MIT License.