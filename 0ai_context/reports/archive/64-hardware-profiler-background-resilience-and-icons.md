# Sprint 64: Hardware Profiler Dinamis, Resiliensi Background, Persistensi Settings, dan Integrasi Ikon Resmi

## 1. Executive Summary
Sprint 64 menyelesaikan 5 target inti pengerasan sistem:
1. **Dynamic Hardware Profiling & Adaptive Resolution Guard**: Mengimplementasikan `DeviceCapabilityService` untuk mengidentifikasi RAM fisik riil, CPU cores, dan dukungan Vulkan Compute. Peringatan termal statis dihapus pada perangkat flagship (>= 12GB RAM) dan disesuaikan secara proporsional pada tier mid dan entry.
2. **Background & Screen-off Resilience**: Menambahkan `WakeLockService` dengan integrasi `PowerManager.PARTIAL_WAKE_LOCK` di native `MainActivity.kt` yang aktif selama pemrosesan video dan dilepas otomatis saat selesai atau dibatalkan. Konfigurasi `AndroidManifest.xml` diperkuat dengan izin foreground service dan atribut `android:foregroundServiceType="dataSync"`.
3. **Settings Persistence Round-Trip**: Memastikan seluruh 15 toggle modifier, slider canvas scale, target resolusi, video codec, dan upscale engine otomatis tersimpan ke `SharedPreferences` dan dimuat ulang tanpa penimpaan ke default saat aplikasi dibuka kembali.
4. **Smooth Monotonic Progress & Stage Descriptions**: Menghilangkan progress jumping dengan monotonic clamping (`rawProgress > maxProgress`), serta menambahkan 5 tahap deskripsi live (`Menyiapkan staging...` hingga `Menyinkronkan ke galeri publik...`) pada `ProcessingScreen`.
5. **Official Icon & Vector Integration**: Mengintegrasikan vektor resmi `warna.svg`, `putih.svg`, dan `hitam.svg`. Merasterisasi launcher mipmaps dengan obsidian background (`#0F1115`) dan safe zone, mengonfigurasi adaptive icon XML, serta menghasilkan siluet putih murni `res/drawable-*/notification_icon.png` untuk Android status bar.

---

## 2. Changes by Component

### A. Hardware Profiling & Adaptive Guard
- **`lib/core/services/device_capability_service.dart`**: Model `DeviceSpecs` dan klasifikasi `DeviceTier` (`entry`, `mid`, `flagship`). Metode `getResolutionWarning()` memberikan teks peringatan kontekstual sesuai tier perangkat.
- **`lib/features/settings/widgets/upscale_resolution_card.dart`**: Menerima parameter `tier` dan menyembunyikan warning badge pada perangkat flagship, menampilkan badge `BEBAN TINGGI` pada mid tier (hanya untuk 4K), dan `RISIKO PANAS / LAMBAT` pada entry tier.
- **`android/app/src/main/kotlin/id/novrira/videouniquifier/MainActivity.kt`**: Handler channel `id.novrira.videouniquifier/device_capability` membaca total RAM via `ActivityManager.MemoryInfo`, core CPU, primary ABI, dan deteksi Vulkan hardware feature.

### B. Background Resilience & WakeLock
- **`lib/core/services/wakelock_service.dart`**: Service bridge untuk acquire dan release `PARTIAL_WAKE_LOCK`.
- **`lib/core/services/ffmpeg_service.dart`**: Memanggil `WakeLockService.acquire()` sebelum pipeline render berjalan dan `WakeLockService.release()` di blok `finally`.
- **`android/app/src/main/AndroidManifest.xml`**: Izin `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_DATA_SYNC`, dan `POST_NOTIFICATIONS` terverifikasi.

### C. Settings Persistence
- **`lib/core/providers/uniquifier_provider.dart`**: Memuat seluruh state persistensi via `_initResolution()` dari `SettingsService` dan menyimpan setiap perubahan toggle, slider, dan dropdown secara instan.
- **`test/hardware_resilience_and_persistence_test.dart`**: Test round-trip memastikan pengaturan tersimpan dan dipulihkan identik saat instansiasi baru provider.

### D. Progress & Stage Tracking
- **`lib/core/services/ffmpeg_service.dart`**: Monotonic clamping pada callback statistik FFmpeg mencegah persentase mundur.
- **`lib/features/process/screens/processing_screen.dart`**: Deskripsi progres multibahasa/tahapan nyata 0%-100% dan step tracking 5 fase (Metadata -> Transform -> Filtergraph -> Encode -> Export).

### E. Official Icon Integration
- **`pubspec.yaml`**: Mendaftarkan `assets/warna.svg`, `assets/putih.svg`, dan `assets/hitam.svg`.
- **`android/app/src/main/res/`**:
  - `mipmap-*/ic_launcher.png`, `ic_launcher_round.png`, `launcher_icon.png` (warna.svg dengan safe zone dan obsidian background).
  - `drawable-*/ic_launcher_foreground.png` (vektor safe zone).
  - `mipmap-anydpi-v26/ic_launcher.xml` dan `launcher_icon.xml` (adaptive icon XML).
  - `drawable-*/notification_icon.png` (siluet putih murni dari putih.svg).
- **`lib/core/services/notification_service.dart`**: Menggunakan resource icon `@drawable/notification_icon`.

---

## 3. Verification & Quality Gates
- **Static Analysis**: `flutter analyze --fatal-infos` -> **0 issues found** (clean).
- **Test Suite**: `flutter test` -> **124/124 tests passed (100%)**.
- **Code Limits**: Seluruh file di `lib/` <= 400 baris dan fungsi <= 40 baris.

---

## 4. MCP Evidence Appendix
- `tools["codebase-memory-mcp"].index_status`: 2059 nodes, 5064 edges, ready.
- `tools["codebase-memory-mcp"].index_repository`: Full re-index repository completed.
