import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_item.dart';
import '../state/gallery_state.dart';
import '../widgets/photo_info_dialog.dart';
import '../widgets/swipe_card.dart';
import '../widgets/swipe_controls.dart';
import 'review_screen.dart';
import 'select_start_photo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GalleryState _galleryState = GalleryState();
  final CardSwipeController _swipeController = CardSwipeController();
  bool _isProcessingSwipe = false;

  @override
  void initState() {
    super.initState();
    _galleryState.initialize();
  }

  @override
  void dispose() {
    _galleryState.dispose();
    super.dispose();
  }

  void _onSwipeAction(SwipeAction action, PhotoItem item) {
    if (_isProcessingSwipe) return;
    _isProcessingSwipe = true;
    if (action == SwipeAction.keep) {
      _galleryState.swipeKeep(item);
    } else {
      _galleryState.swipeDelete(item);
    }
    Future.microtask(() {
      if (mounted) {
        setState(() {
          _isProcessingSwipe = false;
        });
      }
    });
  }

  void _triggerKeep() {
    if (_isProcessingSwipe) return;
    _swipeController.swipeRight();
  }

  void _triggerDelete() {
    if (_isProcessingSwipe) return;
    _swipeController.swipeLeft();
  }

  void _openReviewScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => ReviewScreen(galleryState: _galleryState),
      ),
    );
  }

  void _openSelectStartPhotoScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => SelectStartPhotoScreen(galleryState: _galleryState),
      ),
    );
  }

  void _showAlbumPicker() {
    final albums = _galleryState.albums;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Album',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              // Option for Demo Sample Photos
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.amber, size: 20),
                ),
                title: const Text('Sample Demo Photos',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Preloaded sample gallery',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                trailing: _galleryState.isDemoMode
                    ? const Icon(Icons.check, color: Color(0xFF10B981))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  _galleryState.switchToDemoMode();
                },
              ),
              const Divider(color: Colors.white12, height: 1),
              // Device albums
              if (albums.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No device albums found',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: albums.length,
                    itemBuilder: (c, idx) {
                      final album = albums[idx];
                      final isSelected = !_galleryState.isDemoMode &&
                          _galleryState.currentAlbum?.id == album.id;
                      return ListTile(
                        leading: const Icon(Icons.photo_library_rounded,
                            color: Color(0xFF6366F1)),
                        title: Text(
                          album.name,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Color(0xFF10B981))
                            : null,
                        onTap: () {
                          Navigator.pop(ctx);
                          _galleryState.selectAlbum(album);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _galleryState,
      builder: (context, _) {
        final deleteCount = _galleryState.deleteQueue.length;
        final hasMore = _galleryState.hasMorePhotos;
        final currentPhoto = _galleryState.currentPhoto;
        final nextPhoto = _galleryState.nextPhoto;

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1E293B),
            elevation: 0,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.style_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'EasySwipe',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              // Choose starting photo
              IconButton(
                icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
                tooltip: 'Choose Starting Photo',
                onPressed: _openSelectStartPhotoScreen,
              ),

              // Album / source selector
              IconButton(
                icon: const Icon(Icons.folder_open_rounded, color: Colors.white),
                tooltip: 'Select Album',
                onPressed: _showAlbumPicker,
              ),

              // Review Queue Button with badge
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: Colors.white),
                      tooltip: 'Review Swiped Photos',
                      onPressed: _openReviewScreen,
                    ),
                    if (deleteCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF43F5E),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF43F5E).withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$deleteCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Permission banner if permission is not granted
                if (!_galleryState.isDemoMode &&
                    !_galleryState.permissionState.isAuth &&
                    !_galleryState.permissionState.hasAccess &&
                    !_galleryState.isLoading)
                  _buildPermissionBanner(),

                // Status & Progress Bar
                _buildHeaderProgress(),

                // Main Tinder Stack Area
                Expanded(
                  child: _galleryState.isLoading
                      ? _buildLoadingState()
                      : (!hasMore
                          ? _buildDeckFinishedState()
                          : _buildCardDeck(currentPhoto!, nextPhoto)),
                ),

                // Bottom Control Buttons
                SwipeControls(
                  canUndo: _galleryState.canUndo,
                  enabled: hasMore && !_galleryState.isLoading,
                  onUndo: _galleryState.undoLastSwipe,
                  onDelete: _triggerDelete,
                  onKeep: _triggerKeep,
                  onInfo: currentPhoto != null
                      ? () => PhotoInfoDialog.show(context, currentPhoto)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPermissionBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded,
              color: Colors.amber, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Gallery access needed to manage your device photos.',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _galleryState.requestPermission,
            style: TextButton.styleFrom(
              foregroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderProgress() {
    final total = _galleryState.totalCount;
    final current = _galleryState.currentIndex;
    final progress = total > 0 ? (current / total).clamp(0.0, 1.0) : 0.0;
    final albumName = _galleryState.isDemoMode
        ? 'Sample Gallery'
        : (_galleryState.currentAlbum?.name ?? 'Recent');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: InkWell(
        onTap: _openSelectStartPhotoScreen,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      _galleryState.isDemoMode
                          ? Icons.auto_awesome
                          : Icons.photo_library_outlined,
                      size: 15,
                      color: const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      albumName,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      current < total
                          ? 'Photo #${current + 1} of $total'
                          : '$total of $total reviewed',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.tune_rounded,
                        size: 14, color: Color(0xFF6366F1)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF1E293B),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                minHeight: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF6366F1),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Loading photos...',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDeck(PhotoItem currentPhoto, PhotoItem? nextPhoto) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // Next Card (Behind top card)
              if (nextPhoto != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: 0.94,
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: const Offset(0, 12),
                        child: Opacity(
                          opacity: 0.75,
                          child: SwipeCard(
                            key: ValueKey('bg_${nextPhoto.id}'),
                            item: nextPhoto,
                            isTopCard: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Top Active Card
              Positioned.fill(
                child: SwipeCard(
                  key: ValueKey('top_${currentPhoto.id}'),
                  controller: _swipeController,
                  item: currentPhoto,
                  isTopCard: true,
                  onSwiped: (action) => _onSwipeAction(action, currentPhoto),
                  onInfoTap: () => PhotoInfoDialog.show(context, currentPhoto),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeckFinishedState() {
    final keptCount = _galleryState.keptPhotos.length;
    final deleteCount = _galleryState.deleteQueue.length;
    final totalSizeText = _galleryState.formattedTotalDeleteQueueSize;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.2),
                    const Color(0xFF10B981).withOpacity(0.2),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Caught Up!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You have reviewed all photos in this deck.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 28),

            // Summary Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Kept', '$keptCount', const Color(0xFF10B981)),
                  Container(width: 1, height: 40, color: Colors.white12),
                  _buildStatItem(
                      'For Delete', '$deleteCount', const Color(0xFFF43F5E)),
                  Container(width: 1, height: 40, color: Colors.white12),
                  _buildStatItem('Est. Space', totalSizeText,
                      const Color(0xFF38BDF8)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action: Review & Batch Delete
            if (deleteCount > 0) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF43F5E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: const Color(0xFFF43F5E).withOpacity(0.5),
                  ),
                  onPressed: _openReviewScreen,
                  icon: const Icon(Icons.delete_sweep_rounded),
                  label: Text(
                    'Review & Clean Up ($deleteCount photos)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action: Restart Deck
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _galleryState.restartDeck,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Start Over from Beginning (#1)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action: Choose Starting Photo
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF38BDF8),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _openSelectStartPhotoScreen,
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text(
                  'Choose Starting Photo',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
