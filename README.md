# LensCopy Mobile 📱

**LensCopy Mobile** brings the full power of the LensCopy Chrome extension to Android and iOS — featuring **100% On-Device Google ML Kit OCR**, **Google Lens interactive tap-to-select**, a **Permanent Clipboard Hub**, **Supabase licensing & referral sync**, and a **Top Taskbar Quick Settings Tile** to scan anything on your screen without leaving other apps.

---

## 🌟 Key Features

1. **Google Lens Interactive Touch Viewport**:
   - Tap individual words or lines to highlight with glowing selection pills.
   - Drag to box-select entire paragraphs or regions.
   - Pinch to zoom and pan high-resolution images.
   - Floating Action Pill with **1-Tap Copy**, **Select All**, **Share**, and **Google Search**.

2. **Top Taskbar / Quick Settings Tile (`Scan Screen`)**:
   - Swipe down from the top of your phone while in *any* app (Instagram, PDF reader, YouTube, locked apps).
   - Tap the **LensCopy Scan** tile.
   - The app instantly snapshots what's on screen and presents the Google Lens selection overlay.

3. **100% On-Device & Offline Privacy**:
   - Powered by **Google ML Kit Text Recognition**.
   - No images, screenshots, or extracted text ever leave your phone.

4. **Permanent Clipboard Hub**:
   - Searchable history of all past copies.
   - Smart automatic tagging (`🔗 Links`, `✉ Emails`, `💻 Code`, `📄 Plain Text`).
   - Pin favorite clips, export, or share with 1 tap.

5. **Unified Supabase Licensing & Referral Rewards**:
   - Connects directly to the existing LensCopy Supabase backend (`https://hkcqjbbpmbvsabqnmqtb.supabase.co`).
   - Shares the same license keys (`LC-XXXX-XXXX-XXXX-XXXX`), daily quotas, and referral bonus days as the Chrome extension.
   - Auto-syncs usage and quotas whenever online.

---

## 🚀 How to Run & Build

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.2.0 or newer)
- Android Studio / Xcode

### Setup
```bash
cd mobile-app
flutter pub get
```

### Run on Connected Device / Emulator
```bash
flutter run
```

### Build Production Android APK
```bash
flutter build apk --release
```
The compiled APK will be at:
`mobile-app/build/app/outputs/flutter-apk/app-release.apk`

---

## 📲 How to Enable the Top Taskbar Tile (Quick Settings)

1. Swipe down twice from the top of your Android phone screen to open the full Quick Settings shade.
2. Tap the **Pencil / Edit** icon.
3. Scroll down to find **LensCopy Scan**.
4. Drag it up into your active top tiles.
5. Done! You can now pull down your top bar and tap **LensCopy Scan** over any app to instantly extract text.
