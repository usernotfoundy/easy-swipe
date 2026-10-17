import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../models/photo_item.dart';

class PhotoInfoDialog extends StatefulWidget {
  final PhotoItem item;

  const PhotoInfoDialog({super.key, required this.item});

  static Future<void> show(BuildContext context, PhotoItem item) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => PhotoInfoDialog(item: item),
    );
  }

  @override
  State<PhotoInfoDialog> createState() => _PhotoInfoDialogState();
}

class _PhotoInfoDialogState extends State<PhotoInfoDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.item.fileSizeBytes == null) {
      widget.item.getOrFetchFileSize().then((size) {
        if (mounted && size > 0) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • hh:mm:ss a');
    final formattedDate = dateFormat.format(item.createDateTime);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: item.assetEntity != null
                      ? AssetEntityImage(
                          item.assetEntity!,
                          isOriginal: false,
                          thumbnailSize: const ThumbnailSize(200, 200),
                          fit: BoxFit.cover,
                        )
                      : (item.mockUrl != null
                          ? Image.network(item.mockUrl!, fit: BoxFit.cover)
                          : Container(color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Photo Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),

          // Detail rows
          _buildInfoRow(
            icon: Icons.calendar_today_rounded,
            title: 'Date Created',
            value: formattedDate,
          ),
          _buildInfoRow(
            icon: Icons.aspect_ratio_rounded,
            title: 'Resolution',
            value: item.formattedDimensions.isNotEmpty
                ? '${item.formattedDimensions} px'
                : 'Unknown',
          ),
          _buildInfoRow(
            icon: Icons.data_usage_rounded,
            title: 'File Size',
            value: item.formattedFileSize,
          ),
          _buildInfoRow(
            icon: Icons.perm_media_rounded,
            title: 'Type',
            value: item.isMock ? 'Demo / Sample Image' : 'Device Gallery Asset',
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
