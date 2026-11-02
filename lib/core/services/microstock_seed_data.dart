import 'microstock_news_service.dart';

/// Baseline seed articles for microstock agencies, trend guidelines, and community discussions.
class MicrostockSeedData {
  static List<MicrostockNewsArticle> getSeedArticles() {
    return const [
      MicrostockNewsArticle(
        id: 'adobe-2026-trends',
        title: 'Adobe Stock Releases 2026 Visual Trend Forecast',
        summary: 'Autonomous robotics, clean energy, and authentic cultural celebrations lead creator demand.',
        source: 'Adobe Stock Brief',
        category: 'TRENDS',
        publishedDate: '2026-11-01',
        sourceUrl: 'https://stock.adobe.com/trends',
        tags: ['#AdobeStock', '#VisualTrends', '#Robotics', '#CleanEnergy'],
        readTime: '4 min read',
        keyTakeaways: 'Enterprise buyers prioritize vertical portrait (9:16) clips with micro-movements, authentic human expressions, and strict Rec.709 color profiles.',
        technicalSpecs: [
          'Aspect Ratio: 9:16 Vertical Portrait & 16:9 4K UHD',
          'Frame Rate: Constant 30.00 / 60.00 FPS (Strict CFR)',
          'Color Space: Rec.709 (BT.709) standard broadcast curve',
          'Encoding: H.264 / H.265 CRF 17-22, Moov Atom FastStart',
        ],
        contributorChecklist: [
          'Pastikan tidak ada logo merk/brand terlihat pada latar belakang.',
          'Sertakan model release legal jika menampilkan wajah manusia jelas.',
          'Hindari filter over-sharpening yang memunculkan white halos di tepi objek.',
          'Gunakan nama file deskriptif berbasis keyword tanpa karakter spesial.',
        ],
        fullContent:
            'Adobe Stock has officially unveiled its comprehensive 2026 Visual Trend Forecast for video creators and contributors worldwide. Analysis of over 85 million commercial search queries demonstrates a dramatic 140% surge in requests for authentic, unpolished cinematography highlighting autonomous industrial robotics, distributed renewable energy installations, and localized cultural celebrations.\n\nCommercial advertising agencies and enterprise social media managers now heavily favor vertical 9:16 portrait assets over traditional landscape video. Ingestion algorithms directly deprioritize footage suffering from variable frame rate stutter, harsh artificial sharpness, or inconsistent gamma curves.\n\nTo maximize licensing revenue, contributors should produce 5-15 second looping B-roll clips with subtle handheld or slow-gimbal micro-movements. Clips featuring genuine candid smiles, diverse age demographics, and natural workplace interaction achieve the highest click-through rates across corporate branding campaigns.',
      ),
      MicrostockNewsArticle(
        id: 'shutterstock-4k-specs',
        title: 'Shutterstock Accelerates Editorial Video Requirements',
        summary: '4K 60FPS CFR format with clean primary BT.709 color spaces now favored for enterprise licensing.',
        source: 'Shutterstock Official',
        category: 'REQUIREMENTS',
        publishedDate: '2026-10-28',
        sourceUrl: 'https://shutterstock.com/blog',
        tags: ['#Shutterstock', '#4K60FPS', '#BT709', '#CFR'],
        readTime: '3 min read',
        keyTakeaways: 'Variable Frame Rate (VFR) containers are immediately rejected by Shutterstock bot reviewers; files must have faststart headers.',
        technicalSpecs: [
          'Resolution: 3840×2160 (4K UHD) or 2560×1440 (2K QHD)',
          'Container & Flags: MP4 / MOV with -movflags +faststart',
          'Bitrate Target: 20-25 Mbps VBV cap (H.264 / H.265)',
          'Chroma Subsampling: 4:2:0 YUV baseline level 5.1',
        ],
        contributorChecklist: [
          'Ubah mode kamera ponsel dari VFR ke Constant Frame Rate (CFR).',
          'Periksa metadata EXIF dan GPS agar tidak mengekspos lokasi privat.',
          'Pastikan tidak ada audio statik berdengung atau clipped waveform.',
          'Cantumkan informasi Editorial yang akurat pada judul (Kota, Tanggal, Peristiwa).',
        ],
        fullContent:
            'Shutterstock has implemented stricter automated technical validation standards across its global ingest pipeline. The automated quality control system now performs frame-by-frame cadence analysis to reject Variable Frame Rate (VFR) videos that introduce sound desynchronization inside professional NLEs like Premiere Pro and DaVinci Resolve.\n\nFurthermore, all submitted MP4 files must feature the "moov atom" metadata packet positioned at the absolute start of the file structure. This guarantees immediate zero-buffering preview playback for corporate enterprise teams auditing assets on iOS and Android workstations.\n\nSubmissions with crushed shadows, clipped high-key highlights, or non-compliant color matrices (such as un-tagged BT.2020) are automatically rejected. The platform recommends shooting in flat profiles and grading strictly into Rec.709.',
      ),
      MicrostockNewsArticle(
        id: 'reddit-microstock-evasion',
        title: 'Community Discussion: AI Duplicate Detection on Cross-Agency Uploads',
        summary: 'Contributors discuss perceptual hashing algorithms used by Shutterstock and Adobe Stock in late 2026.',
        source: 'Reddit Community Discussion',
        category: 'COMMUNITY',
        publishedDate: '2026-10-26',
        sourceUrl: 'https://reddit.com/r/microstock/hot',
        tags: ['#Reddit', '#MicrostockCommunity', '#AntiDuplication', '#Hashing'],
        readTime: '4 min read',
        keyTakeaways: 'Top contributors recommend 2-4% zoom, subtle sensor noise, and audio speed shifts (1.01x) to prevent false-positive duplicate bans.',
        technicalSpecs: [
          'Micro-Crop: 2% - 5% subtle frame re-centering',
          'Sensor Dither: Gaussian grain intensity 0.03',
          'Audio Pitch Warp: ±0.5% frequency variation',
          'Metadata: Complete camera serial & GPS sanitization',
        ],
        contributorChecklist: [
          'Jangan gunakan batch upload dengan frame rate berbeda-beda.',
          'Uji coba 1-2 file sampel sebelum upload 100 video sekaligus.',
          'Periksa apakah kurator manusia memberikan feedback serupa pada agensi lain.',
          'Gunakan deskripsi yang berbeda antara Shutterstock dan Adobe Stock.',
        ],
        fullContent:
            'A trending discussion on Reddit\'s r/microstock community sheds light on recent creator experiences with automated duplication flags across major agencies. Several full-time contributors reported that uploading identical ProRes exports to Shutterstock, Adobe Stock, and Freepik simultaneously triggered automated spam warnings on their portfolios.\n\nMembers analyzed the detection mechanism and confirmed agencies now compare multidimensional perceptual hashes and temporal cadence fingerprints. Slight trimming of intro frames alone is no longer sufficient to create a distinct media identity in the agency databases.\n\nThe consensus recommendation from experienced contributors is to apply systematic media uniquification: strip all EXIF hardware signatures, apply 2-4% dynamic spatial crop with face-aware framing, and introduce microscopic sensor noise. This ensures full compliance with agency anti-spam rules while protecting accounts from mistaken automated shadowbans.',
      ),
      MicrostockNewsArticle(
        id: 'freepik-bonus-program',
        title: 'Freepik Announces Enhanced Contributor Royalty Program',
        summary: 'High-converting microstock deduplication and cinematic footage unlock bonus revenue tiers.',
        source: 'Freepik Trends',
        category: 'EARNINGS',
        publishedDate: '2026-10-25',
        sourceUrl: 'https://freepik.com/contributor',
        tags: ['#Freepik', '#Royalties', '#Cinematic', '#Deduplication'],
        readTime: '3 min read',
        keyTakeaways: 'Top-tier 4K cinematic b-roll unlocks 25% royalty bonus, but duplicate or near-identical batch uploads face automated penalties.',
        technicalSpecs: [
          'Aspect Ratio: 16:9 Cinematic & 9:16 Vertical Reels',
          'Frame Rates: 24, 25, 30, or 60 FPS continuous',
          'Audio Profile: Clean ambient stereo or muted (volume=0.01)',
          'Duration: 6 to 30 seconds optimal loop lengths',
        ],
        contributorChecklist: [
          'Terapkan modifikasi vDNA (tilt/crop 1-3%) pada variasi adegan serupa.',
          'Pilih kategori dan tag microstock yang relevan maksimal 15-20 tags.',
          'Pastikan tidak ada watermark pribadi atau teks overlay.',
          'Unggah secara konsisten 10-20 klip berkualitas per minggu.',
        ],
        fullContent:
            'Freepik has officially rolled out its 2026 Contributor Royalty Booster Program, distributing over €2.5M in bonus rewards to creators of high-demand motion content. Footage categories achieving the fastest download velocity include urban lifestyle, culinary food preparation, modern workspace collaboration, and aesthetic background textures.\n\nHowever, Freepik also announced aggressive measures against catalog spamming. Contributors uploading identical footage with minor color grading changes risk account demotion. The platform uses deep visual hashes to detect perceptual duplication across contributor portfolios.\n\nTo safely maximize earnings, contributors are encouraged to introduce subtle optical variations, differing camera angles, and authentic physical micro-framing before batch uploading.',
      ),
      MicrostockNewsArticle(
        id: 'microstock-ai-dedup',
        title: 'Microstock AI Inspection Guidelines 2026',
        summary: 'Metadata stripping and sensor fingerprint variation prevent automated duplicate rejections.',
        source: 'Adobe Stock Brief',
        category: 'GUIDELINES',
        publishedDate: '2026-10-20',
        sourceUrl: 'https://microstockguild.org/guidelines',
        tags: ['#AntiDuplication', '#Metadata', '#SensorNoise', '#Evasion'],
        readTime: '5 min read',
        keyTakeaways: 'Clean metadata sanitization, micro-crop (1-5%), and imperceptible noise injection prevent false-positive duplicate bans.',
        technicalSpecs: [
          'Crop Margin: 1% - 8% dynamic inner-box scaling',
          'Noise Injection: Gaussian temporal noise (strength 3-5)',
          'Rotation / Tilt: 0.5° - 1.0° micro-rotation with clean borders',
          'Audio Pitch & Speed: 1.01x - 1.025x synchronized time warp',
        ],
        contributorChecklist: [
          'Hapus jejak GPS, serial kamera, dan signature software pengedit.',
          'Ganti metadata kamera sintetis dengan profil resmi (iPhone 15 Pro Max).',
          'Lakukan uji coba render preview sebelum upload massal ke 5 agensi.',
          'Pertahankan integritas rasio aspek agar tidak terdistorsi.',
        ],
        fullContent:
            'The Microstock Contributor Guild has released an essential operational whitepaper detailing how stock platforms deploy neural networks and perceptual hashing to detect duplicate uploads across different accounts and sibling agencies.\n\nThese automated inspection algorithms compute multidimensional feature vectors capturing high-frequency sensor noise patterns, edge geometry, and color distribution. When a creator distributes identical footage across multiple agencies, aggressive bots can trigger automatic rejections or shadowbans.\n\nEthical uniquification practices recommended by the Guild include stripping synthetic encoding tags, injecting subtle microscopic grain, adjusting spatial framing by 1-5% with face-focus crop anchors, and modifying audio frequency spectrums without degrading perceptible consumer playback quality.',
      ),
    ];
  }
}
