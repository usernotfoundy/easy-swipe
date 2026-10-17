import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../models/photo_item.dart';
import '../services/gallery_service.dart';

class GalleryState extends ChangeNotifier {
  final GalleryService _service = GalleryService.instance;

  List<PhotoItem> _photos = [];
  int _currentIndex = 0;

  final List<PhotoItem> _keptPhotos = [];
  final List<PhotoItem> _deleteQueue = [];
  final List<SwipeRecord> _history = [];

  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _currentAlbum;

  bool _isLoading = true;
  PermissionState _permissionState = PermissionState.notDetermined;
  bool _isDemoMode = false;
  String? _errorMessage;

  // Getters
  List<PhotoItem> get photos => _photos;
  int get currentIndex => _currentIndex;
  List<PhotoItem> get keptPhotos => List.unmodifiable(_keptPhotos);
  List<PhotoItem> get deleteQueue => List.unmodifiable(_deleteQueue);
  List<SwipeRecord> get history => List.unmodifiable(_history);
  List<AssetPathEntity> get albums => List.unmodifiable(_albums);
  AssetPathEntity? get currentAlbum => _currentAlbum;
  bool get isLoading => _isLoading;
  PermissionState get permissionState => _permissionState;
  bool get isDemoMode => _isDemoMode;
  String? get errorMessage => _errorMessage;

  bool get hasMorePhotos => _currentIndex < _photos.length;
  int get remainingCount => _photos.length - _currentIndex;
  int get totalCount => _photos.length;
  bool get canUndo => _history.isNotEmpty;

  PhotoItem? get currentPhoto {
    if (_currentIndex < _photos.length) {
      return _photos[_currentIndex];
    }
    return null;
  }

  PhotoItem? get nextPhoto {
    if (_currentIndex + 1 < _photos.length) {
      return _photos[_currentIndex + 1];
    }
    return null;
  }

  int get totalDeleteQueueBytes {
    int total = 0;
    for (final item in _deleteQueue) {
      total += (item.fileSizeBytes ?? 0);
    }
    return total;
  }

