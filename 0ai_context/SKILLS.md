# SKILLS.md — OpenCode & Hermes Skills Matrix

Dokumentasi referensi lengkap seluruh skill yang terinstall di environment OpenCode / Hermes untuk proyek `nra_video_uniquifier`.

---

## 1. Standard Mandatory Skills
Empat core engineering skills terpasang dan diverifikasi:
- `/senior-architect`: Desain arsitektur sistem, dekomposisi modul, manajemen boundary, dan evaluasi trade-off skalabilitas.
- `/clean-code`: Standar koding pragmatis, batasan ketat (<= 40 baris/fungsi, <= 400 baris/file), prinsip YAGNI, minim abstraksi.
- `/systematic-debugging`: Investigasi bug 4 fase berbasis bukti, isolasi akar masalah sebelum patch, no speculative fixes.
- `/senior-qa`: Strategi testing menyeluruh, test automation, responsive widget testing, verifikasi multi-resolusi, edge-case matrix.

---

## 2. Mobile & Flutter Stack Matrix
Skill spesifik untuk platform mobile dan stack aplikasi ini:
- `/flutter-expert`: Arsitektur Flutter mendalam, Dart 3, state management, InheritedWidget/Provider, canvas shaders, render tree optimization.
- `/mobile-design`: Prinsip desain antarmuka mobile-first untuk iOS dan Android, interaksi sentuh, platform conventions.
- `/mobile-native`: Adaptasi web/hybrid agar terasa native di mobile (100vh bug, notch/safe-area, tap latency, gesture conflicts).
- `/write-swift`: Panduan modern Swift 6, data-race safety, concurrency (`actors`, `task groups`), value types, dan Swift Testing.

---

## 3. Architecture, Fullstack & DevOps Matrix
Skill perancangan sistem dan infrastruktur:
- `/senior-fullstack`: Pengembangan fullstack komprehensif (React, Next.js, Node.js, GraphQL, PostgreSQL), scaffolding, pola arsitektur.
- `/senior-devops`: Automasi CI/CD, deployment pipelines, containerization, Infrastructure as Code (IaC), monitoring cloud (AWS, GCP, Azure).
- `/docker-expert`: Optimasi Docker multi-stage builds, container hardening, security scan, Docker Compose orchestration.
- `/supabase-postgres-best-practices`: Optimasi performa PostgreSQL, query tuning, indexing, schema design, konfigurasi database.

---

## 4. Security & Vulnerability Matrix
Skill audit keamanan dan hardening:
- `/security-audit`: Review keamanan menyeluruh untuk codebase, API, service, dan CLI tools, vulnerability research, threat modeling.
- `/senior-security`: Engineering keamanan tingkat lanjut, penetration testing, arsitektur kriptografi, audit kepatuhan.
- `/vulnerability-scanner`: Analisis kerentanan berbasis OWASP 2025, supply chain security, mapping attack surface, mitigasi dependensi.

---

## 5. QA, Debugging & Code Review Matrix
Skill penjaminan kualitas kode dan eksekusi:
- `/code-reviewer`: Code review multi-bahasa (TypeScript, JavaScript, Python, Swift, Kotlin, Go), best practices, automated linting checklist.
- `/karpathy-guidelines`: Pedoman perilaku coding: perubahan surgical, no over-engineering, validasi asumsi, success criteria terukur.
- `/break-ui`: Stress-testing antarmuka menggunakan input edge-case ekstrem (teks panjang, formatting aneh, angka batas, karakter khusus).

---

## 6. Ponytail Suite (Lazy Senior Dev Mode)
Rangkaian skill minimal diff, standard-library/native-first, anti-bloat:
- `/ponytail`: Mode senior dev malas: solusi tuntas dengan diff terkecil, native API rungs, zero unnecessary abstractions.
- `/ponytail-audit`: Audit repo menyeluruh untuk bug, celah keamanan, bottleneck performa, bloat, dan target pembersihan kode.
- `/ponytail-debt`: Ledger pencatatan seluruh shortcut teknis (`shortcut:` dan `ponytail:` comments) dalam codebase.
- `/ponytail-gain`: Laporan efisiensi terukur dari reduksi kode, token cost, dan kecepatan eksekusi.
- `/ponytail-help`: Panduan cepat tingkatan mode ponytail (lite, full, ultra) dan perintah terkait.
- `/ponytail-review`: Review kualitas diff mencakup logika, ketahanan beban nyata, kecukupan tes, dan kebutuhan tiap baris kode.

---

