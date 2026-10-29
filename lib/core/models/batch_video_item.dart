enum BatchItemStatus { pending, processing, completed, failed, cancelled }

class BatchVideoItem {
  final String id;
  final String path;
  final String name;
  final int sizeBytes;
  BatchItemStatus status;
  double progress;
  String? outputPath;
  String? error;

  BatchVideoItem({
    required this.id,
    required this.path,
    required this.name,
    required this.sizeBytes,
    this.status = BatchItemStatus.pending,
    this.progress = 0.0,
    this.outputPath,
    this.error,
  });

  bool get isPending => status == BatchItemStatus.pending;
  bool get isProcessing => status == BatchItemStatus.processing;
  bool get isCompleted => status == BatchItemStatus.completed;
  bool get isFailed => status == BatchItemStatus.failed;
  bool get isCancelled => status == BatchItemStatus.cancelled;

  String get formattedSize {
    if (sizeBytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double d = sizeBytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return '${d.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
