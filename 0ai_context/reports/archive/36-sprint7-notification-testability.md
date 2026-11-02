# Laporan 36: Sprint 7 — Testabilitas NotificationService & Penutupan Utang Struktural P2-L

## 1. Executive Verdict

- **P2-M (NotificationService Testability & Real Mock Tests)**: **DONE** — Hook `@visibleForTesting` (`testOverride` dan `initialized`) ditambahkan ke `NotificationService`. Seluruh 5 pengujian unit platform-guarded di `test/notification_service_test.dart` ditulis ulang dengan assertion payload MethodChannel riil (`initialize`, `checkPermissionStatus`, `show` dengan ongoing progress & importance, `cancel`). Ditambah 1 pengujian batch notification di `test/batch_queue_provider_test.dart` yang memverifikasi supresi notifikasi per-item dan emisi tunggal notifikasi ringkasan batch. Komit: `a2735d8`.
- **P2-L-CLOSE (Close P2-L in Report 32)**: **DONE** — Status P2-L di Laporan 32 resmi ditutup dengan status `DONE (effective via Sprint 5/6)`. Berkas `ffmpeg_service.dart` kini berukuran 325 LOC (75 LOC slack), `settings_screen.dart` berukuran 305 LOC (95 LOC slack), dan `uniquifier_provider.dart` berukuran 367 LOC (33 LOC slack). Dekomposisi sub-helper in-file tidak lagi diperlukan.
- **L2 Widget Skill Check**: **COMPLETE** — Skill `flutter-widget-decomposition` telah dibuat oleh Hermes di akhir Sprint 6 dan memuat seluruh kriteria: waktu ekstraksi, pola konstruktor (props in, callbacks out), dan larangan tegas forwarder untuk widget.
- **V37–V40 Preflight**: Seluruh verifikasi preflight lulus 100%.

| Item ID | Status | Deskripsi | Commit SHA |
|---|---|---|---|
| **P2-M** | DONE | Hook `_testOverride` pada `NotificationService` & 5 tes MethodChannel riil + 1 tes batch supresi | `a2735d8` |
| **P2-L-CLOSE** | DONE | Penutupan resmi P2-L di Laporan 32 berdasarkan pengukuran riil slack seluruh berkas | `a2735d8` |
| **L2 Check** | COMPLETE | `flutter-widget-decomposition/SKILL.md` terverifikasi lengkap (3/3 kriteria) | n/a |
| **V37** | PASS | Total berkas Dart di `lib/` terkonfirmasi tepat 35 berkas; seluruh berkas <= 367 LOC | n/a |
| **V38** | PASS | `ffmpeg_service.dart` 325 LOC; `processVideo` body 84 baris; slack 75 baris memadai | n/a |
| **V39** | PASS | `NotificationService` memiliki 5 metode platform-guard, 135 LOC awal, 0 anotasi pengujian | n/a |
| **V40** | PASS | 5 dari 5 tes notifikasi lama terbukti false-green (hanya memeriksa `completes` saat early-exit) | n/a |

---

## 2. Rincian L2 Detail (`flutter-widget-decomposition/SKILL.md`)

Inspeksi berkas `C:/Users/Administrator/AppData/Local/hermes/skills/devops/flutter-widget-decomposition/SKILL.md` (ukuran: 4.604 bytes, SHA: `a516c62a...`):

1. **Kapan Mengekstrak Sub-Widget Privat dari `build()` vs Membiarkannya Inline**:
   - `flutter-widget-decomposition/SKILL.md:14-20` (When to Use): Digunakan saat berkas mendekati plafon (> 350 baris), atau metode `build()` membengkak karena sub-widget privat.
   - `flutter-widget-decomposition/SKILL.md:26-30` (Seksi 1): "Primary Candidates: Sub-widgets with large line spans (>= 50 LOC) that represent a single cohesive visual section...".
   - `flutter-widget-decomposition/SKILL.md:51-55` (Seksi 4: Stop Rule): "Once the parent file is safely below the ceiling, keep remaining small sub-widgets (< 40 lines, e.g. section headers or app info cards) inlined in the screen file. Over-extracting small widgets introduces unnecessary file sprawl without architectural payoff."
