# 38 - Audit & Perbaikan Notifikasi Fisik, Direct Intent All Files Access, dan Multi-Select Visual Effects

**Date:** 2026-11-06  
**Type:** fix / feature  
**Status:** Completed  
**Branch:** main  

---

## 1. Executive Summary

Investigasi mendalam dan perbaikan menyeluruh pada 3 fokus area inti:
1. **Audit & Perbaikan Notifikasi Fisik:** Mengidentifikasi akar penyebab notifikasi tidak muncul di perangkat fisik OEM (Realme/ColorOS), memperbaiki ketersediaan drawable icon resource di seluruh density, mendaftarkan channel `video_processing_channel` dengan level `Importance.high` / `Priority.high`, menambahkan validasi runtime izin, serta menyediakan tombol pengujian diagnostik interaktif di menu pengaturan.
2. **Audit & Perbaikan All Files Access Direct Intent & Banner:** Memperbaiki kegagalan custom URI pada `url_launcher` dengan mengimplementasikan native `MethodChannel` (`id.novrira.videouniquifier/storage_intent`) di `MainActivity.kt` yang langsung memanggil `Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` dengan URI `package:<packageName>`. Menetapkan auto-dismiss `Duration(seconds: 4)` pada banner SnackBar izin.
3. **Multi-Select Toggle Visual Effects Pipeline:** Memperluas state visual effect menjadi multi-select interaktif (tap-to-toggle: klik aktif, klik lagi nonaktif; "None" mematikan seluruh efek). Merangkai filter FFmpeg secara aman dalam 4 tahap terurut (Spatial $\rightarrow$ Temporal $\rightarrow$ Tonal $\rightarrow$ Texture) dengan stream label unik (`[v0]`, `[v1]`, dst.), serta memperbarui `VisualEffectSelectorCard` agar dapat menampilkan seluruh slider kontekstual aktif secara simultan.

---

## 2. Root Cause Analysis & Solutions

### 2.1 Audit Notifikasi Perangkat Fisik

#### Root Cause
1. **Resource Drawable Lookup:** Plugin `flutter_local_notifications` mencari icon menggunakan `Resources.getIdentifier(name, "drawable", packageName)`. Nama icon `ic_notification.png` sebelumnya tidak ada di seluruh folder density, hanya `notification_icon.png`. Selain itu, string `@mipmap/ic_launcher` dengan karakter `@` dapat memicu `resourceId = 0` pada beberapa versi Android jika tidak ada fallback di folder `drawable`.
2. **Channel Importance Caching Android OS:** Channel sebelumnya (`nra_video_processing_channel`) didaftarkan dengan level `IMPORTANCE_LOW` di Android OS. Begitu channel dibuat di perangkat pengguna, Android tidak mengizinkan aplikasi mengubah level importance ke tingkat yang lebih tinggi. Pada ROM OEM (Realme UI / ColorOS / MIUI), channel bertingkat low secara otomatis menyembunyikan status bar icon dan mematikan heads-up pop-up alert.
3. **Progress Details Binding:** `_buildProgressDetails` di `NotificationService` sebelumnya mengikat ke channel bertingkat low tersebut.

#### Fix
1. Menggandakan dan menyelaraskan file asset `ic_notification.png` ke seluruh folder density: `drawable/`, `drawable-mdpi/`, `drawable-hdpi/`, `drawable-xhdpi/`, `drawable-xxhdpi/`, dan `drawable-xxxhdpi/`.
2. Mendaftarkan channel resmi `video_processing_channel` (`Video Processing`) dengan konfigurasi `Importance.high`, `Priority.high`, `playSound: true`, `enableVibration: true`, dan `setShowBadge(true)` baik di layer Kotlin (`MainActivity.kt`) maupun layer Dart (`NotificationService.dart`).
3. Mengubah `processChannelId` pada `NotificationService` ke `video_processing_channel` dan memperbarui `_buildProgressDetails` menjadi `importance: Importance.high`, `priority: Priority.high`.
4. Menambahkan alias validasi izin runtime `requestNotificationsPermission()` di `NotificationService`.
5. Menambahkan tombol aksi interaktif `Test Notification` pada kartu Background & Alerts di `SettingsScreen` yang langsung menembakkan notifikasi diagnostik ke status bar.

---

### 2.2 Direct Intent "All Files Access" & Auto-Dismiss Banner

