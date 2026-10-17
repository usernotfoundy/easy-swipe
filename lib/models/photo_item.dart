import 'package:photo_manager/photo_manager.dart';

enum SwipeAction { keep, delete }

class SwipeRecord {
  final PhotoItem item;
  final SwipeAction action;
  final int originalIndex;

  SwipeRecord({
    required this.item,
    required this.action,
    required this.originalIndex,
  });
}

class PhotoItem {
  final String id;
  final String title;
  final DateTime createDateTime;
  final int width;
  final int height;
  final AssetEntity? assetEntity;
  final String? mockUrl;
  int? fileSizeBytes;

  PhotoItem({
    required this.id,
    required this.title,
    required this.createDateTime,
    required this.width,
    required this.height,
    this.assetEntity,
    this.mockUrl,
    this.fileSizeBytes,
  });

  bool get isMock => assetEntity == null && mockUrl != null;

  Future<int> getOrFetchFileSize() async {
    if (fileSizeBytes != null && fileSizeBytes! > 0) return fileSizeBytes!;
    try {
      final file = await assetEntity?.file;
      if (file != null) {
        fileSizeBytes = await file.length();
        return fileSizeBytes!;
      }
    } catch (_) {}
    return 0;
  }

  String get formattedFileSize {
    if (fileSizeBytes == null || fileSizeBytes == 0) return 'Unknown size';
    final kb = fileSizeBytes! / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  String get formattedDimensions {
    if (width <= 0 || height <= 0) return '';
    return '${width}x$height';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhotoItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
