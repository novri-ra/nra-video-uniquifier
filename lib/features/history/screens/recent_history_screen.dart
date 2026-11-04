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
  bool _isSelectionMode = false;
  final Set<String> _selectedItemPaths = <String>{};

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
      _selectedItemPaths.clear();
      _isSelectionMode = false;
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
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedItemPaths.clear();
      }
    });
  }

  void _toggleItemSelection(VideoExportItem item) {
    setState(() {
      if (_selectedItemPaths.contains(item.file.path)) {
        _selectedItemPaths.remove(item.file.path);
      } else {
        _selectedItemPaths.add(item.file.path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedItemPaths.length == _items.length) {
        _selectedItemPaths.clear();
      } else {
        _selectedItemPaths.clear();
        _selectedItemPaths.addAll(_items.map((i) => i.file.path));
      }
    });
  }

  Future<bool> _confirmBatchDelete(int count) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Hapus $count Video?',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus $count video terpilih secara permanen dari perangkat?',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus Semua',
              style: TextStyle(color: AppColors.vividCoral),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedItemPaths.isEmpty) return;
    final count = _selectedItemPaths.length;
    if (!await _confirmBatchDelete(count)) return;

    final selectedItems = _items
        .where((i) => _selectedItemPaths.contains(i.file.path))
        .toList();
    await HistoryService.deleteExportItems(selectedItems);

    if (mounted) {
      setState(() {
        _items.removeWhere((i) => _selectedItemPaths.contains(i.file.path));
        _selectedItemPaths.clear();
        _isSelectionMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count video berhasil dihapus dari perangkat'),
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<bool> _confirmDelete(VideoExportItem item) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Video?',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Delete ${item.fileName}?',
          style: const TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _deleteItem(VideoExportItem item) async {
    if (!await _confirmDelete(item)) return;
    try {
      final targetPath = item.file.path;
      final existed = await item.file.exists();
      await HistoryService.deleteItem(item.file);
      if (mounted) {
        setState(() {
          _items.removeWhere((i) => i.file.path == targetPath);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existed
                  ? 'Video berhasil dihapus'
                  : 'Berkas dibersihkan dari riwayat',
            ),
            backgroundColor: AppColors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _items.removeWhere((i) => i.file.path == item.file.path);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berkas dibersihkan dari riwayat'),
            backgroundColor: AppColors.surfaceContainerHighest,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _shareItem(VideoExportItem item) async {
    try {
      await Share.shareXFiles([
        XFile(item.file.path, mimeType: 'video/mp4'),
      ], text: 'Exported video: ${item.fileName}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _openItem(VideoExportItem item) async {
    try {
      final res = await OpenFilex.open(item.file.path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to open: ${res.message}'),
            backgroundColor: AppColors.surfaceContainerHighest,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Open error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = HistoryService.formatTotalSize(_items);

    return Scaffold(
      appBar: const TopAppBar(title: 'RECENT EXPORTS'),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          color: AppColors.primaryContainer,
          backgroundColor: AppColors.surface,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
            children: [
              HistoryHeader(
                itemCount: _items.length,
                totalSize: totalSize,
                onRefresh: _loadHistory,
                isSelectionMode: _isSelectionMode,
                selectedCount: _selectedItemPaths.length,
                onToggleSelectionMode: _toggleSelectionMode,
                onSelectAll: _selectAll,
                isAllSelected:
                    _items.isNotEmpty &&
                    _selectedItemPaths.length == _items.length,
                onDeleteSelected: _deleteSelectedItems,
              ),
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
          child: CircularProgressIndicator(
            color: AppColors.primaryContainer,
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            'Error loading history: $_error',
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
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
        final isSelected = _selectedItemPaths.contains(item.file.path);
        return HistoryItemCard(
          item: item,
          isSelectionMode: _isSelectionMode,
          isSelected: isSelected,
          onTap: () {
            if (_isSelectionMode) {
              _toggleItemSelection(item);
            } else {
              _openItem(item);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              setState(() {
                _isSelectionMode = true;
                _selectedItemPaths.add(item.file.path);
              });
            } else {
              _toggleItemSelection(item);
            }
          },
          onShare: () => _shareItem(item),
          onDelete: () => _deleteItem(item),
        );
      },
    );
  }
}
