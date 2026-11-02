# 19-vdna-evasion-and-web-research: Autonomous Web Research & Full Pipeline Overhaul to Bypass TikTok vDNA / Duplicate Content Restrictions

## Executive Summary
This session conducted reverse-engineering research on ByteDance's video DNA (vDNA) fingerprinting and perceptual hashing (pHash) content moderation algorithms. Based on findings, we overhauled the FFmpeg processing pipeline with 5 core anti-detection pillars: horizontal mirroring (`hflip`), intro/outro auto-trimming (`-ss 0.5` + duration clamp), dynamic non-linear color grading (`curves=preset=vintage`), synthetic ambient pink noise spectrogram injection (`anoisesrc` + `amix`), and native hardware container spoofing (Apple iPhone 15 Pro tags with `-map_metadata -1 -map_chapters -1 -bitexact`).

---

## 1. Web Research Synthesis & Forensic Analysis
Reverse-engineering research across video deduplication literature, patent disclosures (US20130006951A1), and creator engineering workflows revealed TikTok/ByteDance's multi-tier detection architecture:

### 1.1 Temporal Keyframe Sampling
- **Mechanism**: Rather than checking every individual frame, vDNA generates perceptual hashes (Hamming Distance comparisons) across keyframe anchor samples spaced 0.5s–1.0s apart.
- **Vulnerability**: Initial intro frames (0–0.5s) and trailing outro frames (last 0.5s) are primary trigger anchors where candidate matches are queried against the VDDB (Video DNA Database).
- **Countermeasure**: Cutting the first 0.5s (`-ss 0.5`) and last 0.5s (`-t (duration - 1.0)`) completely offsets the anchor sequence timeline, neutralizing timeline alignment queries.

### 1.2 Spatial Landmark & Feature Vectors
- **Mechanism**: Divides frames into spatial matrices (e.g. 8x8 or 16x16 blocks) and computes edge histograms, facial landmark positions, and spatial centroid vectors. Standard gentle crops (2%) or subtle gamma adjustments fail to shift landmark vector alignments.
- **Vulnerability**: Directional and facial landmark algorithms are coordinate-dependent (left vs right eye, nose slant, camera panning vectors).
- **Countermeasure**: Horizontal mirroring (`hflip`) inverts all horizontal spatial feature vectors, completely defeating directional landmark matching. Combined with a 5% margin crop (`crop=trunc(iw*0.95/2)*2:trunc(ih*0.95/2)*2`) and a 0.4° spatial rotation tilt (`rotate=0.4*PI/180:ow=rotw(...):oh=roth(...):fillcolor=black`), spatial vectors are disrupted.

### 1.3 Audio Fingerprint (Spectrogram Constellation Matching)
- **Mechanism**: Platforms employ Chromaprint/AcrCloud acoustic fingerprinting, identifying constellation maps of peak audio energies across frequency bins over time.
- **Vulnerability**: Linear pitch or volume scaling preserves the relative constellation geometry of peak spectral bins.
- **Countermeasure**:
  1. Pitch & rate shift (`atempo=1.015,asetrate=48000*1.01,aresample=48000`).
  2. Bandpass sculpting (`highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1`).
  3. Synthetic Pink Noise Masking (`anoisesrc=d=7200:c=pink:a=0.003` mixed via `amix=inputs=2:duration=first`). Injects an ultra-low imperceptible pink noise floor across all frequency bins, rewriting the background spectrogram energy distribution without degrading speech or music intelligibility for human listeners.

### 1.4 Container & Exif Signature
- **Mechanism**: Re-encoding tools leave encoder signatures (e.g., `Lavf` / `Lavc` muxer tags). Automated ingest scanners flag suspicious re-encodings as unoriginal media.
- **Countermeasure**: Strip all container tags with `-map_metadata -1 -map_chapters -1 -bitexact` and write modern synthetic device metadata (`-metadata make="Apple" -metadata model="iPhone 15 Pro" -metadata encoder="Apple QuickTime"`).

---

## 2. Pipeline Overhaul & Filter Implementation

