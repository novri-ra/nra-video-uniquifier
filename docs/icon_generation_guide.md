# Icon Generation & Customization Guide

This guide details the procedure for replacing the default Flutter placeholder icon with a branded adaptive icon for Google Play Store production submission.

---

## 1. Icon Specifications

### A. Google Play Store High-Res Icon
- **Dimensions**: 512 × 512 pixels
- **Format**: 32-bit PNG (with alpha)
- **Max file size**: 1024 KB
- **Corner radius / Shadow**: Submit square with sharp corners; Google Play applies the squircle mask and drop shadow automatically.

### B. Android Adaptive Icon Specification
- **Canvas Size**: 108 × 108 dp
- **Safe Zone (Key Art)**: 72 × 72 dp centered inside the 108 dp canvas (inner 66% area). Anything outside this circle/squircle may be clipped by device launchers.
- **Background Layer**: 108 × 108 dp solid color (`#1A1A1A` recommended) or subtle dark pattern.
- **Foreground Layer**: 108 × 108 dp transparent PNG with centered symbol/logo fitting within the 72 dp safe zone.

### C. Standard Android Mipmap Densities
| Density | Total Canvas (px) | Safe Zone (px) | Directory |
|---|---|---|---|
| **mdpi** (1x) | 48 × 48 | 32 × 32 | `android/app/src/main/res/mipmap-mdpi/` |
| **hdpi** (1.5x) | 72 × 72 | 48 × 48 | `android/app/src/main/res/mipmap-hdpi/` |
| **xhdpi** (2x) | 96 × 96 | 64 × 64 | `android/app/src/main/res/mipmap-xhdpi/` |
| **xxhdpi** (3x) | 144 × 144 | 96 × 96 | `android/app/src/main/res/mipmap-xxhdpi/` |
| **xxxhdpi** (4x) | 192 × 192 | 128 × 128 | `android/app/src/main/res/mipmap-xxxhdpi/` |

---

## 2. Recommended Online Generation Tools

1. **[Icon Kitchen](https://icon.kitchen/)** (Recommended)
   - Supports text, clipart, or custom SVG/PNG upload.
   - Automatically generates Android adaptive icon packages, notification icons, and Play Store 512x512 assets with correct safe-zone padding.
2. **[AppIcon.co](https://www.appicon.co/)**
   - Quick drag-and-drop generator providing complete zip files for Android and iOS asset folders.

---

## 3. Automated In-Project Regeneration Workflow

Once you have your source 1024×1024 PNG logo, follow these steps to generate all mipmap density assets automatically:

### Step 1: Save Source Assets
Place your artwork in the project root:
- `assets/icon/icon_1024.png` (Full 1024×1024 icon for legacy launchers)
- `assets/icon/icon_foreground_1024.png` (Transparent logo for adaptive foreground)

### Step 2: Add Generator Dependency
```bash
flutter pub add flutter_launcher_icons --dev
```

### Step 3: Configure `pubspec.yaml`
Add this configuration block at the bottom of `pubspec.yaml`:
```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: false
  image_path: "assets/icon/icon_1024.png"
  min_sdk_android: 24
  adaptive_icon_background: "#1A1A1A"
  adaptive_icon_foreground: "assets/icon/icon_foreground_1024.png"
```

### Step 4: Run Icon Generation Command
```bash
dart run flutter_launcher_icons
```

This will automatically create and replace all files in `android/app/src/main/res/mipmap-*/ic_launcher.png` and configure the adaptive icon XML definitions in `android/app/src/main/res/mipmap-anydpi-v26/`.
