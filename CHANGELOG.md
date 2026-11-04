# Changelog
## [Unreleased]
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
