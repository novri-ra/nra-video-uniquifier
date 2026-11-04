import 'package:flutter/foundation.dart';
import '../models/batch_video_item.dart';
import '../services/ffmpeg_service.dart';
import '../services/notification_service.dart';
import 'uniquifier_provider.dart';

class BatchQueueProvider extends ChangeNotifier {
  final List<BatchVideoItem> _items = [];
  bool _isProcessing = false;
  int _currentIndex = -1;
  bool _isCancelled = false;

  List<BatchVideoItem> get items => List.unmodifiable(_items);
  bool get isProcessing => _isProcessing;
  int get currentIndex => _currentIndex;
  bool get isCancelled => _isCancelled;

  int get totalCount => _items.length;
  int get completedCount => _items.where((e) => e.isCompleted).length;
  int get failedCount => _items.where((e) => e.isFailed).length;
  bool get hasItems => _items.isNotEmpty;

  double get overallProgress {
    if (_items.isEmpty) return 0.0;
    double sum = 0.0;
    for (final item in _items) {
      if (item.isCompleted) {
        sum += 1.0;
      } else if (item.isProcessing) {
        sum += item.progress;
      }
    }
    return (sum / _items.length).clamp(0.0, 1.0);
  }

  void addItems(List<BatchVideoItem> newItems) {
    if (_isProcessing) return;
    _items.addAll(newItems);
    notifyListeners();
  }

  void setItems(List<BatchVideoItem> newItems) {
    if (_isProcessing) return;
    _items.clear();
    _items.addAll(newItems);
    _currentIndex = -1;
    notifyListeners();
  }

  void removeItem(int index) {
    if (_isProcessing || index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_isProcessing) return;
    _items.clear();
    _currentIndex = -1;
    notifyListeners();
  }

  Future<void> cancelBatch() async {
    _isCancelled = true;
    await FfmpegService.cancel();
    await NotificationService.cancelProgressNotification();
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isPending || _items[i].isProcessing) {
        _items[i].status = BatchItemStatus.cancelled;
      }
    }
    _isProcessing = false;
    notifyListeners();
  }

  void cancelItem(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].isPending) {
      _items[index].status = BatchItemStatus.cancelled;
      notifyListeners();
    }
  }

  Future<void> runBatch(UniquifierProvider config) async {
    if (_isProcessing || _items.isEmpty) return;
    _isProcessing = true;
    _isCancelled = false;
    notifyListeners();

    for (int i = 0; i < _items.length; i++) {
      if (_isCancelled) break;
      await _processSingleItem(i, _items[i], config);
      // Inter-item memory purge to prevent OOM
      if (i < _items.length - 1) await _interItemCleanup();
    }

    _isProcessing = false;
    await NotificationService.cancelProgressNotification();
    if (!_isCancelled) {
      await NotificationService.showCompleteNotification(
        title: 'Batch Processing Finished',
        body:
            '$completedCount of ${_items.length} videos completed successfully',
        success: failedCount == 0,
      );
    }
    notifyListeners();
  }

  Future<void> _processSingleItem(
    int i,
    BatchVideoItem current,
    UniquifierProvider config,
  ) async {
    _currentIndex = i;
    current.status = BatchItemStatus.processing;
    current.progress = 0.0;
    notifyListeners();

    try {
      final outputPath = await _executeBatchItem(i, current, config);
      current.status = BatchItemStatus.completed;
      current.outputPath = outputPath;
      current.progress = 1.0;
    } catch (e) {
      current.status = _isCancelled
          ? BatchItemStatus.cancelled
          : BatchItemStatus.failed;
      if (!_isCancelled) current.error = e.toString();
    }
    notifyListeners();
  }

  Future<String> _executeBatchItem(
    int i,
    BatchVideoItem current,
    UniquifierProvider config,
  ) {
    return FfmpegService.processVideo(
      inputPath: current.path,
      removeMetadata: config.removeMetadata,
      modifyAudio: config.modifyAudio,
      modifyVisuals: config.modifyVisuals,
      upscale1080p: config.upscale1080p,
      targetResolution: config.targetResolution,
      upscaleEngine: config.upscaleEngine,
      videoCodec: config.videoCodec,
      enableEnhanceAndDenoise: config.enableEnhanceAndDenoise,
      enableDeepAntiFingerprint: config.enableDeepAntiFingerprint,
      enableHorizontalFlip: config.enableHorizontalFlip,
      enableAggressiveAudio: config.enableAggressiveAudio,
      enableAutoTrim: config.enableAutoTrim,
      isPortrait: null,
      enableHardwareAcceleration: config.hardwareAcceleration,
      enableBlurredCanvas: config.enableBlurredCanvas,
      canvasScalePercent: config.canvasScalePercent,
      muteOriginalAudio: config.muteOriginalAudio,
      enableDynamicZoom: config.enableDynamicZoom,
      enableMicroOverlay: config.enableMicroOverlay,
      enableFrameSkip: config.enableFrameSkip,
      enableChromaShift: config.enableChromaShift,
      thermalThrottle: config.thermalThrottle,
      suppressCompleteNotification: true,
      totalDurationMs: 0,
      targetFps: config.targetFps,
      saturationLevel: config.saturationLevel,
      sharpeningLevel: config.sharpeningLevel,
      cropZoomScale: config.cropZoomScale,
      cropAnchor: config.cropAnchor,
      introTrimOffset: config.introTrimOffset,
      onProgress: (p, speed, timeMs) =>
          _handleBatchProgress(i, p, speed, timeMs, current, config),
    );
  }

  void _handleBatchProgress(
    int i,
    double p,
    double speed,
    int timeMs,
    BatchVideoItem current,
    UniquifierProvider config,
  ) {
    if (_isCancelled || !current.isProcessing) return;
    current.progress = p;
    config.updateRealtimeStats(p, speed, timeMs);
    final pct = (p * 100).toInt();
    NotificationService.showProgressNotification(
      progress: pct,
      title: 'Batch [${i + 1}/${_items.length}] ${current.name}',
      body: '$pct% • Overall ${(overallProgress * 100).toInt()}%',
    );
    notifyListeners();
  }

  Future<void> _interItemCleanup() async {
    // Yield to event loop between items to release memory
    await Future<void>.value();
  }
}