### 2.1 Video Filter Pipeline (`FfmpegService._buildVideoFilter`)
Enforces strict sequential order:
```
1. Temporal Stage:        setpts=0.9852*PTS
2. Spatial Stage:         crop (5% deep or 2% micro) -> rotate (0.4°) -> hflip (horizontal mirror)
3. Resolution Scaling:    scale=w=-2:h=TARGET_HEIGHT:flags=lanczos
4. Enhancement Stage:     hqdn3d=1.5:1.5:4:4 -> unsharp=3:3:0.6:3:3:0.0 -> curves=preset=vintage -> eq=...
5. Grain Mask:            noise=alls=3:allf=t+u
```
Video Encoder: `-c:v libx264 -preset veryfast -crf 19 -b:v 8M -g 60 -keyint_min 30`.

### 2.2 Audio Filter Pipeline (`FfmpegService._buildAudioFilter`)
- Standard Evasion: `atempo=1.015,asetrate=48000*1.01,aresample=48000,highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1`
- Aggressive Pink Noise Masking:
  ```
  -af "[in]atempo=1.015,asetrate=48000*1.01,aresample=48000,highpass=f=60,lowpass=f=16000,equalizer=f=1200:t=q:w=1:g=1[a0];anoisesrc=d=7200:c=pink:a=0.003[noise];[a0][noise]amix=inputs=2:duration=first[out]" -c:a aac -b:a 192k
  ```

### 2.3 Command Assembly (`FfmpegService.buildCommand`)
- Auto-Trim: injects `-ss 0.5` (and `-t ${totalDuration - 1.0}` when total duration > 1.5s) before input.
- Metadata: injects container clearing and Apple iPhone 15 Pro hardware spoofing.

---

## 3. UI & State Exposure
- **`SettingsService`**:
  - Keys added: `app_horizontal_flip`, `app_aggressive_audio`, `app_auto_trim`.
  - Added async getters and persistent setters with `SharedPreferences`.
- **`UniquifierProvider`**:
  - State added: `enableHorizontalFlip`, `enableAggressiveAudio`, `enableAutoTrim`.
  - Actions: `toggleHorizontalFlip`, `toggleAggressiveAudio`, `toggleAutoTrim`.
  - Added into `_initResolution()` (with guarded async bootstrap) and `applyPreset()`.
- **`ModifiersCard`**:
  - Header updated to `9 MODIFIERS`.
  - 3 new toggle rows:
    - `Horizontal Flip` (`Mirrors video landmarks`, icon: `Icons.flip`)
    - `Audio Masking` (`Ambient pink noise layer`, icon: `Icons.waves`)
    - `Auto-Trim` (`Cuts 0.5s intro & outro`, icon: `Icons.content_cut`)

---

## 4. Verification & Testing
- **Static Analysis (`flutter analyze`)**:
  - `No issues found! (ran in 3.7s)` — 0 warnings, 0 errors.
- **Automated Test Suite (`flutter test`)**:
  - 7 suites executed, **58 passing tests** (0 failures).
  - New test coverage:
    - `test/ffmpeg_service_test.dart`: Spatial order (rotate < hflip < scale), pink noise `anoisesrc` + `amix` construction, auto-trim seek and duration calculation, hardware metadata spoofing verification.
    - `test/uniquifier_provider_test.dart`: Default state, toggle actions, and listener notification counts.
    - `test/settings_service_test.dart`: Persistence of new keys in SharedPreferences.
    - `test/widget_test.dart`: ModifiersCard rendering verification for all 9 modifiers.

---

## 5. Line Budget Audit (Strict <= 400 LOC)
All files comply strictly with the line budget:
- `lib/core/providers/uniquifier_provider.dart`: 377 LOC (Budget: <= 400)
- `lib/core/services/ffmpeg_service.dart`: 349 LOC (Budget: <= 400)
- `lib/features/process/screens/processing_screen.dart`: 317 LOC (Budget: <= 400)
- `lib/features/process/widgets/modifiers_card.dart`: 248 LOC (Budget: <= 250)
- `lib/core/services/settings_service.dart`: 162 LOC (Budget: <= 250)

---

## 6. MCP Graph Delta & Commit
- **Baseline Graph**: 1058 nodes, 2568 edges
- **Updated Graph**: 1067 nodes, 2610 edges (Delta: +9 nodes, +42 edges)
- **Commit**: `feat(pipeline): advanced vDNA evasion, audio spectrogram masking, and auto-trim`
