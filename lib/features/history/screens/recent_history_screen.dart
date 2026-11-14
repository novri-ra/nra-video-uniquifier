import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage_space/storage_space.dart';
import '../../../core/services/history_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/top_app_bar.dart';
import '../widgets/history_empty_state.dart';
import '../widgets/history_item_card.dart';
import '../widgets/history_storage_bar.dart';

class RecentHistoryScreen extends StatefulWidget {
  const RecentHistoryScreen({super.key});

  @override
  State<RecentHistoryScreen> createState() => _RecentHistoryScreenState();
}

class _RecentHistoryScreenState extends State<RecentHistoryScreen>
    with WidgetsBindingObserver {
  List<VideoExportItem> _items = [];
  StorageSpace? _deviceStorage;
  bool _isLoading = true;
  String? _error;
  bool _isSelectionMode = false;
  final Set<String> _selectedItemPaths = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStoragePermissionOnMount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _verifyStoragePermissionOnResume();
      _loadHistory();
    }
  }

  Future<void> _verifyStoragePermissionOnResume() async {
    if (!mounted || !Platform.isAndroid) return;
    try {
      final isGranted = await Permission.manageExternalStorage.isGranted;
      if (isGranted && mounted) {
        setState(() {});
      }
    } catch (e) {
      // permission_handler errors may echo the permission name.
      debugPrint(
        '[RecentHistoryScreen] storage permission check failed: '
        '${e.runtimeType}',
      );
    }
  }

  Future<void> _checkStoragePermissionOnMount() async {
    if (!mounted || !Platform.isAndroid) return;
    final hasPermission = await HistoryService.hasStoragePermission();
    if (hasPermission) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasPrompted = prefs.getBool('has_prompted_manage_storage') ?? false;
      if (!hasPrompted && mounted) {
        await prefs.setBool('has_prompted_manage_storage', true);
        if (mounted) {
          _showStoragePermissionDialog();
        }
      }
    } catch (e) {
      // Fallback: If SharedPreferences fails, do not spam dialog
      debugPrint(
        '[RecentHistoryScreen] storage permission prompt failed: '
        '${e.runtimeType}',
      );
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
              color: AppColors.mintSage,
              size: 22,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'File Management Permission',
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
          'To scan, manage, and permanently delete exported videos from shared storage, Android requires "All Files Access" permission.\n\nPlease enable this permission on the settings screen that opens.',
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
              'Later',
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
              if (HistoryService.isAndroid11OrHigher) {
                await HistoryService.requestAllFilesAccessDirectly();
              } else {
                await HistoryService.requestStoragePermission();
              }
              if (!mounted) return;
              final ok = await HistoryService.hasStoragePermission();
              if (ok) {
                _loadHistory();
                onGranted?.call();
              } else {
                _showOpenSettingsPrompt();
              }
            },
            child: const Text('Grant Access'),
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

  Future<void> _showOpenSettingsPrompt() async {
    if (!mounted) return;
    final isGranted = await HistoryService.hasStoragePermission();
    if (isGranted) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: const Text(
            'All Files Access permission is required. Open Settings to enable.',
          ),
          backgroundColor: AppColors.surfaceContainerHighest,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Settings',
            textColor: AppColors.mintSage,
            onPressed: () => HistoryService.requestAllFilesAccessDirectly(),
          ),
        ),
      );
    }
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
      debugPrint('[RecentHistoryScreen] load history failed: $e');
      if (mounted) {
        setState(() {
          _error = '${e.runtimeType}';
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
          'Delete $count Videos?',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Text(
          'Are you sure you want to permanently delete $count selected videos from this device?',
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
              'Delete All',
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
          AppToast.show(
            context,
            message: '$count video(s) permanently deleted',
            isError: true,
          );
        } else if (deletedPaths.isNotEmpty) {
          AppToast.show(
            context,
            message:
                '${deletedPaths.length} video(s) deleted. ${selectedItems.length - deletedPaths.length} failed to delete (verify storage permissions).',
            isError: true,
          );
        } else {
          AppToast.show(
            context,
            message:
                'Failed to delete selected videos. Ensure storage permissions are granted.',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('[RecentHistoryScreen] delete multiple items failed: $e');
      if (mounted) {
        AppToast.show(
          context,
          message: 'Unexpected error while deleting videos.',
          isError: true,
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

    try {
      final targetPath = item.file.path;
      final success = await HistoryService.deleteItem(item.file);
      if (mounted) {
        if (success) {
          setState(() {
            _items.removeWhere((i) => i.file.path == targetPath);
          });
          AppToast.show(
            context,
            message: 'Video permanently deleted from device',
            isError: true,
          );
        } else {
          AppToast.show(
            context,
            message:
                'Failed to delete physical file. Ensure storage permissions are granted.',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('[RecentHistoryScreen] delete item failed: $e');
      if (mounted) {
        AppToast.show(
          context,
          message: 'Unexpected error while deleting video.',
          isError: true,
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
      debugPrint('[RecentHistoryScreen] share item failed: $e');
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to share video.',
          isError: true,
        );
      }
    }
  }

  Future<void> _openItem(VideoExportItem item) async {
    try {
      final res = await OpenFilex.open(item.file.path);
      if (res.type != ResultType.done && mounted) {
        AppToast.show(
          context,
          message: 'Unable to open: ${res.message}',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('[RecentHistoryScreen] open item failed: $e');
      if (mounted) {
        AppToast.show(context, message: 'Failed to open video.', isError: true);
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
