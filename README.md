# EdgeVoice 🎙️

**EdgeVoice** is a high-end Smart Home controller and voice assistant bridge built with Flutter. It features a sleek "Cyberpunk/Dark Mode" aesthetic, leveraging local TinyML on hardware and a robust .NET backend for a premium user experience.

---

## 🚀 Key Features

### 🎙️ TinyML Voice Integration
*   **Speech-to-Text (STT):** High-accuracy real-time voice recognition for cloud fallback.
*   **Hardware First:** Optimized to work with local TinyML models running on the **Arduino Nano 33 BLE Sense Rev2**.
*   **Auto-Silence Detection:** The assistant intelligently stops listening after 2 seconds of silence.
*   **Real-time Visual Feedback:** Pulse animations and live transcriptions that react to your voice.

### 🏠 Smart Home Ecosystem
*   **Dynamic Room Control:** Manage devices across different rooms (Living Room, Bedroom, Kitchen, etc.) with a modernized grid layout.
*   **Remote Sync & Polling:** Automatically synchronizes device states with the backend every 10 seconds to ensure the UI reflects external changes.
*   **Appliance Monitoring:** Real-time status for critical appliances like fridges, AC units, and washing machines.

### 🎭 Premium UI/UX
*   **Morph Transitions:** Utilizes the `animations` package (Container Transform) for smooth, high-fidelity transitions between screens and cards.
*   **Hero Animations:** Shared element transitions for the App Logo and Profile Picture across Auth and Home screens.
*   **Cyberpunk Aesthetic:** A consistent dark theme using Neon Cyan accents (`0xFF00F0FF`) and deep slate gradients.

### 👤 Profile & Security
*   **Custom Auth Flow:** Secure Login, Sign Up, and Email Verification powered by a dedicated .NET REST API.
*   **Profile Image Uploads:** Full support for uploading and persisting profile pictures using multipart API requests and `XFile`.
*   **JWT Authentication:** Secure token-based sessions with persistent auto-login capabilities.

---

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/) (Dart)
*   **Hardware Platform:** Arduino Nano 33 BLE Sense Rev2 (TinyML)
*   **Backend:** Custom .NET REST API (Hosted on Smarter ASP)
*   **Networking:** `Dio` for robust API communication and multipart uploads.
*   **State Management:** `Provider` for clean reactive updates.
*   **Animations:** `animations` (Google), `TweenAnimationBuilder`.

---

## 📂 Project Structure

```text
lib/
├── screens/
│   ├── welcome_screen.dart     # Landing page with Hero logo
│   ├── login_screen.dart       # Morphing Auth UI
│   ├── create_account_screen.dart # Form-validated registration
│   ├── home_screen.dart        # Master Dashboard with Voice UI
│   ├── rooms_screen.dart       # Room-specific device toggles
│   ├── logs_screen.dart        # Real-time command/action history
│   └── settings_screen.dart    # Profile management & Device pairing
├── services/
│   ├── auth_service.dart       # JWT Auth & Profile image logic
│   └── api_service.dart        # Smart Home API communication
├── providers/
│   ├── edgevoice_voice_provider.dart # Voice logic handler
│   └── device_pairing_provider.dart  # Hardware linking state
└── main.dart                   # Multi-provider initialization
```

---

## 🏁 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/MostafaMo426/EdgeVoice.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **API Configuration:**
    Ensure `lib/config.dart` has the correct `apiBaseUrl`.
4.  **Run the app:**
    ```bash
    flutter run
    ```

---

## 🗺️ Progress Roadmap

### ✅ Phase 1: Foundation & Security (Completed)
- [x] Custom .NET API Integration (Replacing Firebase).
- [x] JWT Token Persistence & Secure Storage.
- [x] Email Verification & Password Change flows.

### ✅ Phase 2: Smart Home & UI (Completed)
- [x] **Morphing UI:** Container transforms for room cards.
- [x] **Profile System:** Multi-platform image upload & persistence.
- [x] **Dynamic Polling:** Real-time state syncing with the server.

### ✅ Phase 3: Voice Core (Completed)
- [x] **Speech-to-Text:** Live transcription with visual feedback.
- [x] **TinyML Bridge:** Communication logic for Arduino hardware.
- [x] **Auto-Stop Logic:** Silence detection for hands-free usage.

### 🚧 Phase 4: Final Milestone (Pending)
- [ ] **Physical Device Linking:** Establishing the secure handshake and control link between the Flutter app and the actual **EdgeVoice Hardware Device**.

---

## 👨‍💻 Contributors

*   **Mostafa Mohamed** - *Lead Developer*

## 📄 License

This project is licensed under the MIT License.
