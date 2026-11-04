# Changelog
## [Unreleased]
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
