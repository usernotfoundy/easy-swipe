# 📸 EasySwipe

**EasySwipe** is a modern, intuitive Flutter application designed to make cleaning up your phone's photo gallery effortless and fun. Using familiar Tinder-style swipe gestures, you can rapidly sort through your photos, hold unwanted pictures in a safe staging queue, and review them before confirming permanent batch deletion.

---

## ✨ Features

- **👉 Swipe Right to Keep**: Keep memories you love with a satisfying green stamp animation.
- **👈 Swipe Left to Delete (Staged Hold)**: Unwanted photos are never deleted immediately—they are placed into a temporary delete queue so you can swipe fast without fear of accidents.
- **🎯 Choose Where to Start Swiping**:
  - Open the starting point selector grid from the top bar or by tapping the progress header.
  - Tap any photo in your album (e.g., photo `#35`) to jump directly to it and swipe downwards from there.
  - Optional toggle to automatically mark all previous photos as **Kept**.
- **🗑️ Batch Deletion & Trash Review**:
  - Tap the trash badge in the top bar to review all swiped-left photos.
  - **Multi-select**: Check or uncheck individual photos to include or exclude them from deletion.
  - **Restore to Keep**: Instantly restore individual photos or all deselected photos back to your gallery.
  - **Storage Savings Preview**: Displays estimated storage space to be freed in MB.
  - **Safety Confirmation**: Explicit native confirmation dialog before permanent deletion.
- **🔄 Quick Undo**: Accidentally swiped the wrong way? Use the undo button to immediately retrieve the previous card.
- **🚀 Full Album Loading with Lazy Sizing**:
  - Loads entire albums (no 150-photo limit) with instant startup.
  - Asynchronously computes file sizes in the background to ensure zero lag.
- **📁 Album Selector & Demo Mode**:
  - Switch between device albums (Camera, Screenshots, Downloads, etc.).
  - Built-in **Sample Demo Mode** with high-resolution images for quick testing or emulators.
- **🔍 Detailed Photo Inspector & Full-Screen Zoom**:
  - View creation date, resolution, file size, and storage path.
  - Long-press any photo in the Review screen to view it full-screen with pinch-to-zoom.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart 3)
- **State Management**: Built-in reactive `ChangeNotifier` + `ListenableBuilder`
- **Gallery & Media**: [`photo_manager`](https://pub.dev/packages/photo_manager) & [`photo_manager_image_provider`](https://pub.dev/packages/photo_manager_image_provider)
- **Formatting**: [`intl`](https://pub.dev/packages/intl)
- **UI Design**: Modern dark theme with custom physics-based swipe cards

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (v3.13.0 or higher)
- Android Studio / Xcode (for device builds)
- A connected physical device or emulator

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/usernotfoundy/easy-swipe.git
   cd easy-swipe
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

---

## 📱 Permissions Setup

### Android (`android/app/src/main/AndroidManifest.xml`)
The following permissions are configured for device media access:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
<uses-permission android:name="android.permission.ACCESS_MEDIA_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)
Photo library permissions are declared:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>EasySwipe requires access to your photos to help you review and organize your gallery.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>EasySwipe requires permission to manage photos in your gallery.</string>
```

---

## 📂 Project Structure

```text
lib/
├── main.dart                          # App entrypoint and dark theme definition
├── models/
│   └── photo_item.dart                # Photo data model, swipe history records, and lazy size resolution
├── services/
│   └── gallery_service.dart           # Device photo loading, permissions, deletion, and sample demo data
├── state/
│   └── gallery_state.dart             # Central state manager (deck index, keep list, delete queue, undo)
├── widgets/
│   ├── swipe_card.dart                # Interactive Tinder card with rotation, stamps, and gesture isolation
│   ├── swipe_controls.dart            # Floating circular action buttons (Undo, Delete, Info, Keep)
│   └── photo_info_dialog.dart         # Bottom sheet displaying photo metadata
└── screens/
    ├── home_screen.dart               # Main deck view, album picker, and progress bar
    ├── review_screen.dart             # Staged delete queue review, multi-select, and confirmed batch delete
    └── select_start_photo_screen.dart # Visual gallery grid to jump to any starting point
```

---

## 💡 How It Works

1. **Swipe**: Flick right to keep, flick left to stage for deletion.
2. **Jump Anytime**: Tap the progress bar or the top grid button to select a new starting point.
3. **Review**: Open the trash review screen anytime to verify staged photos and restore any false positives.
4. **Clean**: Tap "Confirm Delete" to permanently clean up your device storage.

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