  String get formattedTotalDeleteQueueSize {
    final bytes = totalDeleteQueueBytes;
    if (bytes == 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Initialize and load permissions & initial photos
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _permissionState = await _service.requestPermissions();
      if (_permissionState.isAuth || _permissionState.hasAccess) {
        _isDemoMode = false;
        await _loadGalleryAlbumsAndPhotos();
      } else {
        // Fallback to sample photos if permission is not granted yet
        _loadDemoMode();
      }
    } catch (e) {
      _errorMessage = 'Failed to load photos: $e';
      _loadDemoMode();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request permissions manually (e.g. from a banner or button)
  Future<void> requestPermission() async {
    _isLoading = true;
    notifyListeners();
    try {
      _permissionState = await _service.requestPermissions();
      if (_permissionState.isAuth || _permissionState.hasAccess) {
        _isDemoMode = false;
        await _loadGalleryAlbumsAndPhotos();
      }
    } catch (e) {
      _errorMessage = 'Permission error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    await _service.openSettings();
  }

  /// Load device albums and photos
  Future<void> _loadGalleryAlbumsAndPhotos() async {
    _albums = await _service.getAlbums();
    if (_albums.isNotEmpty) {
      _currentAlbum = _albums.first;
      final loaded = await _service.getPhotos(album: _currentAlbum);
      if (loaded.isNotEmpty) {
        _photos = loaded;
        _isDemoMode = false;
      } else {
        // If device album is empty (e.g. fresh emulator), load sample photos with banner
        _loadDemoMode();
      }
    } else {
      _loadDemoMode();
    }
    _currentIndex = 0;
    _keptPhotos.clear();
    _deleteQueue.clear();
    _history.clear();
  }

  void _loadDemoMode() {
    _isDemoMode = true;
    _photos = _service.getSamplePhotos();
    _currentIndex = 0;
    _keptPhotos.clear();
    _deleteQueue.clear();
    _history.clear();
  }

  /// Toggle or switch to sample photos
  void switchToDemoMode() {
    _loadDemoMode();
    _isLoading = false;
    notifyListeners();
  }

  /// Switch album
  Future<void> selectAlbum(AssetPathEntity album) async {
    _isLoading = true;
    _currentAlbum = album;
    notifyListeners();

    try {
      _photos = await _service.getPhotos(album: album);
      _currentIndex = 0;
      _keptPhotos.clear();
      _deleteQueue.clear();
      _history.clear();
      _isDemoMode = false;
    } catch (e) {
      _errorMessage = 'Failed to load album: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh photos
  Future<void> refresh() async {
    if (_isDemoMode) {
      _loadDemoMode();
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    await _loadGalleryAlbumsAndPhotos();
    _isLoading = false;
    notifyListeners();
  }

  /// Swipe Right -> Keep
  void swipeKeep(PhotoItem item) {
    if (_currentIndex >= _photos.length) return;
    final index = _currentIndex;
    _keptPhotos.add(item);
    _history.add(SwipeRecord(
      item: item,
      action: SwipeAction.keep,
      originalIndex: index,
    ));
    _currentIndex++;
    notifyListeners();
  }

  /// Swipe Left -> Queue for deletion (Temporary hold)
  void swipeDelete(PhotoItem item) {
    if (_currentIndex >= _photos.length) return;
    final index = _currentIndex;
    _deleteQueue.add(item);
    _history.add(SwipeRecord(
      item: item,
      action: SwipeAction.delete,
      originalIndex: index,
    ));
    _currentIndex++;
    notifyListeners();

    if (item.fileSizeBytes == null) {
      item.getOrFetchFileSize().then((size) {
        if (size > 0) {
          notifyListeners();
        }
      });
    }
  }

  /// Undo the last swipe action
  void undoLastSwipe() {
    if (_history.isEmpty || _currentIndex <= 0) return;

    final lastRecord = _history.removeLast();
    if (lastRecord.action == SwipeAction.keep) {
      _keptPhotos.remove(lastRecord.item);
    } else {
      _deleteQueue.remove(lastRecord.item);
    }

    _currentIndex--;
    notifyListeners();
  }

  /// Restore a photo from the delete queue (undo deletion for individual item)
  void restoreFromDeleteQueue(PhotoItem item) {
    if (_deleteQueue.remove(item)) {
      _keptPhotos.add(item);
      // Remove or update from history if present
      _history.removeWhere((record) =>
          record.item.id == item.id && record.action == SwipeAction.delete);
      notifyListeners();
    }
  }

  /// Restore multiple photos from delete queue
  void restoreMultipleFromDeleteQueue(List<PhotoItem> items) {
    for (final item in items) {
      if (_deleteQueue.remove(item)) {
        _keptPhotos.add(item);
        _history.removeWhere((record) =>
            record.item.id == item.id && record.action == SwipeAction.delete);
      }
    }
    notifyListeners();
  }

  /// Finalize & Confirm Batch Deletion
  /// Deletes selected items permanently from device or demo list.
  Future<int> confirmBatchDelete(List<PhotoItem> itemsToDelete) async {
    if (itemsToDelete.isEmpty) return 0;

    _isLoading = true;
    notifyListeners();

    int deletedCount = 0;
    try {
      if (_isDemoMode) {
        // Mock deletion
        for (final item in itemsToDelete) {
          _deleteQueue.remove(item);
          _photos.remove(item);
          _history.removeWhere((r) => r.item.id == item.id);
        }
        deletedCount = itemsToDelete.length;
      } else {
        final idsToDelete = itemsToDelete
            .where((item) => item.assetEntity != null)
            .map((item) => item.assetEntity!.id)
            .toList();

        final resultIds = await _service.deletePhotos(idsToDelete);
        deletedCount = resultIds.length;

        // Remove confirmed deleted photos from local lists
        for (final id in resultIds) {
          _deleteQueue.removeWhere((item) => item.id == id);
          _photos.removeWhere((item) => item.id == id);
          _history.removeWhere((r) => r.item.id == id);
        }

        // Adjust currentIndex if necessary
        if (_currentIndex > _photos.length) {
          _currentIndex = _photos.length;
        }
      }
    } catch (e) {
      _errorMessage = 'Error deleting photos: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return deletedCount;
  }

  /// Restart current deck
  void restartDeck() {
    _currentIndex = 0;
    _keptPhotos.clear();
    _deleteQueue.clear();
    _history.clear();
    notifyListeners();
  }

  /// Jump to a specific starting photo index
  void jumpToIndex(int newIndex, {bool markPreviousAsKept = true}) {
    if (newIndex < 0 || newIndex >= _photos.length) return;

    if (markPreviousAsKept && newIndex > _currentIndex) {
      for (int i = 0; i < newIndex; i++) {
        final item = _photos[i];
        if (!_deleteQueue.contains(item) && !_keptPhotos.contains(item)) {
          _keptPhotos.add(item);
        }
      }
    }

    _currentIndex = newIndex;
    _history.clear();
    notifyListeners();
  }
}
