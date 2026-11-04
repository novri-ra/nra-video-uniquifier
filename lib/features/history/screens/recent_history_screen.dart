import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStoragePermissionOnMount();
    });
  }

  Future<void> _checkStoragePermissionOnMount() async {
    if (!mounted || !Platform.isAndroid) return;
    final hasPermission = await HistoryService.hasStoragePermission();
    if (!hasPermission && mounted) {
      _showStoragePermissionDialog();
    }
  }

  Future<bool> _showStoragePermissionDialog({VoidCallback? onGranted}) async {
    if (!mounted) return false;
    final granted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(
              Icons.folder_shared_outlined,
              color: AppColors.primaryContainer,
              size: 22,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Izin Akses Penyimpanan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'NRA Video Uniquifier memerlukan izin akses penyimpanan untuk memindai, membuka, dan menghapus riwayat video hasil ekspor dari perangkat secara permanen.',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Nanti',
              style: TextStyle(color: AppColors.outline),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(true);
              final ok = await HistoryService.requestStoragePermission();
              if (ok) {
                if (mounted) {
                  _loadHistory();
                  onGranted?.call();
                }
              } else if (mounted) {
                _showOpenSettingsPrompt();
              }
            },
            child: const Text('Izinkan Akses'),
          ),
        ],
      ),
    );

    if (granted == true && mounted) {
      _loadHistory();
      return true;
    }
    return false;
  }

  void _showOpenSettingsPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Izin penyimpanan belum diberikan. Buka Pengaturan Aplikasi untuk mengaktifkan.',
        ),
        backgroundColor: AppColors.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Pengaturan',
          textColor: AppColors.primaryContainer,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
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

    final hasPermission = await HistoryService.hasStoragePermission();
    if (!hasPermission) {
      if (!mounted) return;
      final ok = await _showStoragePermissionDialog(
        onGranted: () => _deleteSelectedItems(),
      );
      if (!ok) return;
    }

    try {
      final selectedItems = _items
          .where((i) => _selectedItemPaths.contains(i.file.path))
          .toList();
      final deletedPaths = await HistoryService.deleteExportItemsDetailed(
        selectedItems,
      );

      if (mounted) {
        setState(() {
          _items.removeWhere((i) => deletedPaths.contains(i.file.path));
          _selectedItemPaths.removeWhere((path) => deletedPaths.contains(path));
          if (_selectedItemPaths.isEmpty) {
            _isSelectionMode = false;
          }
        });

        if (deletedPaths.length == selectedItems.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count video berhasil dihapus dari perangkat'),
              backgroundColor: AppColors.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (deletedPaths.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${deletedPaths.length} video berhasil dihapus. ${selectedItems.length - deletedPaths.length} video gagal dihapus (periksa izin penyimpanan).',
              ),
              backgroundColor: AppColors.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal menghapus video terpilih. Pastikan izin akses penyimpanan telah diberikan.',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat menghapus video: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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

    final hasPermission = await HistoryService.hasStoragePermission();
    if (!hasPermission) {
      if (!mounted) return;
      final ok = await _showStoragePermissionDialog(
        onGranted: () => _deleteItem(item),
      );
      if (!ok) return;
    }

    try {
      final targetPath = item.file.path;
      final success = await HistoryService.deleteItem(item.file);
      if (mounted) {
        if (success) {
          setState(() {
            _items.removeWhere((i) => i.file.path == targetPath);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video berhasil dihapus dari perangkat'),
              backgroundColor: AppColors.surfaceContainerHighest,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal menghapus berkas fisik dari penyimpanan. Pastikan izin akses penyimpanan telah diberikan.',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan saat menghapus video: $e'),
            backgroundColor: AppColors.error,
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
