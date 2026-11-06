# Changelog
## [Unreleased]

## [1.0.4] - 2026-11-06
- feat(compatibility): implement universal Android support from legacy Android 7.0 (API 24) to Android 16 (API 36)
- fix(notifications): ensure rock-solid notification delivery on Android 13-16 via POST_NOTIFICATIONS runtime flow, dataSync foreground service type, and R8 keep rules
- feat(preview): full-fidelity debounced preview rendering with FFmpeg 1-frame extraction and active session cancellation
- feat(effects): unified visual effect catalog (Blurred Canvas, Echo Delay, RGB Split, Dreamy Bloom, 16mm Film, Dynamic Grain)
- feat(ui): VisualEffectSelectorCard with responsive horizontal carousel and contextual dynamic sub-controls
- test: expand test suite to 206+ passing tests with zero static analysis issues

## [1.0.3] - 2026-11-05
- feat(ui): implement InteractivePreviewSlider with 60 FPS real-time floating preview overlay
- feat(controls): wire manual sliders for crop zoom, micro-rotation, sharpening, saturation, and canvas scale
- fix(success): resolve missing thumbnail display on SuccessScreen with robust fallback
- test: expand test suite to 185 passing tests covering slider overlay lifecycles

## [1.0.2] - 2026-11-05
- feat(storage): implement WidgetsBindingObserver for real-time permission sync on resume
- feat(storage): integrate device_info_plus for dynamic Android SDK version detection
- fix(manifest): register granular media permissions (READ_MEDIA_VIDEO, READ_MEDIA_IMAGES, READ_MEDIA_AUDIO)

## [1.0.1] - 2026-11-05
- fix(engine): resolve audio amix drop (-6 dB) and calibrate sub-perceptual pitch shift (±1.5%)
- fix(engine): wire dynamic sharpening slider and connect real physical disk storage check
- feat(evasion): implement dynamic GOP jittering, micro color matrix shifting, and SEI NAL stripping
- feat(storage): implement 4-tier native intent dispatcher for Android 11+ MANAGE_EXTERNAL_STORAGE
- feat(a11y): upgrade dark mode contrast to WCAG AAA (12.18:1) via mintSage tokens
- feat(i18n): normalize entire UI copy and notification strings to English default
- feat(data): integrate real background SHA-256 hashing, dynamic render estimation, and dynamic manifest badges

