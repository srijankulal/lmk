# LMK (Let Me Know) 📱⚡

> **Never miss a deadline or document expiration again.**  
> Smart, offline-first document expiry and renewal reminder application built with Flutter, Isar, Firebase, and Google Gemini AI OCR.

---

## ✨ Features

- 📑 **Smart AI Document Scanner**: Take a picture or select an image of your passport, driver's license, vehicle insurance, or bills. Google Gemini automatically extracts the document title, category, issue date, and expiry date.
- 🗂️ **Dynamic Document Categorization**: Automatically identifies and assigns tailored 3D embossed category icons (Passports, Visas, Medical, Vehicles/PUC, Bills/Finance, Real Estate, Warranties, and Work/Education).
- 🗃️ **Cascading Card Deck**: Beautiful tactile stacked cards with downward drop shadows, smooth slide animations, and urgent countdown indicators.
- 🔔 **Customizable Audio Alarms**: Choose from 5 custom notification sounds (Chime, Gentle Marimba, Tactile Pulse, Faahh, or Classic Alert) with immediate sound preview.
- 🛑 **Full-Screen Intent Alerts**: Toggle between full-screen alarm takeovers and standard high-priority heads-up banners.
- 🔄 **Smooth Cloud & Offline Sync**: Fully functional offline with Isar database local storage, instant pull-to-refresh sync, and cloud synchronization with Express API.
- 🎨 **Minimalist & Glassmorphic UI**: Calibrated dual-theme palette with fluid animations, dynamic blur surfaces, and zero clutter.

---

## 🏗️ Architecture & Tech Stack

- **Frontend**: Flutter (FVM 3.8.x), Dart 3
- **State & Theming**: Reactive Listenables, Shadcn UI Flutter, custom glassmorphism
- **Local Database**: [Isar Database](https://isar.dev/) for high-performance offline persistence
- **Cloud Backend**: Express.js API deployed on Vercel with JWT auth
- **Notifications**: `flutter_local_notifications` with scheduled alarm intents and dynamic sound channels
- **Authentication**: Firebase Auth with Google Sign-In

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (or FVM)
- Android Studio / Xcode
- Java JDK 21

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/srijankulal/lmk.git
   cd lmk
   ```

2. **Install dependencies**:
   ```bash
   fvm flutter pub get
   ```

3. **Run on connected device/emulator**:
   ```bash
   fvm flutter run
   ```

4. **Build Beta Release APK**:
   ```bash
   fvm flutter build apk --release
   ```

---

## 📦 Release Information

- **Current Version**: `0.1.0 (Alpha)`
- **Target SDK**: Android 34 / 35 (Android 14/15 ready)
- **Minimum SDK**: Android 21 (Lollipop+)
