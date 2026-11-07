# Fix Report 93 — Silent Catches in UserInterestService

**Date:** 2026-11-08
**Type:** Manual Fix (AUDIT-20261108-006, P1)
**Status:** Complete (1 sibling handler deliberately excluded, see §2.3)

## 1. Background

HANDOFF §10 finding `AUDIT-20261108-006` reported 3 empty `catch (_) {}` blocks in
`lib/core/services/user_interest_service.dart`. The important one is `_loadAffinity` (line 262): a
corrupt or unmigratable `nra_user_affinity_v2` / `nra_keyword_affinity_v1` entry silently resets the
whole affinity map to empty, so a user's learned topic weights vanish with no trace. The other two
swallow SharedPreferences write failures for the affinity map and the webhook URL.

## 2. What Was Done

### 2.1 The empty `catch (_) {}` blocks (3 of 3 fixed)

| Line (pre-fix) | Enclosing method | New log message |
|----------------|------------------|-----------------|
| 68 | `setWebhookUrl` (prefs write) | `[UserInterestService] webhook url save failed: $e` |
| 262 | `_loadAffinity` (v2 decode + v1 migration, single shared catch) | `[UserInterestService] affinity load failed: ${e.runtimeType}` — see §2.2 |
| 273 | `_saveAffinity` (prefs write) | `[UserInterestService] affinity save failed: $e` |

`_loadAffinity` has **one** catch covering both the v2 decode and the v1→v2 migration branch, so it
gets one message. It is labelled `affinity load failed` rather than `affinity migration decode`
because the same handler also catches the v2 read; the migration is simply the branch that runs when
v2 is absent.

### 2.2 Privacy: `_loadAffinity` logs the exception type, not `$e`

`$e` is not safe on this specific handler. `jsonDecode` throws `FormatException`, and
`FormatException.toString()` echoes the offending source. The source here is the affinity JSON,
whose keys are the user's search queries. Verified with a throwaway probe:

```
FormatException
---
FormatException: Unexpected character (at character 21)
{"my secret query":{oops}}
                    ^
```

So `... failed: $e` would have printed the beginning of the stored JSON — i.e. user search terms —
straight into logcat, violating the task's "no `query` / `keyword` / user-entered string" rule. The
handler therefore logs `${e.runtimeType}` (still distinguishes `FormatException` from
`MissingPluginException` and friends) plus a one-line comment explaining why. The other two handlers
keep `$e`, because prefs/plugin exceptions do not carry the stored value or any user string.

### 2.3 Sibling silent handlers on the same path

| Line | Site | Decision |
|------|------|----------|
| 79 | `getWebhookUrl` — `catch (_) { _configuredWebhookUrl = defaultWebhookUrl; }` | **Not changed.** The task explicitly forbids touching the `getWebhookUrl` implementation. It is the only remaining silent handler in the file. |
| 277 | `_dispatchTelemetry` / `mockDispatcher` | No handler exists and none was added (ponytail: no new `try`/`catch`). A throwing mock propagates to the caller in tests, which is the desired signal. |
| 285 | `flushQueue` | Empty no-op method, not an error handler. Untouched. |

Consequence: the `grep -nE 'catch \(_\) \{\}|catchError\(\(_\) \{\}\)|catch \(_\) \{ return'` gate
returns **0 matches** (the line 79 body is an assignment, not `{}` / `return`). The `getWebhookUrl`
catch is the only silent handler left, by instruction.

### 2.4 Privacy scan of pre-existing logs

`debugPrint` / `print` / `log` / `developer.log` count in this file before the fix: **0**. There was
nothing to narrow. No new log message interpolates `query`, `keyword`, `title`, `category`,
`langMode`, `article.id`, `payload`, or any affinity `score` — the `_dispatchTelemetry` payloads
(which do contain all of those) are never logged.

### 2.5 Not changed

- No `rethrow`. On decode failure the map still ends up empty and `initialize()` still completes;
  the deterministic fallback is intact.
- No new API surface: no `isDegraded`, no `lastErrors` (scan: 0 matches).
- `_affinityKeyV1`, `_affinityKeyV2`, `_webhookKey`, `mockDispatcher`, `defaultWebhookUrl`,
  `getWebhookUrl`, the decay formula, and every `record*` method are untouched.

## 3. Verification

| Check | Command | Result |
|-------|---------|--------|
| Static analysis | `dart analyze --fatal-infos` | exit 0, `No issues found!` |
| Target test | `flutter test test/microstock_news_and_translation_test.dart` | exit 0, `All tests passed!` (18 tests, incl. 4 `UserInterestService` tests) |
| Full suite | `flutter test` | exit 0, 216/216 passed |
| Silent-handler grep | `catch (_) {}` / `catchError((_) {})` / `catch (_) { return` | 0 matches |
| New API surface | `isDegraded` / `lastErrors` scan | 0 matches |
| Diff scope | `git diff --stat` | 1 file, 10 insertions, 3 deletions |
| Deletions audit | `git diff` removed lines | 3, all the literal `} catch (_) {}` lines |

The target suite exercises `recordSearch`, `recordChipClick`, `getAdaptiveKeywords`, the offline
telemetry queue, and the default webhook binding; all passed unchanged, so affinity ranking and
telemetry behaviour are identical.

## 4. Note for the Next Mapper Run

The mapper should detect this report and drop `AUDIT-20261108-006` from the findings inventory, with
the caveat that `getWebhookUrl` (line 79) still has a silent fallback by explicit instruction.
31 of the original 85 empty catches remain in `lib/` (verified by pattern scan after this fix).
Next: `-017` (3, `settings_service.dart`), `-018` (3, `storage_service.dart`),
`translation_service.dart` (3), `article_image_service.dart` (3), then `-016` (`locale_provider.dart`).

Worth registering as a separate P3: reports 91 and 93 both show that `$e` on a `jsonDecode` failure
echoes the JSON prefix. `microstock_news_service.dart` logs `cache read failed: $e` over cached
article JSON, so that log line has the same latent leak (article titles/summaries, not queries).
A small follow-up could standardise "log the type, not the payload" for decode handlers.
