import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:storage_space/storage_space.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../widgets/history_empty_state.dart';
import '../widgets/history_item_card.dart';
import '../widgets/history_storage_bar.dart';

class RecentHistoryScreen extends StatefulWidget {
  const RecentHistoryScreen({super.key});

  @override
  State<RecentHistoryScreen> createState() => _RecentHistoryScreenState();
}

class _RecentHistoryScreenState extends State<RecentHistoryScreen> {
  List<VideoExportItem> _items = [];
  StorageSpace? _deviceStorage;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await HistoryService.loadHistory();
      final storage = await HistoryService.getDeviceStorage();
      if (mounted) {
        setState(() {
          _items = items;
          _deviceStorage = storage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<bool> _confirmDelete(VideoExportItem item) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Video?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text('Delete ${item.fileName}?', style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _deleteItem(VideoExportItem item) async {
    if (!await _confirmDelete(item)) return;
    try {
      await HistoryService.deleteItem(item.file);
      _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _shareItem(VideoExportItem item) async {
    try {
      await Share.shareXFiles(
        [XFile(item.file.path, mimeType: 'video/mp4')],
        text: 'Exported video: ${item.fileName}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _openItem(VideoExportItem item) async {
    try {
      final res = await OpenFilex.open(item.file.path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open: ${res.message}'), backgroundColor: AppColors.surfaceContainerHighest),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Open error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = HistoryService.formatTotalSize(_items);

    return Scaffold(
      appBar: const TopAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              HistoryHeader(itemCount: _items.length, totalSize: totalSize, onRefresh: _loadHistory),
              const SizedBox(height: 12),
              StorageTelemetryBar(
                totalSize: totalSize,
                hasItems: _items.isNotEmpty,
                deviceStorage: _deviceStorage,
              ),
              const SizedBox(height: 16),
              _buildContentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: AppColors.primaryContainer, strokeWidth: 2),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Error loading history: $_error', style: const TextStyle(color: AppColors.error, fontSize: 12)),
        ),
      );
    }
    if (_items.isEmpty) return const HistoryEmptyView();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _items[index];
        return HistoryItemCard(
          item: item,
          onTap: () => _openItem(item),
          onShare: () => _shareItem(item),
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }
}
