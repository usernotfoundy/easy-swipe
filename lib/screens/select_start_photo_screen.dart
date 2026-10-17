import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_item.dart';
import '../state/gallery_state.dart';

class SelectStartPhotoScreen extends StatefulWidget {
  final GalleryState galleryState;

  const SelectStartPhotoScreen({super.key, required this.galleryState});

  @override
  State<SelectStartPhotoScreen> createState() => _SelectStartPhotoScreenState();
}

class _SelectStartPhotoScreenState extends State<SelectStartPhotoScreen> {
  late int _selectedIndex;
  bool _markPreviousAsKept = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Default selected index is current deck index (clamped to bounds)
    final total = widget.galleryState.photos.length;
    _selectedIndex = widget.galleryState.currentIndex.clamp(0, total > 0 ? total - 1 : 0);

    // Scroll automatically to current position after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedIndex > 0 && _scrollController.hasClients) {
        // Approximate row height (width / 3 * 1.25)
        final row = _selectedIndex ~/ 3;
        final targetOffset = row * 160.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmSelection() {
    widget.galleryState.jumpToIndex(
      _selectedIndex,
      markPreviousAsKept: _markPreviousAsKept,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Swiping deck now starts at photo #${_selectedIndex + 1}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.galleryState.photos;
    final total = photos.length;
    final currentDeckIndex = widget.galleryState.currentIndex;
    final selectedPhoto = (total > 0 && _selectedIndex < total) ? photos[_selectedIndex] : null;
    final remainingFromSelection = total > 0 ? total - _selectedIndex : 0;

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
              'Choose Starting Photo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$total photos available • Tap to select where to begin',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          // Jump to first photo
          IconButton(
            icon: const Icon(Icons.first_page_rounded, color: Colors.white70),
            tooltip: 'Jump to beginning (#1)',
            onPressed: total > 0
                ? () {
                    setState(() {
                      _selectedIndex = 0;
                    });
                    _scrollController.animateTo(
                      0.0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                : null,
          ),
          // Jump to current active deck photo
          if (currentDeckIndex < total)
            IconButton(
              icon: const Icon(Icons.my_location_rounded, color: Color(0xFF38BDF8)),
              tooltip: 'Jump to current photo (#${currentDeckIndex + 1})',
              onPressed: () {
                setState(() {
                  _selectedIndex = currentDeckIndex;
                });
                final row = _selectedIndex ~/ 3;
                _scrollController.animateTo(
                  (row * 160.0).clamp(0.0, _scrollController.position.maxScrollExtent),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              },
            ),
        ],
      ),
      body: total == 0
          ? const Center(
              child: Text(
                'No photos available',
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
            )
          : Column(
              children: [
                // Quick info hint banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.touch_app_rounded,
                          size: 20, color: Color(0xFF6366F1)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Selected photo #${_selectedIndex + 1}. Swiping will continue from here downwards ($remainingFromSelection photos).',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Photo Grid
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.76,
                    ),
                    itemCount: total,
                    itemBuilder: (context, index) {
                      final item = photos[index];
                      final isSelected = index == _selectedIndex;
                      final isCurrentDeck = index == currentDeckIndex;
                      final isAlreadyKept = widget.galleryState.keptPhotos.contains(item);
                      final isAlreadyDelete = widget.galleryState.deleteQueue.contains(item);

                      return _buildGridCard(
                        item: item,
                        index: index,
                        isSelected: isSelected,
                        isCurrentDeck: isCurrentDeck,
                        isAlreadyKept: isAlreadyKept,
                        isAlreadyDelete: isAlreadyDelete,
                      );
                    },
                  ),
                ),

                // Bottom Action Panel
                if (selectedPhoto != null)
                  _buildBottomControl(selectedPhoto, remainingFromSelection),
              ],
            ),
    );
  }

  Widget _buildGridCard({
    required PhotoItem item,
    required int index,
    required bool isSelected,
    required bool isCurrentDeck,
    required bool isAlreadyKept,
    required bool isAlreadyDelete,
  }) {
    final dateFormat = DateFormat('MMM d');
    final dateStr = dateFormat.format(item.createDateTime);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isCurrentDeck
                    ? const Color(0xFF38BDF8)
                    : Colors.white12),
            width: isSelected ? 3.0 : (isCurrentDeck ? 2.0 : 1.0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
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

              // Dim overlay if before selected index
              if (index < _selectedIndex)
                Container(
                  color: Colors.black.withOpacity(0.35),
                ),

              // Bottom gradient for date
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 38,
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

              // Bottom Date tag
              Positioned(
                bottom: 5,
                left: 6,
                right: 6,
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Index Badge (Top Left)
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1)
                        : Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Status Badge (Top Right)
              Positioned(
                top: 6,
                right: 6,
                child: _buildStatusBadge(
                  isSelected: isSelected,
                  isCurrentDeck: isCurrentDeck,
                  isAlreadyKept: isAlreadyKept,
                  isAlreadyDelete: isAlreadyDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isSelected,
    required bool isCurrentDeck,
    required bool isAlreadyKept,
    required bool isAlreadyDelete,
  }) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xFF6366F1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
      );
    }

    if (isCurrentDeck) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF38BDF8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'CURRENT',
          style: TextStyle(
            color: Colors.black,
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    if (isAlreadyDelete) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFFF43F5E).withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 12),
      );
    }

    if (isAlreadyKept) {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 12),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBottomControl(PhotoItem selectedPhoto, int remainingCount) {
    final hasPhotosBefore = _selectedIndex > 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox for marking previous as kept
            if (hasPhotosBefore)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _markPreviousAsKept = !_markPreviousAsKept;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _markPreviousAsKept,
                          onChanged: (val) {
                            setState(() {
                              _markPreviousAsKept = val ?? true;
                            });
                          },
                          activeColor: const Color(0xFF10B981),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mark previous $_selectedIndex photos (#1 to #$_selectedIndex) as Kept',
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Confirm Button
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Start from #${_selectedIndex + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$remainingCount photos left to swipe',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  onPressed: _confirmSelection,
                  icon: const Icon(Icons.play_arrow_rounded, size: 22),
                  label: const Text(
                    'Start Swiping Here',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