#### Root Cause
1. `url_launcher` memperlakukan string `android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION:package:...` sebagai skema web URL generik. Intent resolver Android OS menolak skema tersebut karena intent pengaturan sistem memerlukan pemanggilan native `android.content.Intent` dengan URI `package:<packageName>`.
2. Banner SnackBar sebelumnya belum memiliki durasi eksplisit (mengikuti durasi default SnackBar yang panjang).

#### Fix
1. Mengimplementasikan native `MethodChannel` dengan nama channel `id.novrira.videouniquifier/storage_intent` di `MainActivity.kt`:
   - Pada Android 11+ (API 30+): Memanggil `Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:" + applicationContext.packageName))`. Pengguna langsung mendarat pada toggle switch "Allow access to manage all files" khusus untuk NRA Video Uniquifier.
   - Fallback: Memanggil `Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION` atau `Settings.ACTION_APPLICATION_DETAILS_SETTINGS`.
2. Mengintegrasikan MethodChannel ini pada `HistoryService.requestAllFilesAccessDirectly()`.
3. Memperbarui `_showOpenSettingsPrompt()` pada `recent_history_screen.dart` dengan durasi auto-dismiss `const Duration(seconds: 4)` dan tombol aksi "Settings" yang langsung memicu intent native tersebut.

---

### 2.3 Multi-Select Toggle Visual Effects Pipeline

#### State Management (`UniquifierProvider`)
- Menambahkan state `Set<UnifiedVisualEffect> _activeVisualEffects = {UnifiedVisualEffect.none}`.
- Menambahkan getter `Set<UnifiedVisualEffect> get activeVisualEffects`.
- Mengimplementasikan `bool isEffectActive(UnifiedVisualEffect effect)`.
- Mengimplementasikan logika tap-to-toggle di `void toggleVisualEffect(UnifiedVisualEffect effect)`:
  - Jika `effect == UnifiedVisualEffect.none`: set dikosongkan dan diisi `{UnifiedVisualEffect.none}`.
  - Jika efek lain: `none` dihapus dari set. Jika efek sudah ada, dihapus (toggle off). Jika belum ada, ditambahkan (toggle on). Jika set menjadi kosong, otomatis kembali ke `{UnifiedVisualEffect.none}`.
  - Memicu `requestFilteredPreviewDebounced(immediate: true)`.
- Mempertahankan getter `selectedVisualEffect` (mengembalikan efek aktif terakhir non-none atau none) untuk kompatibilitas penuh dengan pemanggil lama.

#### Multi-Stage Filter Chaining (`FilterBuilders` & `FfmpegService`)
- Menambahkan `orderEffectsByStage(Iterable<UnifiedVisualEffect> effects)` untuk mengurutkan efek aktif sesuai standar pipeline 4 tahap:
  1. **Spatial Stage:** `UnifiedVisualEffect.blurredCanvas` (scale foreground 70%-100% di atas background blur).
  2. **Temporal Stage:** `UnifiedVisualEffect.motionEcho` atau `UnifiedVisualEffect.rgbSplit`.
  3. **Tonal Stage:** `UnifiedVisualEffect.dreamyBloom` atau `UnifiedVisualEffect.film16mm`.
  4. **Texture Stage:** `UnifiedVisualEffect.dynamicGrain`.
- Mengimplementasikan `_buildStageSegment` dengan prefix label stream unik per tahap (`bc_`, `me_`, `rs_`, `db_`) agar filtergraph tidak bertabrakan nama label stream antar cabang.
- Mengaitkan input stream pad dan output stream pad berturut-turut:
  - Transformasi linear awal (crop, rotate, unsharp, saturation) mengalirkan output ke `[v0]`.
  - Tahap 1 mengonsumsi `[v0]` dan menghasilkan `[v1]`.
  - Tahap 2 mengonsumsi `[v1]` dan menghasilkan `[v2]`, dst.
  - Tahap akhir menghasilkan stream tanpa label (atau berlabel `[outv]`).
- Memperbarui `FfmpegService.renderFilteredPreviewFrame` agar mendukung output filtergraph berlabel (dengan menyisipkan `;[label] scale=480:-2`) maupun tanpa label (dengan `,scale=480:-2`).

