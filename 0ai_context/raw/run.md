# Mapper Run — report 129

- Date: 2026-11-14
- HEAD: `3d4d4ed` (fix(core): resolve filter bottleneck, audio leak, and export hang)
- Mode: RE-RUN (SEED, STATE, HANDOFF already exist)
- Preflight: `index_status` OK — `nra_video_uniquifier`, status ready, 2908 nodes /
  7070 edges, snapshot `2026-11-13T14:31:12Z`, `watch.watched=false`.
- Health: analyze exit 0, test 229/229 passed, format exit 0 (0 changed).
- Code delta since the previous mapper run: reports 123–128 — software H.264 lock
  (`libx264`, CRF 18, `-hwaccel none`), H.265/HW-accel UI locks, Intel/News tab
  removal (4-slot nav), LUT (`lut3d`) foundation, chunked FFmpeg audit logging,
  2-hour audio noise leak fix (`d=7200` → `d=60`), filter-thread unblocking, and
  the 30 s gallery-export timeout.
- Findings: 037 resolved (report 123), 024 invalid (report 120); active set is now
  020, 027, 028, 036.
- Reports indexed: 123–129 (123–125 were missing from `index.json` and were added
  in this run).
- Next report number: 130.