## [1.0.0] - 2026-11-05
- feat(microstock): reactive on-demand full article extraction with dynamic progress indicator
- fix(microstock): strip aside, banners, and freestar advertising clutter before DOM parsing
- fix(history): persist storage permission prompt via SharedPreferences to limit dialog to 1 occurrence
- fix(history): remove redundant permission checks during single and bulk delete actions
- fix(history): implement resilient per-file iteration for bulk video deletion with MediaScanner synchronization
- docs(reports): add report 27 (comprehensive news reader and storage management fix) to reports index
- feat(microstock): add DOM pre-cleaning to strip advertisements, social widgets, and noise from article reader
- feat(microstock): support multi-element narrative extraction (headings h2-h4, bullet lists ul/ol/li, blockquotes)
- feat(microstock): implement rich semantic block rendering in MicrostockArticleSheet
- docs(reports): add report 26 (full article content dom extraction) to reports index
- feat(microstock): reverse-engineer Google News RPC batchexecute (Fbv4je) to decode original publisher URLs
- feat(microstock): add Indonesian microstock & commercial photography RSS feed with when:14d freshness
- feat(microstock): expand DOM container selectors for WordPress (.entry-content, .post-content)
- feat(microstock): unify 'All' tab feed with strict newest-first chronological sorting
- docs(reports): add report 25 (news reader upgrade) to reports index
- fix(history): add runtime storage permission prompt for Android Scoped Storage compliance
- fix(history): enforce strict post-delete disk verification in HistoryService
- fix(history): eliminate cosmetic UI removal when physical deletion fails
- fix(history): trigger MediaStore index rescan upon file deletion
- docs(reports): add report 22 (audit) and report 23 (implementation fix) to reports index
- fix(microstock): build on-demand ArticleReaderExtractor for thin RSS article content and og:image fallback
- fix(microstock): guard ArticleFooterSourceBox to distinguish external RSS sources from verified guidelines
- fix(microstock): strip legacy [Read More] artifacts from reader view
- docs(reports): add report 20 (audit) and report 21 (implementation fix) to reports index
- refactor(provider): decompose UniquifierProvider god-object into domain mixins under providers/uniquifier/
- refactor(provider): isolate media probing, modifiers/sliders, presets, and rendering progress into dedicated mixins
- docs(reports): add report 19-implement-p2-phase2-uniquifier-provider-mixins to reports index
- refactor(process): decompose SuccessScreen into modular presentation widgets in widgets/success/
- refactor(process): extract SuccessHeroCard, SuccessManifestCard, and SuccessActionButtons
- docs(reports): add report 18-implement-p2-phase1-success-screen-refactor to reports index
- feat(microstock): add dynamic word-count read time estimation badge
- feat(microstock): implement offline-first reactive bookmark service and Saved category filter
- feat(microstock): introduce reader font scaling (A-/A+) and reading scroll progress indicator
- feat(microstock): add 50MB storage quota auto-pruning for local WebP image cache
- docs(reports): add report 16-implement-editorial-ux-bookmarks-pruning to reports index
- feat(microstock): implement 7-day exponential decayed user affinity engine in SharedPreferences
- feat(microstock): build dynamic category aggregator driven by active article tags and affinity rankings
- feat(microstock): present clean multi-paragraph reader typography and suppress synthetic boilerplate boxes
- fix(privacy): eliminate external Google Apps Script telemetry webhooks in compliance with Section 14
- docs(reports): add report 15-implement-phase3-dynamic-chips-affinity-clean-reader to reports index
- feat(microstock): build ArticleImageService with background Isolate WebP compression and local disk caching
- feat(microstock): add responsive 16:9 WebP thumbnails to MicrostockNewsCard and hero banners to MicrostockArticleSheet
- feat(microstock): implement non-blocking background image download and localImagePath cache preservation
- docs(reports): add report 14-implement-phase2-image-webp-isolate to reports index
- feat(microstock): integrate html and image packages, expand article model with media/author attributes
- feat(microstock): add direct photography RSS feeds (PetaPixel, Fstoppers) with DOM-based XML parsing
- feat(microstock): implement append-merge article caching with 1-hour TTL background refresh
- fix(microstock): eliminate truncated HTML tags and residual link leaks using real DOM fragment parser
- docs(reports): add report 13-implement-phase1-model-feed-cache to reports index
- fix(microstock): sanitize raw HTML entities and Google News RSS tags from article feed and reader sheet
- fix(ui): resolve RenderFlex overflow errors on MicrostockNewsCard, MicrostockArticleSheet, and action toolbars
- docs(reports): add report 11-fix-microstock-news-parser-and-overflow to reports index
- fix(a11y): expand interactive touch targets to 48x48dp for bento add queue, clear file, and accordion header (MAJ-01)
- feat(a11y): add Semantics liveRegion, tooltips, and dynamic state labels for processing radar and accordion cards (MAJ-02)
- docs(reports): add report 09-fix-phase2-touch-targets-semantics to reports index
- fix(ui): resolve critical light mode contrast failures on disabled process action button (CRIT-01)
- fix(ui): add theme-adaptive accent tokens for preset badges and offline indicator to satisfy WCAG 2.2 AA (CRIT-02)
- docs(reports): add report 07-audit-ui-ux-standards and report 08-fix-phase1-ui-contrast to reports index
- feat(history): add physical file deletion on disk and automatic thumbnail cache cleanup
- feat(history): implement multi-select mode with batch deletion, select all, and confirmation dialog
- test(history): add unit tests for batch file deletion (174/174 passed)
- docs(reports): add report 06-fix-history-delete-multiselect to reports index
- fix(evasion): resolve TikTok unoriginal content detection by adding foreground canvas spatial crop, continuous sinusoidal zoompan, and dynamic RGB curves (Report 04)
- feat(evasion): harden acoustic and container fingerprints via ±4.0% pitch shift, stereo phase dispersion, randomized device metadata profiles, and stitchable=1 encoder flags (Report 05)
- fix(core): resolve P3 swallowed exception in LocaleProvider (AUDIT-20261104-006)
- docs(reports): add reports 03, 04, and 05 to documentation index
- fix(core): resolve P1 empty catch blocks in FfmpegService and UniquifierProvider with local diagnostic logging and lifecycle guards (AUDIT-20261104-001, AUDIT-20261104-002)
- docs(reports): add report 02-fix-p1-silent-error-catches and update report index
- Regenerated context packet (HANDOFF.md, audit report, state).
### Added
- Setup sistem kontinuitas chat (CHAT-CONTINUITY.md) dan aturan Git.
- Menambahkan `0ai_context/ANALYST-PROMPT.txt` untuk standarisasi prompt awal AI Chat.
- Menerapkan fitur deduplikasi audit di Mapper.

### Fixed
- Memperbaiki 23 peringatan linter curly_braces pada core services dan providers.