#### UI Selector Card (`VisualEffectSelectorCard`)
- Status aktif kartu preset menggunakan `provider.isEffectActive(item.effect)`.
- Aksi `onTap` memanggil `provider.toggleVisualEffect(item.effect)`.
- Label badge dinamis: menampilkan nama efek jika 1 aktif (e.g. `CANVAS`, `ECHO`, `BLOOM`), `ORIGINAL` jika none, dan `X ACTIVE` jika lebih dari 1 aktif.
- Menampilkan seluruh slider kontekstual aktif secara simultan:
  - Slider `BLURRED CANVAS FOREGROUND SCALE` jika Blurred Canvas aktif.
  - Slider `TEMPORAL CLONE DELAY` jika Echo Delay aktif.
  - Banner deskripsi jika efek tonal/texture lain aktif.

---

## 3. Verification & Quality Gates

### 3.1 Code Formatting
```bash
dart format --set-exit-if-changed lib/ test/
# Formatted 122 files (0 changed) in 0.39 seconds.
# Exit Code: 0
```

### 3.2 Static Analysis
```bash
flutter analyze
# Analyzing nra-video-uniquifier...
# No issues found! (ran in 21.5s)
# Exit Code: 0
```

### 3.3 Test Suite Execution
```bash
flutter test
# 00:27 +212: All tests passed!
# Total Tests: 212 passed, 0 failed, 0 skipped.
# Test Count Growth: 206 -> 212 tests (+6 new unit & widget tests).
```

Rincian pengujian baru yang diverifikasi:
1. `orderEffectsByStage sorts effects in strict 4-stage pipeline order`: verifikasi pengurutan spasial $\rightarrow$ temporal $\rightarrow$ tonal $\rightarrow$ tekstur.
2. `buildPreviewFilterChain chains multi-stage effects with valid stream labels`: verifikasi label `[v0]`, `[v1]`, `[v2]` dan sintaks filtergraph FFmpeg.
3. `toggleVisualEffect supports interactive multi-select and none reset`: verifikasi toggle-on, multi-select, toggle-off, fallback auto-none, dan reset via None.
4. `supports multi-select toggling and displays multiple sliders simultaneously`: widget test interaksi tap-to-toggle dan render slider Blurred Canvas + Motion Echo secara bersamaan.
5. `processChannelId is video_processing_channel with high importance`: verifikasi konstanta channel ID.
6. `requestNotificationsPermission delegates to requestPermission`: verifikasi alias validasi runtime.

---

## 4. Modified Files

| File | Changes |
|------|---------|
| `android/app/src/main/res/drawable-*/ic_notification.png` | Penambahan resource icon notifikasi di seluruh folder density (`drawable`, `mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`) |
| `android/app/src/main/kotlin/id/novrira/videouniquifier/MainActivity.kt` | Setup native MethodChannel `id.novrira.videouniquifier/storage_intent` untuk `ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION` dengan `Uri.parse("package:" + packageName)` |
| `lib/core/services/notification_service.dart` | Channel registration `video_processing_channel` (Importance.high), update `processChannelId`, penambahan fallback icon candidates, dan alias `requestNotificationsPermission()` |
| `lib/core/services/history_service.dart` | Implementasi pemanggilan native `_storageChannel` pada `requestAllFilesAccessDirectly()` dan pembersihan unused import |
| `lib/features/history/screens/recent_history_screen.dart` | Auto-dismiss `Duration(seconds: 4)` pada SnackBar izin dan navigasi direct intent via `HistoryService` |
| `lib/core/providers/uniquifier_provider.dart` | Implementasi `activeVisualEffects`, `toggleVisualEffect`, `isEffectActive`, integrasi multi-stage chaining ke `buildPreviewFilterChain` |
| `lib/core/services/filter_builders.dart` | Implementasi `orderEffectsByStage`, `_buildStageSegment`, dan perakit multi-stage filtergraph berlabel stream pad |
| `lib/core/services/ffmpeg_service.dart` | Robust filter complex parsing untuk filtergraph berlabel stream pad maupun unlabelled |
| `lib/features/process/widgets/visual_effect_selector_card.dart` | UI multi-select tap-to-toggle, badge `X ACTIVE`, dan rendering simultan slider kontekstual |
| `lib/features/settings/screens/settings_screen.dart` | Penambahan tombol uji coba diagnostik status bar `Test Notification` di bawah Background & Alerts |
| `test/notification_service_test.dart` | Unit tests untuk `video_processing_channel` dan `requestNotificationsPermission` |
| `test/unified_effect_preview_test.dart` | Unit tests untuk `orderEffectsByStage`, multi-stage filter builder, dan `toggleVisualEffect` |
| `test/visual_effect_selector_card_test.dart` | Widget tests untuk multi-select dan simultaneous slider rendering |
| `0ai_context/reports/INDEX.md` | Registrasi laporan #38 |