2. **Pola Konstruktor (Props In, Callbacks Out)**:
   - `flutter-widget-decomposition/SKILL.md:28` (Seksi 1): "Parameter Shape: Prefer sub-widgets that accept pure primitives, enums, or model data with callback hooks (`VoidCallback`, `ValueChanged<T>`)."
   - `flutter-widget-decomposition/SKILL.md:42-48` (Seksi 3): Mencontohkan passing nilai dan event handlers secara eksplisit:
     ```dart
     CodecSelectorCard(
       currentCodec: provider.videoCodec,
       onSelect: provider.setVideoCodec,
     )
     ```
3. **Larangan Eksplisit Stub Forwarder untuk Widget**:
   - `flutter-widget-decomposition/SKILL.md:49-50` (Seksi 3): "Rule: Do not create widget forwarders or alias stubs in the screen file. Unlike public static methods, private widget classes have no external callers across other files or unit tests. Import and instantiate the new public class directly."
   - `flutter-widget-decomposition/SKILL.md:67-71` (Pitfalls): "### Never Create Forwarder Stubs for Private Widgets. Rule: Do not leave `class _ExtractedWidget extends ExtractedWidget` stubs in the original screen file. Why: Stubs consume line budget in the file being shrunk and serve no purpose because internal private widgets have no external callers or test contracts."

Vonis: **COMPLETE (Seluruh 3 kriteria terpenuhi secara eksplisit dengan sitasi baris)**.

---

## 3. Preflight Table (V37 – V40)

| ID | Pertanyaan | Bukti | Vonis | Tindakan |
|---|---|---|---|---|
| **V37** | Verifikasi jumlah berkas `lib/` | `find lib/ -name "*.dart" \| wc -l` menghasilkan 35 berkas. 10 berkas terpanjang memiliki rentang 253 - 367 baris. | `35 files — matches` | Terverifikasi presisi |
| **V38** | Kelayakan penutupan P2-L | `ffmpeg_service.dart`: 325 baris. `processVideo(...)`: baris 180-284 (105 baris total, body eksekusi 84 baris). Seluruh berkas target memiliki slack >= 33 LOC. | `processVideo <= 100 lines body — P2-L can be closed` | Tutup P2-L di Laporan 32 |
| **V39** | Struktur awal `NotificationService` | 135 baris total, 5 metode statis memiliki guard `Platform.isAndroid` (`init`, `requestPermission`, `showProgressNotification`, `cancelProgressNotification`, `showCompleteNotification`), 0 anotasi `@visibleForTesting`. | `5 methods with platform guard, 135 LOC total` | Tambahkan hook testOverride |
| **V40** | Audit false green pengujian notifikasi lama | `test/notification_service_test.dart`: seluruh 5 pengujian hanya mengecek `completes` / `isTrue` saat method langsung return karena bukan Android. | `5 of 5 tests are false green` | Tulis ulang di P2-M |

---

## 4. Rincian Refaktor `NotificationService` & Restorasi Pengujian

### Hook Testabilitas pada `NotificationService`
Ditambahkan ke `lib/core/services/notification_service.dart`:
```dart
  static bool? _testOverride;
  @visibleForTesting
  static set testOverride(bool? value) => _testOverride = value;
  @visibleForTesting
  static set initialized(bool value) => _initialized = value;
  static bool get _canRun => _testOverride ?? Platform.isAndroid;
```
Seluruh pemeriksaan platform digantikan dengan `_canRun`.
Metrik LOC: 135 baris -> **142 baris** (mematuhi batas target <= 150 LOC dan batas mutlak <= 400 LOC).

### Restorasi 5 Pengujian Unit NotificationService
File: `test/notification_service_test.dart`
- Inisialisasi: `AndroidFlutterLocalNotificationsPlugin.registerWith()`, `debugDefaultTargetPlatformOverride = TargetPlatform.android`, `NotificationService.testOverride = true`.
- Mock channel dipasang pada `dexterous.com/flutter/local_notifications` dan `flutter.baseflow.com/permissions/methods`.
- Daftar pengujian baru dengan verifikasi payload:
  1. `init invokes initialize on local notifications channel`: Memverifikasi pemanggilan method `initialize` dengan argumen settings non-null.
  2. `requestPermission invokes checkPermissionStatus on permission channel and returns true`: Memverifikasi permission check status.
  3. `showProgressNotification invokes show with ongoing progress payload`: Memverifikasi payload `id: 8801`, `showProgress: true`, `progress: 50`, `ongoing: true`, `title`, dan `body`.
  4. `cancelProgressNotification invokes cancel with progressNotificationId`: Memverifikasi pembatalan notifikasi progres dengan `id: 8801`.
  5. `showCompleteNotification cancels ongoing progress and invokes show with high importance`: Memverifikasi pembatalan notifikasi progres berjalan dan penayangan alert sukses dengan `id: 8802`, `channelId: video_complete_channel`, dan `playSound: true`.

