import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_item.dart';
import '../state/gallery_state.dart';

class ReviewScreen extends StatefulWidget {
  final GalleryState galleryState;

  const ReviewScreen({super.key, required this.galleryState});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // Set of photo IDs currently selected for batch deletion
  final Set<String> _selectedForDeletion = {};

  @override
  void initState() {
    super.initState();
    // By default, everything in the delete queue is selected for deletion
    for (final item in widget.galleryState.deleteQueue) {
      _selectedForDeletion.add(item.id);
      if (item.fileSizeBytes == null) {
        item.getOrFetchFileSize().then((size) {
          if (mounted && size > 0) {
            setState(() {});
          }
        });
      }
    }
  }

  void _toggleSelection(PhotoItem item) {
    setState(() {
      if (_selectedForDeletion.contains(item.id)) {
        _selectedForDeletion.remove(item.id);
      } else {
        _selectedForDeletion.add(item.id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final item in widget.galleryState.deleteQueue) {
        _selectedForDeletion.add(item.id);
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedForDeletion.clear();
    });
  }

  void _restoreItem(PhotoItem item) {
    widget.galleryState.restoreFromDeleteQueue(item);
    setState(() {
      _selectedForDeletion.remove(item.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored "${item.title}" to Keep list'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restoreAllDeselected() {
    final deselectedItems = widget.galleryState.deleteQueue
        .where((item) => !_selectedForDeletion.contains(item.id))
        .toList();

    if (deselectedItems.isEmpty) return;

    widget.galleryState.restoreMultipleFromDeleteQueue(deselectedItems);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored ${deselectedItems.length} photos'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showConfirmDeleteDialog() async {
    final selectedItems = widget.galleryState.deleteQueue
        .where((item) => _selectedForDeletion.contains(item.id))
        .toList();

    if (selectedItems.isEmpty) return;

    int totalSelectedBytes = 0;
    for (final it in selectedItems) {
      totalSelectedBytes += (it.fileSizeBytes ?? 0);
    }
    String sizeStr = '';
    if (totalSelectedBytes > 0) {
      final mb = totalSelectedBytes / (1024 * 1024);
      sizeStr = ' (~${mb.toStringAsFixed(1)} MB)';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF43F5E).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFF43F5E),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirm Deletion',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete ${selectedItems.length} photos$sizeStr from your gallery?\n\nThis cannot be undone.',
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Forever',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Also restore any deselected items back to keep list automatically
      _restoreAllDeselected();

      final deletedCount =
          await widget.galleryState.confirmBatchDelete(selectedItems);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Deleted $deletedCount photos from gallery.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _openFullPreview(PhotoItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: item.assetEntity != null
                      ? AssetEntityImage(
                          item.assetEntity!,
                          isOriginal: true,
                          fit: BoxFit.fitWidth,
                        )
                      : (item.mockUrl != null
                          ? Image.network(item.mockUrl!, fit: BoxFit.fitWidth)
                          : const SizedBox.shrink()),
                ),
              ),
            ),
            // Top Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.galleryState,
      builder: (context, _) {
        final queue = widget.galleryState.deleteQueue;
        final selectedCount = queue
            .where((item) => _selectedForDeletion.contains(item.id))
            .length;

        int selectedBytes = 0;
        for (final item in queue) {
          if (_selectedForDeletion.contains(item.id)) {
            selectedBytes += (item.fileSizeBytes ?? 0);
          }
        }
        final mb = selectedBytes / (1024 * 1024);
        final sizeText =
            mb > 0 ? '${mb.toStringAsFixed(1)} MB' : '${queue.length} items';

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review Swiped Photos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${queue.length} marked for deletion • $sizeText',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              if (queue.isNotEmpty)
                TextButton(
                  onPressed: _selectedForDeletion.length == queue.length
                      ? _deselectAll
                      : _selectAll,
                  child: Text(
                    _selectedForDeletion.length == queue.length
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          body: queue.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Info banner explaining how review & undo works
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: Color(0xFF38BDF8),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Uncheck photos to exclude them from deletion, or tap Restore to return them to Keep.',
                              style: TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Grid of photos
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: queue.length,
                        itemBuilder: (context, index) {
                          final item = queue[index];
                          final isSelected =
                              _selectedForDeletion.contains(item.id);

                          return _buildGridItem(item, isSelected);
                        },
                      ),
                    ),

                    // Bottom Finalize & Confirm Bar
                    _buildBottomActionPanel(selectedCount, sizeText),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildGridItem(PhotoItem item, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSelection(item),
      onLongPress: () => _openFullPreview(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFF43F5E) : Colors.white24,
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFF43F5E).withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo Image
              if (item.assetEntity != null)
                AssetEntityImage(
                  item.assetEntity!,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize(300, 400),
                  fit: BoxFit.cover,
                )
              else if (item.mockUrl != null)
                Image.network(item.mockUrl!, fit: BoxFit.cover)
              else
                Container(color: Colors.grey[800]),

              // Dim overlay if deselected (meaning excluded / safe)
              if (!isSelected)
                Container(
                  color: Colors.black.withOpacity(0.45),
                ),

              // Gradient at bottom for text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom size tag
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  item.formattedFileSize,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Top Selection Indicator
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFFF43F5E)
                        : Colors.black.withOpacity(0.6),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isSelected
                          ? Icons.delete_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 14,
                      color: isSelected ? Colors.white : Colors.white70,
                    ),
                  ),
                ),
              ),

              // Quick Restore button (Top Left)
              Positioned(
                top: 6,
                left: 6,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _restoreItem(item),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.65),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.undo_rounded,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E293B),
                border: Border.all(color: Colors.white12),
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Photos in Delete Queue',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Swipe left on photos in the main deck to queue them for review and batch deletion.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'Back to Swiping',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionPanel(int selectedCount, String sizeText) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCount selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedCount > 0
                        ? 'Will free $sizeText'
                        : 'No photos selected',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF43F5E),
                disabledBackgroundColor: Colors.white12,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white38,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: selectedCount > 0 ? 6 : 0,
                shadowColor: const Color(0xFFF43F5E).withOpacity(0.5),
              ),
              onPressed: selectedCount > 0 ? _showConfirmDeleteDialog : null,
              icon: const Icon(Icons.delete_forever_rounded, size: 20),
              label: Text(
                'Confirm Delete ($selectedCount)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
