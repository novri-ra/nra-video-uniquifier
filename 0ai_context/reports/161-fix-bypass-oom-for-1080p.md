# Report 161 — fix: Bypass OOM Guard for 1080p Resolution

## Metadata
- **Date**: 2026-11-15
- **Type**: fix
- **Task**: fix-bypass-oom-for-1080p-161
- **Status**: done
- **Tests**: 229/229 passed
- **Analyze**: 0 issues (clean exit 0)

---

## Summary

Relaxed the OOM Guard evaluation in `FfmpegService._isHighOomRisk` to completely bypass complexity score limits when targeting 1080p (`TargetResolution.r1080p`):

1. **Context & Problem**:
   - Users on Entry Tier hardware (<4GB RAM) were blocked when configuring rich visual effects on 1080p exports because the complexity score reached 50 (exceeding the 40-point entry limit).
   - In reality, 1080p video frames require only ~3MB per frame of RAM, making it memory-safe even on 3GB/4GB devices. Processing 1080p with heavy filters is CPU-bound rather than memory-constrained.
   - Heavy OOM crashes primarily risk 4K (and 2K) frame buffers (~24MB per frame).

2. **Implementation**:
   - Updated `FfmpegService._isHighOomRisk` to accept `required TargetResolution targetResolution`.
   - Added an immediate bypass check at the top of `_isHighOomRisk`:
     ```dart
     if (targetResolution == TargetResolution.r1080p) {
       return null;
     }
     ```
   - Retained strict complexity score evaluation for 2K and 4K resolutions to prevent device crashes on high-resolution rendering.
   - Updated the invocation of `_isHighOomRisk` in `FfmpegService.processVideo` to pass `targetResolution`.

---

## Files Modified

| File | Change |
|------|--------|
| `lib/core/services/ffmpeg_service.dart` | Added `targetResolution` parameter and early bypass return `null` for `TargetResolution.r1080p` in `_isHighOomRisk`. |

---

## Verification

```bash
dart analyze --fatal-infos
# -> Analyzing nra_video_uniquifier... No issues found!

flutter test
# -> 229/229 passed.

grep -n "TargetResolution.r1080p" lib/core/services/ffmpeg_service.dart
# -> line 831: if (targetResolution == TargetResolution.r1080p) {
```
