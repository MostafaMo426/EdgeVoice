# EdgeVoice Mobile Application: Technical Documentation

## 1. Project Overview & Architecture

### 1.1 Role of the Application
The **EdgeVoice Mobile Application** serves as the primary control plane and user interface for the EdgeVoice Smart Home Ecosystem. The **Arduino Nano 33 BLE Sense Rev2** hardware handles local, low-latency voice processing using a custom-trained **TinyML model**, while the Flutter application provides a centralized dashboard for cross-device management, hardware orchestration, and remote control.

### 1.2 System Architecture
The application follows a hybrid distributed architecture, acting as the intelligent bridge between the user and the EdgeVoice hardware. It implements an **Automatic Hybrid Link** strategy:
*   **Proximity Path (BLE):** Direct, low-latency communication via **Bluetooth Low Energy (BLE)** GATT characteristics when the user is near the device.
*   **Remote Path (Cloud):** Global synchronization through a cloud-based **.NET REST API** when the user is outside the local Bluetooth range.

![EdgeVoice System Architecture](docs/images/architecture_diagram.png)  
*Tip: Save a Mermaid or LucidChart diagram here showing the flow: [User] <-> [Flutter App] <-> [REST API] and [Flutter App] <-> [Arduino Nano via BLE].*

---

## 2. Tech Stack & Dependencies

The application is built using the **Flutter SDK**, leveraging the **Dart** programming language with a modernized Android build system (**Gradle 8.14**, **Kotlin 2.2.20**).

### 2.1 Core Dependencies
*   **State Management:** `Provider` & `ChangeNotifierProxyProvider` — Manages reactive UI updates and cross-provider communication (e.g., Voice logic responding to BLE connection state).
*   **Hardware Connectivity:** `flutter_blue_plus` — Handles BLE device discovery, GATT connections, and characteristic writes.
*   **Networking:** `Dio` — Utilized for RESTful communication, JWT interceptors, and multipart profile uploads.
*   **Motion Design:** `animations` — Implements high-end Material Motion (Shared Z-axis, Container Transform).
*   **Security:** `app_settings` — Direct integration with system Bluetooth settings for streamlined pairing.

---

## 3. App Architecture & Folder Structure

EdgeVoice employs a **Layered Architecture** pattern, separating infrastructure (Services), business logic (Providers), and presentation (Screens/Widgets).

```text
lib/
├── config.dart             # API endpoints & Global constants
├── main.dart               # Multi-provider initialization & Auth routing
├── providers/              # State management & Logic controllers
│   ├── device_pairing_provider.dart  # BLE connection & GATT logic
│   └── edgevoice_voice_provider.dart # Voice processing & Hybrid routing
├── screens/                # UI Views
│   ├── welcome_screen.dart     # Landing page
│   ├── login_screen.dart       # Morphing Auth view
│   ├── create_account_screen.dart
│   ├── forgot_password_screen.dart # Email-based code request
│   ├── reset_password_screen.dart  # OTP Verification & Password reset
│   ├── verify_email_screen.dart
│   ├── home_screen.dart        # Master Dashboard
│   ├── rooms_grid_screen.dart  # Room & Device orchestration
│   ├── logs_screen.dart        # Activity history
│   ├── settings_screen.dart    # User profile & Pairing access
│   └── pairing_screen.dart     # BLE discovery UI
├── services/               # Infrastructure layer
│   ├── api_service.dart        # Cloud REST API wrapper
│   ├── auth_service.dart       # JWT Auth & Profile image logic
│   └── voice_command_service.dart
└── widgets/                # Reusable UI components
```

---

## 4. Core Features & User Interface

### 4.1 Intelligent Voice Assistant
Features a "Pulsing Mic" interface with real-time feedback.
*   **Visual States:** Cyan (Listening), **Neon Yellow (Processing)**, and Green (Success).
*   **Memory Management:** Automatic memory wipe upon command completion or app restart to ensure a clean user state.
![Voice UI](docs/images/voice_ui.png)

### 4.2 Global Quick Actions
Dynamic toggle system that scans all rooms to perform bulk operations (e.g., "Turn off ALL lights", "Secure ALL doors") without hardcoded device mappings.

### 4.3 Secure Account Recovery
Integrated **Forgot Password flow** using OTP (One-Time Password) verification, allowing users to securely reset passwords with enforced strength rules.

### 4.4 High-Fidelity Room Morphing
Uses **Container Transforms** to morph room cards into detailed device controllers, maintaining visual context and state sync (10s polling).

---

## 5. State Management & Data Flow

EdgeVoice utilizes the **Observer Pattern** with a focus on Hybrid Routing:

1.  **User Action:** User initiates a voice command.
2.  **Provider Check:** `EdgeVoiceVoiceProvider` checks the `DevicePairingProvider` for an active BLE connection.
3.  **Command Routing (Text-Only):** 
    *   The application performs **Local Speech-to-Text** and extracts the command as a String.
    *   **Local Mode:** If connected via BLE, the text is encoded to UTF-8 bytes and written to the Arduino GATT characteristic. **No voice file is transmitted**.
    *   **Cloud Mode:** If disconnected, the command is transmitted as a JSON payload (`keyword`) via the cloud `ApiService`.
4.  **Global Log:** The action is logged to the server regardless of the path for consistent history tracking.
5.  **State Reset:** The `finally` block wipes temporary command strings to reset the UI to "Touch to Speak".

---

## 6. Hardware Integration & Communication

### 6.1 Proximity Handshake
The app manages the GATT lifecycle for the **Arduino Nano 33 BLE Sense Rev2**:
*   **Service UUID:** `19B10000-E8F2-537E-4F6C-D104768A1214`
*   **Command Characteristic:** `19B10001-E8F2-537E-4F6C-D104768A1214`

### 6.2 TinyML Synchronization
The hardware executes the TinyML model locally. The Flutter app acts as the "Rich UI" for this model, reflecting sensor data and command inferences back to the user in a visual format.

---

## 7. Setup & Installation Guide

### Prerequisites
*   Flutter SDK (^3.24.0)
*   Smartphone with Bluetooth 5.0+ support
*   Android 11+ (API 30+) for full BLE functionality

### Installation Steps
1.  **Clone & Clean:**
    ```bash
    git clone https://github.com/MostafaMo426/EdgeVoice.git
    flutter clean && flutter pub get
    ```
2.  **Configure:** Update `lib/config.dart` with your `.NET` backend endpoint.
3.  **Build:**
    ```bash
    flutter build apk --release
    ```
