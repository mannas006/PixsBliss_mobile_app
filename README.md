
# PixsBliss Mobile App

PixsBliss is a beautiful, modern Flutter wallpaper app that allows users to browse, upload, and manage high-quality wallpapers. It features seamless integration with Firebase and Pexels, a stunning UI, and a rich set of features for both users and developers.

---

## ✨ Features

- **User-uploaded wallpapers** (Firebase/Firestore)
- **Curated wallpapers** from Pexels
- **Trending & Featured** sections
- **Category browsing** (Firebase & Pexels)
- **Favorites & Search**
- **Light & Dark theme support**
- **Modern UI** with skeleton loading animations
- **Responsive design** for all devices
- **Smooth performance** and offline support

---

## 🚀 Getting Started

### 1. Clone the Repository
```sh
git clone <your-repo-url>
cd PixsBliss_mobile_app
```

### 2. Install Dependencies
```sh
flutter pub get
```

### 3. Configure Firebase
- Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective folders.
- See [`Docs/FIREBASE_SETUP.md`](Docs/FIREBASE_SETUP.md) for full setup instructions.

### 4. Run the App
```sh
flutter run
```

---

## 🛠️ Tech Stack
- **Flutter** (cross-platform mobile framework)
- **Firebase** (Firestore, Auth, Storage)
- **Cloudinary** (image hosting)
- **Pexels API** (curated wallpapers)
- **Riverpod** (state management)
- **Hive** (local storage)
- **Dio** (networking)
- **Lottie, Shimmer, Glassmorphism** (UI/UX)

---

## 📸 Screenshots
_Add screenshots here to showcase the app UI._

---

## 📂 Project Structure
- `lib/` — Main app code (features, core, shared)
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` — Platform-specific code
- `Docs/` — Setup and migration guides

---

## 🙏 Credits
- Wallpapers from [Pexels](https://www.pexels.com/)
- Built with [Flutter](https://flutter.dev/)

---

## 📄 License
MIT
