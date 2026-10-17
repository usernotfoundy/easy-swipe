import 'package:flutter/material.dart';

class SwipeControls extends StatelessWidget {
  final VoidCallback? onUndo;
  final VoidCallback? onDelete;
  final VoidCallback? onKeep;
  final VoidCallback? onInfo;
  final bool canUndo;
  final bool enabled;

  const SwipeControls({
    super.key,
    required this.onUndo,
    required this.onDelete,
    required this.onKeep,
    required this.onInfo,
    this.canUndo = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Undo Button
          _buildActionButton(
            icon: Icons.replay_rounded,
            color: const Color(0xFFF59E0B),
            size: 50,
            iconSize: 26,
            isEnabled: enabled && canUndo,
            tooltip: 'Undo last swipe',
            onTap: onUndo,
          ),

          // Delete Button (Left Swipe)
          _buildActionButton(
            icon: Icons.close_rounded,
            color: const Color(0xFFF43F5E),
            size: 64,
            iconSize: 32,
            isEnabled: enabled,
            tooltip: 'Swipe left to delete',
            onTap: onDelete,
          ),

          // Details / Info Button
          _buildActionButton(
            icon: Icons.info_outline_rounded,
            color: const Color(0xFF38BDF8),
            size: 50,
            iconSize: 24,
            isEnabled: enabled,
            tooltip: 'Photo info',
            onTap: onInfo,
          ),

          // Keep Button (Right Swipe)
          _buildActionButton(
            icon: Icons.favorite_rounded,
            color: const Color(0xFF10B981),
            size: 64,
            iconSize: 32,
            isEnabled: enabled,
            tooltip: 'Swipe right to keep',
            onTap: onKeep,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    required bool isEnabled,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    final effectiveColor = isEnabled ? color : Colors.white24;

    return Tooltip(
      message: tooltip,
      child: AnimatedScale(
        scale: isEnabled ? 1.0 : 0.88,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B).withOpacity(0.9),
            border: Border.all(
              color: effectiveColor.withOpacity(isEnabled ? 0.35 : 0.1),
              width: 2,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(size / 2),
              onTap: isEnabled ? onTap : null,
              splashColor: color.withOpacity(0.3),
              highlightColor: color.withOpacity(0.15),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: effectiveColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