### Restorasi Pengujian Supresi Notifikasi Batch (D5-02 / P2-I)
File: `test/batch_queue_provider_test.dart`
- Menjalankan batch 3-item dengan `runBatch(dummyConfig)`.
- Menginspeksi log emisi `NotificationService.completeNotificationId` via mock channel.
- Asersi tegas: `expect(completeCalls.length, 1)` membuktikan intermediate per-item notifications disupresi penuh (`suppressCompleteNotification: true`) dan hanya satu notifikasi ringkasan yang dikirim saat batch selesai (`Batch Processing Finished`).

---

## 5. Test Delta

- `flutter test` pasca implementasi P2-M:
  - **100 passed**, **0 failed**, **0 skipped** (sebelumnya 99 passed).
  - Waktu eksekusi: 24 detik.
  - Zero skips di seluruh suite pengujian repositori.

---

## 6. Skill Delta (Sprint Ini)

### Block L4 — Pre-Sprint Fingerprint (Sprint 7)
```
2026-10-30 13:15:17 5102  flutter-provider-decomposition/SKILL.md | 30f223676252cdb323b85320fa11c0fdd34129bb6d480adac920b6534e808d9f
2026-10-30 10:32:25 19169 flutter-state-and-testing/SKILL.md      | bb9494c51f7513f04c80322ac80a3e1e0e40a711c65f5ee8014c994422737e36
2026-10-30 13:15:06 4604  flutter-widget-decomposition/SKILL.md   | a516c62a22810c8600612b2248ff779a3cc17b344aa5d973c6fd3c187f7e10dc
2026-09-19 17:50:08 9073  sdlc-review/SKILL.md                   | ce90e8a3e145cce69c62880dc85921700110879f9290952d6cec28218503155f
2026-10-11 22:34:10 2778  windows-bluetooth-management/SKILL.md  | c2e5f46338d75f6f6b8297c3dc562e1c7ccd3a850bbb7f7881688cec717d2533
2026-10-11 22:40:40 8788  windows-driver-management/SKILL.md     | b5485bd3cec6d6d075b12542470228ebedf679513ca552e91621c133bc7a3ada
2026-10-27 20:07:49 13325 windows-native-scripting/SKILL.md      | 044d9ddec10eae7bd731ce977d4f48445a9324988d29d54432d8b41e8f86e513
2026-10-27 21:15:16 15850 windows-software-cleanup/SKILL.md      | 7133fafea15c5dfe2163c582b8f5754e115765bf105deb70dc5d99126c8d7a6f
2026-10-10 02:05:25 15679 windows-system-health/SKILL.md         | d5caaea22a2171272748f3b1fbded24b52f2278aba283471abd37c02d877d9f7
2026-10-30 13:02:09 22629 multimedia-pipeline-engineering/SKILL.md| b16d110344891169d698fe62671d91fc89728bad1b2da4d8ee26f1fdbabec80a
```

