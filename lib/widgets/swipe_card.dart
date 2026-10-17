import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_item.dart';

class CardSwipeController {
  SwipeCardState? _state;

  void attach(SwipeCardState state) {
    _state = state;
  }

  void detach(SwipeCardState state) {
    if (_state == state) {
      _state = null;
    }
  }

  void swipeLeft() {
    _state?.swipeLeft();
  }

  void swipeRight() {
    _state?.swipeRight();
  }
}

class SwipeCard extends StatefulWidget {
  final PhotoItem item;
  final bool isTopCard;
  final CardSwipeController? controller;
  final void Function(SwipeAction action)? onSwiped;
  final VoidCallback? onInfoTap;

  const SwipeCard({
    super.key,
    required this.item,
    this.isTopCard = true,
    this.controller,
    this.onSwiped,
    this.onInfoTap,
  });

  @override
  State<SwipeCard> createState() => SwipeCardState();
}

class SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  Offset _dragOffset = Offset.zero;
  double _rotation = 0.0;
  bool _isDragging = false;
  bool _hasSwiped = false;

  static const double _swipeThreshold = 110.0;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(SwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach(this);
      widget.controller?.attach(this);
    }
    if (oldWidget.item.id != widget.item.id) {
      _animController.stop();
      _animController.reset();
      _dragOffset = Offset.zero;
      _rotation = 0.0;
      _isDragging = false;
      _hasSwiped = false;
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(this);
    _animController.dispose();
    super.dispose();
  }

  /// Programmatic swipe left (Delete)
  void swipeLeft() {
    if (_hasSwiped || _animController.isAnimating) return;
    _animateAndComplete(const Offset(-550, 20), -0.35, SwipeAction.delete);
  }

  /// Programmatic swipe right (Keep)
  void swipeRight() {
    if (_hasSwiped || _animController.isAnimating) return;
    _animateAndComplete(const Offset(550, 20), 0.35, SwipeAction.keep);
  }

  void _animateAndComplete(
      Offset targetOffset, double targetRotation, SwipeAction action) {
    if (_hasSwiped) return;
    _hasSwiped = true;

    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _rotateAnimation = Tween<double>(
      begin: _rotation,
      end: targetRotation,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        widget.onSwiped?.call(action);
      }
    });
  }

  void _resetPosition() {
    _slideAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _rotateAnimation = Tween<double>(
      begin: _rotation,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTopCard) {
      return _buildCardContent(context);
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final currentOffset =
            _animController.isAnimating ? _slideAnimation.value : _dragOffset;
        final currentRotation =
            _animController.isAnimating ? _rotateAnimation.value : _rotation;

        return Transform.scale(
          scale: _isDragging ? 1.02 : 1.0,
          child: Transform.translate(
            offset: currentOffset,
            child: Transform.rotate(
              angle: currentRotation,
              child: GestureDetector(
                onPanStart: (details) {
                  if (_animController.isAnimating || _hasSwiped) return;
                  setState(() {
                    _isDragging = true;
                  });
                },
              onPanUpdate: (details) {
                if (_animController.isAnimating || _hasSwiped) return;
                setState(() {
                  _dragOffset += details.delta;
                  _rotation = (_dragOffset.dx / 320) * (math.pi / 14);
                });
              },
              onPanEnd: (details) {
                if (_animController.isAnimating || _hasSwiped) return;
                setState(() {
                  _isDragging = false;
                });

                final velocityX = details.velocity.pixelsPerSecond.dx;

                if (_dragOffset.dx > _swipeThreshold || velocityX > 750) {
                  _animateAndComplete(
                    Offset(550, _dragOffset.dy),
                    0.35,
                    SwipeAction.keep,
                  );
                } else if (_dragOffset.dx < -_swipeThreshold ||
                    velocityX < -750) {
                  _animateAndComplete(
                    Offset(-550, _dragOffset.dy),
                    -0.35,
                    SwipeAction.delete,
                  );
                } else {
                  _resetPosition();
                }
              },
              child: Stack(
                children: [
                  _buildCardContent(context),
                  _buildSwipeOverlays(),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _buildCardContent(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');
    final formattedDate = dateFormat.format(widget.item.createDateTime);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo Image
            _buildPhotoImage(),

            // Top subtle gradient for contrast
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 90,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Top info badge / Date indicator
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info Button (Top Right)
            if (widget.onInfoTap != null)
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: widget.onInfoTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),

            // Bottom gradient overlay for title & metadata
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 160,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.92),
                      Colors.black.withOpacity(0.65),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom info labels
            Positioned(
              left: 20,
              right: 20,
              bottom: 22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (widget.item.formattedDimensions.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.item.formattedDimensions,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.item.formattedFileSize,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (widget.item.isMock) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sample Demo',
                            style: TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoImage() {
    if (widget.item.assetEntity != null) {
      return AssetEntityImage(
        widget.item.assetEntity!,
        isOriginal: false,
        thumbnailSize: const ThumbnailSize(900, 1400),
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF6366F1),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 48,
                color: Colors.white38,
              ),
            ),
          );
        },
      );
    } else if (widget.item.mockUrl != null) {
      return Image.network(
        widget.item.mockUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF6366F1),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: const Color(0xFF1E293B),
            child: const Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 48,
                color: Colors.white38,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.white30),
        ),
      );
    }
  }

  Widget _buildSwipeOverlays() {
    final double dx = _dragOffset.dx;
    // Calculate opacity based on horizontal displacement
    final double rightOpacity = (dx / 120.0).clamp(0.0, 1.0);
    final double leftOpacity = (-dx / 120.0).clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // KEEP Badge (Swiping Right)
            if (rightOpacity > 0.05)
              Positioned(
                top: 36,
                left: 28,
                child: Opacity(
                  opacity: rightOpacity,
                  child: Transform.rotate(
                    angle: -0.22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'KEEP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // DELETE Badge (Swiping Left)
            if (leftOpacity > 0.05)
              Positioned(
                top: 36,
                right: 28,
                child: Opacity(
                  opacity: leftOpacity,
                  child: Transform.rotate(
                    angle: 0.22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF43F5E).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'DELETE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