## 7. UI/UX Design Systems & Craft Matrix
Skill perancangan antarmuka, layout, dan token desain:
- `/impeccable`: Perancangan, redesign, polish antarmuka frontend (web, mobile, dashboard) dengan standar visual tinggi.
- `/ui-craft`: Prinsip anti-slop UI: discovery phase wajib, hierarki layout, tipografi, warna, dashboard, polish details.
- `/ui-craft-dense-dashboard`: Template dashboard padat/data-heavy (Bloomberg/Retool style, IBM Plex, tabular numbers, sparklines).
- `/ui-craft-editorial`: Desain editorial/majalah/long-form content (serif typography, kolom baca lebar, drop caps).
- `/ui-craft-minimal`: Desain minimalis/clean (gaya Linear/Notion/Vercel, monochrome + single accent, subtle hairline borders).
- `/ui-ux-pro-max`: Intelijen desain UI/UX mencakup 50 style, 21 palet, 50 font pairing, multi-framework support (Tailwind, shadcn).
- `/taste-skill`: Art direction anti-slop berdasarkan riset 247 web gallery terbaik, section blueprints, visual inspection loop.
- `/superdesign`: Canvas design tools untuk UI, wireframe, slide deck, visual assets berbasis multi-model AI.
- `/frontend-design`: Desain visual terarah yang menghindari template default AI, pilihan tipografi dan layout distingtif.
- `/design-doctrine`: House rules desain UI: zero emoji, verifikasi strict, token by intent, konsistensi 8 state komponen.
- `/design-screen`: Pipeline lengkap mendesain halaman dari nol (brief inference, visual direction, tokenisasi, implementasi).
- `/design-component`: Spesifikasi anatomi komponen UI, varian, sizing, 8 status interaksi, aksesibilitas.
- `/design-tokens`: Pembuatan dan audit token desain format W3C DTCG (arsitektur 3-tier: primitive -> semantic -> component).
- `/token-build`: Automasi transform token DTCG ke platform target (CSS vars, Tailwind @theme, TS, Android, iOS).
- `/tokens`: Audit dan penetapan 3-layer token spine dalam proyek.
- `/figma-integration`: Sinkronisasi dua arah antara token/komponen Figma Variables dan codebase.
- `/apply-aesthetic`: Penerapan arah visual spesifik (archetypes atau 2,000+ brand design systems) ke layer token.
- `/sddesign`: Spec-driven design pipeline penuh dari brief, shape spec, build, converge, hingga ship.
- `/shape`: Desain wireframe ASCII, inventaris konten, dan pemetaan state sebelum menulis kode.
- `/craft`: Pipeline one-shot pembuatan antarmuka lengkap dari resep hasil akhir yang siap rilis.
- `/redesign`: Modernisasi antarmuka eksisting dengan mempertahankan apa yang sudah bekerja (IA, brand, SEO).

---

## 8. Micro-Tuning & Polish Matrix
Skill iterasi terfokus pada detail UI spesifik:
- `/polish`: Pass finishing akhir: micro-typography, ritme spacing, hover choreography, satu detail tanda tangan.
- `/delight`: Penambahan micro-interaction berkarakter tanpa dekorasi murahan atau confetti.
- `/bolder`: Peningkatan kepribadian UI, variasi layout, kontras tipografi saat desain terasa terlalu datar.
- `/quieter`: Meredam kebisingan visual, simplifikasi layout dan saturasi warna saat antarmuka terlalu ramai.
- `/colorize`: Strategi aksen warna tunggal pada 3-5 titik terencana, menjaga 90% netral.
- `/distill`: Pemangkasan elemen dekoratif, teks berlebih, dan dead code yang tidak mendukung tindakan pengguna.
- `/extract`: Ekstraksi duplikasi markup/class Tailwind ke komponen reusable dan pengangkatan nilai magic ke token.
- `/typeset`: Optimasi tipografi: modular scale, tracking, line height, weight contrast, dan fitur OpenType.
- `/clarify`: Review UX copy untuk tombol, pesan error, label form, dan empty state agar lugas dan manusiawi.
- `/ux-writing`: Penulisan copy antarmuka berbasis framework what-why-how dan panduan inklusif.
- `/unhappy`: Perancangan state non-happy path lengkap (loading, empty, error, partial, offline, conflict).
- `/harden`: Kesiapan produksi: skeleton loading, graceful degradation, permission handling, offline resiliency.
- `/adapt`: Layout responsif: breakpoint audit, target sentuh aman (touch targets), safe area, fluid typography.
- `/brief`: Pembuatan dan pembaruan brief desain tahan lama pada `.ui-craft/brief.md`.
- `/remember`: Pencatatan konstrain desain dan koreksi pengguna ke dalam dokumen brief proyek.
- `/start`: Diagnostik awal proyek untuk mendeteksi framework, token, dan memandu langkah berikutnya.
- `/finalize`: Quality gate pra-merge: verifikasi 10-pass finish bar dan feedback hierarchy (READY / NOT READY).

