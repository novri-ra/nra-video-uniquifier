# Reports Index

| # | File | Date | Kind | Summary |
|---|------|------|------|---------|
| 01 | 01-audit.md | 2026-11-04 | audit | Baseline audit report with 173 tests passing and 6 findings |
| 02 | 02-fix-p1-silent-error-catches.md | 2026-11-04 | fix | Fix P1 silent error catches in FfmpegService and UniquifierProvider |
| 03 | 03-audit-tiktok-evasion-and-fix-p3.md | 2026-11-04 | audit | P3 Locale Provider fix and TikTok video/audio/metadata evasion pipeline audit |
| 04 | 04-implement-visual-evasion.md | 2026-11-04 | fix | Implement visual evasion upgrades (canvas crop, sinusoidal zoompan, RGB curves) |
| 05 | 05-implement-audio-metadata-evasion.md | 2026-11-04 | fix | Implement audio mutation (±4% pitch, chorus phase) and randomized MP4 metadata profiles |
| 06 | 06-fix-history-delete-multiselect.md | 2026-11-04 | fix | Implement physical disk file deletion and multi-select batch deletion in export history |
| 07 | 07-audit-ui-ux-standards.md | 2026-11-04 | audit | Deep UI/UX audit against WCAG 2.2, HIG, Material 3, contrast ratios, and touch targets |
| 08 | 08-fix-phase1-ui-contrast.md | 2026-11-04 | fix | Fix CRIT-01 and CRIT-02 color contrast issues on disabled action button and pastel badges |
| 09 | 09-fix-phase2-touch-targets-semantics.md | 2026-11-04 | fix | Enforce >= 48x48dp touch targets and integrate Semantics, tooltips, and live progress announcements |
| 10 | 10-refactor-p2-ffmpeg-service.md | 2026-11-04 | refactor | Refactor FfmpegService god-class into modular SRP helpers under lib/core/services/ffmpeg/ |
| 11 | 11-fix-microstock-news-parser-and-overflow.md | 2026-11-04 | fix | Sanitize Microstock RSS HTML entities and tags, and fix RenderFlex overflow in card and reader |
| 12 | 12-audit-microstock-news-architecture.md | 2026-11-04 | audit | Comprehensive architecture audit of Microstock Intel models, RSS parser, cache, and WebP pipeline |
| 13 | 13-implement-phase1-model-feed-cache.md | 2026-11-04 | feature | Implement Phase 1 Microstock Intel: extended model, package:html DOM parser, direct RSS feeds, and 1h TTL append-merge cache |
| 14 | 14-implement-phase2-image-webp-isolate.md | 2026-11-04 | feature | Implement Phase 2 Microstock Intel: ArticleImageService, pure Dart WebP downscale in Isolate.run, offline cache, card thumbnails and reader hero banners |
| 15 | 15-implement-phase3-dynamic-chips-affinity-clean-reader.md | 2026-11-04 | feature | Implement Phase 3 Microstock Intel: 7-day decayed affinity scoring engine, dynamic categories aggregator, offline telemetry, and clean reader UI |
| 16 | 16-implement-editorial-ux-bookmarks-pruning.md | 2026-11-04 | feature | Implement Editorial UX: dynamic read time, offline bookmarks, reader progress bar, font size controls, and 50MB WebP cache pruning |

## Numbering Rules
- NN = 2-digit, monotonic, never reused
- Filename: NN-<kebab-slug>.md
- No dates in filenames
