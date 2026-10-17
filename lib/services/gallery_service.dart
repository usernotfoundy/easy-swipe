import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_item.dart';

class GalleryService {
  static final GalleryService instance = GalleryService._internal();
  GalleryService._internal();

  /// Check current permission state
  Future<PermissionState> getPermissionState() async {
    try {
      return await PhotoManager.getPermissionState(
        requestOption: const PermissionRequestOption(),
      );
    } catch (e) {
      debugPrint('Error getting permission state: $e');
      return PermissionState.denied;
    }
  }

  /// Request permissions
  Future<PermissionState> requestPermissions() async {
    try {
      return await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(),
      );
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return PermissionState.denied;
    }
  }

  /// Open app settings
  Future<void> openSettings() async {
    await PhotoManager.openSetting();
  }

  /// Fetch all photo albums
  Future<List<AssetPathEntity>> getAlbums() async {
    try {
      return await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error getting albums: $e');
      return [];
    }
  }

  /// Fetch photos from a selected album or recent photos
  Future<List<PhotoItem>> getPhotos({
    AssetPathEntity? album,
    int? maxCount,
  }) async {
    try {
      AssetPathEntity? targetAlbum = album;
      if (targetAlbum == null) {
        final albums = await getAlbums();
        if (albums.isNotEmpty) {
          targetAlbum = albums.first;
        }
      }

      if (targetAlbum == null) {
        return [];
      }

      final int totalCount = await targetAlbum.assetCountAsync;
      if (totalCount == 0) return [];

      final int end = (maxCount != null && maxCount > 0)
          ? (maxCount < totalCount ? maxCount : totalCount)
          : totalCount;

      final List<AssetEntity> assets =
          await targetAlbum.getAssetListRange(start: 0, end: end);

      final List<PhotoItem> items = [];
      for (final asset in assets) {
        items.add(
          PhotoItem(
            id: asset.id,
            title: asset.title ??
                'Photo ${asset.id.length > 4 ? asset.id.substring(0, 4) : asset.id}',
            createDateTime: asset.createDateTime,
            width: asset.width,
            height: asset.height,
            assetEntity: asset,
          ),
        );
      }
      return items;
    } catch (e) {
      debugPrint('Error getting photos: $e');
      return [];
    }
  }

  /// Delete selected photos from the device gallery
  Future<List<String>> deletePhotos(List<String> assetIds) async {
    try {
      final List<String> result =
          await PhotoManager.editor.deleteWithIds(assetIds);
      return result;
    } catch (e) {
      debugPrint('Error deleting photos: $e');
      return [];
    }
  }

  /// High quality sample photos for demonstration or empty galleries
  List<PhotoItem> getSamplePhotos() {
    final now = DateTime.now();
    final sampleData = [
      {
        'title': 'Sunset at the Beach',
        'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 2400000,
      },
      {
        'title': 'Mountain Peak at Dawn',
        'url': 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 3100000,
      },
      {
        'title': 'City Skyline at Night',
        'url': 'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 1850000,
      },
      {
        'title': 'Forest Path in Morning Light',
        'url': 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 2750000,
      },
      {
        'title': 'Cozy Coffee & Notebook',
        'url': 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 1600000,
      },
      {
        'title': 'Autumn Golden Leaves',
        'url': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 3400000,
      },
      {
        'title': 'Architecture Minimalist Geometry',
        'url': 'https://images.unsplash.com/photo-1513694203232-719a280e022f?w=1200&q=80',
        'width': 1200,
        'height': 800,
        'size': 1400000,
      },
    ];

    return sampleData.asMap().entries.map((entry) {
      final idx = entry.key;
      final data = entry.value;
      return PhotoItem(
        id: 'sample_$idx',
        title: data['title'] as String,
        createDateTime: now.subtract(Duration(days: idx * 2, hours: idx * 3)),
        width: data['width'] as int,
        height: data['height'] as int,
        mockUrl: data['url'] as String,
        fileSizeBytes: data['size'] as int,
      );
    }).toList();
  }
}