---

## 9. Motion & Animation Matrix
Skill perancangan, optimasi, dan pembersihan animasi:
- `/animate`: Desain motion bermakna, timing, easing curves sesuai hierarki antarmuka.
- `/animate-expo`: Implementasi gesture dan animasi di React Native / Expo (Reanimated, Gesture Handler, Haptics).
- `/apple-design`: Prinsip motion dan interaksi ala Apple: spring physics, interruptible transitions, translusensi, kedalaman.
- `/animation-performance`: Menjaga animasi pada batas frame budget (60/120 FPS), composite-only properties, off-main-thread.
- `/animation-vocabulary`: Glosarium istilah tepat untuk jenis motion UI (rubber-banding, pop-in, spring dampening).
- `/find-animation-opportunities`: Audit read-only untuk mendeteksi titik antarmuka yang memerlukan motion bermakna.
- `/improve-animations`: Audit komprehensif motion codebase dan pembuatan roadmap perbaikan performa animasi.
- `/remove-animations`: Mengidentifikasi dan membuang animasi tidak perlu pada aksi berfrekuensi tinggi atau data fungsional.

---

## 10. Performance, Web & Accessibility Matrix
Skill optimasi web, audit kepatuhan, dan integrasi UI:
- `/web-performance-optimization`: Optimasi kecepatan web, Core Web Vitals (LCP, INP, CLS), bundle splitting, caching runtime.
- `/performance`: Pencegahan layout shift (CLS), optimasi responsivitas interaksi (INP), dan audit performa runtime UI.
- `/react-best-practices`: 40+ aturan performa React & Next.js: eliminasi waterfall request, optimasi bundle, re-render minim.
- `/a11y-audit`: Audit aksesibilitas sesuai standar WCAG 2.2 AA/AAA, ARIA roles, kontras warna, keyboard navigation.
- `/audit`: Audit teknis gabungan mencakup a11y, performa, dan responsivitas dengan tabel prioritas temuan.
- `/heuristic`: Penilaian usability heuristik berbasis 10 prinsip Nielsen + 6 hukum desain dengan skor UsabilityScore.
- `/design-review`: Evaluasi desain komprehensif pada 6 dimensi terbobot sebelum maupun sesudah implementasi.
- `/design-qa`: Setup automated CI quality gates untuk linting token, kontras rasio, dan visual regression testing.
- `/data-dashboard`: Perancangan layar data padat: candlestick, volume, heatmaps, sparklines, dan order books dengan kontras akurat.
- `/ask-sonner`: Panduan implementasi dan debugging toast notification library Sonner di React.
- `/design-code`: Generator kode komponen aksesibel berbasis token untuk beragam framework (React, Vue, Svelte, Flutter, Compose).

---

## 11. Codebase Memory, Tooling & Platform Skills
Skill pengelolaan knowledge graph kode, version control, dan harness:
- `/codebase-memory`: Query graf pengetahuan kode struktural (callers, callees, symbol traces, dependency mapping).
- `/git-commit-helper`: Analisis git diff untuk membuat commit message deskriptif dan presisi.
- `/antigravity`: Referensi lengkap platform Antigravity, konfigurasi agent, subagents, SDK, MCP, keybinds, tools, troubleshooting.
- `/report`: Pengumpulan diagnostik otomatis dan pembuatan issue pelaporan bug via GitHub CLI.

---

## 12. MCP Usage Matrix
Routing tugas untuk `codebase-memory-mcp`:
| Task | MCP Tool | Arguments / Filter | Expected Output |
|---|---|---|---|
| Architecture Mapping | `get_architecture` | `aspects: ["all"]` | System entry points, component tiers |
| Symbol Discovery | `search_graph` | `name_pattern`, `label` | Qualified names, file locations, in/out degrees |
| Dead Code Detection | `search_graph` | `file_pattern: "lib/.*"`, `max_degree: 0` | Symbols with 0 references |
| Dependency / Call Path | `trace_path` | `function_name`, `direction: "both"` | Inbound callers and outbound callees |
| File Outline | `get_file_outline` | `file_path`, `format: "tree"` | Declarations, line spans, methods/classes |
| Impact Analysis | `detect_changes` | Git diff / staging | Affected symbols, cascade risk |
| Graph Inventory | `get_graph_schema` | `diagnostics: "none"` | Counts of node labels and edge types |
| Multi-hop Relationships | `query_graph` | openCypher `MATCH ...` | Custom graph traversals |
| Index Status & Readiness | `index_status` | `diagnostics: "summary"` | Graph readiness, node/edge counts, watch state |
| Snapshot Comparison | `compare_graphs` | `base_project`, `target_project` | Added/removed nodes and edge diffs |