### Directive Issued (Verbatim dari Section 0B)
```
LEARNING DIRECTIVE (MANDATORY):
  Acquire:
    - flutter-widget-decomposition: if it does not exist yet, create it.
      Must include: (a) when to extract a private sub-widget class from
      a build() body vs keep inline, (b) required constructor pattern
      for extracting stateful widgets (props in, callbacks out), (c)
      verification via existing widget tests without adding new tests,
      (d) the "no forwarder for widgets" distinction (widgets are
      instantiated not called, so no delegating stub is needed).
    - notification-service-testability: the pattern for adding a
      @visibleForTesting static override to a service that guards on
      Platform.isAndroid, allowing unit tests to execute the real
      notification logic on host Windows by mocking MethodChannel
      handlers instead of skipping.
  Do NOT acquire:
    - false-green-restoration: do not write tests that only verify
      "completes without throwing". Every restored notification test
      must assert on the mocked MethodChannel invocation payload.
    - skill-proliferation: if flutter-widget-decomposition already
      exists in any form, do not create a duplicate. Consolidate.
  Prune:
    - Any skill rule that recommends testing platform-guarded code
      by simply calling the method and asserting no exception. This
      is the false-green anti-pattern already captured in
      flutter-state-and-testing Rule 23, but should be reinforced
      wherever else it appears.
  Preserve:
    - flutter-state-and-testing Rules 22, 23, 24
    - flutter-provider-decomposition forwarder qualification
    - multimedia-pipeline-engineering filter order protocol
```

### Expected Sprint 8 Verification
"Verify that (a) `flutter-widget-decomposition` maintains the 'no forwarder for widgets' rule and constructor extraction pattern, and (b) `notification-service-testability` pattern (injectable platform test override + MethodChannel payload assertion) is codified into state/testing skills."

---

## 7. Final MCP Baseline

- **Sprint 6 Baseline**: 1467 nodes / 3729 edges
- **Sprint 7 Final Baseline**: **1492 nodes / 3771 edges** (Status: `indexed`, 0 parse unusable, 11 excluded dirs, 54 ignored files).
- **Penjelasan Selisih**: Kenaikan 25 nodes dan 42 edges berasal dari penambahan pengujian terperinci di `test/notification_service_test.dart`, `test/batch_queue_provider_test.dart`, serta berkas laporan Sprint 6 dan 7.

---

## 8. Appendix MCP Evidence

| Tool Nama | Argumen Kueri | Hasil & Metrik | Status Verifikasi |
|---|---|---|---|
| `mcp__codebase_memory_mcp__index_status` | `project: "...nra_video_uniquifier"` | Initial: 1467 nodes, 3729 edges, ready | `verified` |
| `mcp__codebase_memory_mcp__index_repository` | `mode: "full"` | Final: 1492 nodes, 3771 edges, 0 unusable | `verified` |
| `mcp__codebase_memory_mcp__search_graph` | `name_pattern: ".*NotificationService.*"` | Class node di `lib/core/services/notification_service.dart` | `verified` |

---

## 9. Pengakuan Jujur (Honest Admission) — Menuju Uji Perangkat Riil

1. Seluruh utang teknis pra-rilis dari Audit Report 31 kini telah diselesaikan 100%:
   - Parameter batch terisolasi (D1-01).
   - Sinkronisasi hardware acceleration reaktif (D1-02).
   - Concurrency hazard double-tap terproteksi (D2-01).
   - Konsolidasi menu & penghapusan modal usang (D3-01).
   - Preset chips terekspos (D3-02).
   - Purge cache confirmation dialog aktif (D4-02).
   - Touch targets >= 48x48dp (D4-01).
   - TextScaler 2.0 wrapping responsive (D4-03).
   - Rewind progress animasi tertahan pada 15% (D2-02).
   - Async gap `mounted` guard pada history (D2-03).
   - Diagnostic integrity exception (D5-01).
   - Supresi notifikasi batch (D5-02).
   - FileProvider `<root-path>` dihapus (D6-01).
   - Redaksi path absolut pengguna (D6-02).
   - Thumbnail memory clamp 240x240 (D7-01).
   - Dekomposisi struktural seluruh berkas di bawah 400 LOC (P2-L).
   - Testabilitas notifikasi Android dengan asersi payload riil (P2-M).
2. Apa yang tersisa sebelum Uji Perangkat Riil (Physical/Emulator Smoke Test):
   - Menghubungkan perangkat fisik Android via ADB (`adb devices`) atau emulator Android (misal LDPlayer 9 / Android Studio Emulator).
   - Menjalankan build rilis split-ABI (`flutter build apk --release --split-per-abi`) dan melakukan pengujian instalasi APK riil pada arsitektur target (`app-arm64-v8a-release.apk`).
   - Melakukan uji render video riil 4K / 1080p dengan FFmpeg native binaries untuk memverifikasi encoding H.264/H.265 secara langsung pada hardware encoder perangkat.
