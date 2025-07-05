import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallpaper.dart';
import '../services/firestore_service.dart';
import '../services/cache_service.dart';

class FirestoreWallpapersNotifier extends StateNotifier<AsyncValue<List<Wallpaper>>> {
  final FirestoreService _service;
  final CacheService _cacheService;
  
  FirestoreWallpapersNotifier(this._service, this._cacheService) : super(const AsyncValue.loading());

  Future<void> loadWallpapers() async {
    print('=== FirestoreWallpapersNotifier.loadWallpapers Debug ===');
    state = const AsyncValue.loading();
    try {
      // First, try to load from cache
      final cachedWallpapers = _cacheService.getCachedWallpapers();
      print('Cached wallpapers count: ${cachedWallpapers.length}');
      if (cachedWallpapers.isNotEmpty && !_cacheService.isCacheStale()) {
        print('Using cached wallpapers');
        state = AsyncValue.data(cachedWallpapers);
        return;
      }
      
      // Then load from Firestore
      print('Loading from Firestore...');
      final wallpapers = await _service.getWallpapers();
      print('Firestore returned ${wallpapers.length} wallpapers');
      
      // Cache the wallpapers
      await _cacheService.cacheWallpapers(wallpapers);
      print('Cached ${wallpapers.length} wallpapers');
      
      state = AsyncValue.data(wallpapers);
      print('State updated with ${wallpapers.length} wallpapers');
    } catch (error, stackTrace) {
      print('Error in loadWallpapers: $error');
      // If Firestore fails, try to load from cache
      final cachedWallpapers = _cacheService.getCachedWallpapers();
      if (cachedWallpapers.isNotEmpty) {
        print('Using cached wallpapers due to error');
        state = AsyncValue.data(cachedWallpapers);
      } else {
        print('No cached wallpapers available, setting error state');
        state = AsyncValue.error(error, stackTrace);
      }
    }
    print('==================================================');
  }

  Future<void> refresh() async {
    // Always fetch from Firestore and update cache, ignore current cache
    state = const AsyncValue.loading();
    try {
      final wallpapers = await _service.getWallpapers();
      await _cacheService.cacheWallpapers(wallpapers);
      state = AsyncValue.data(wallpapers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadWallpapersByCategory(String category) async {
    state = const AsyncValue.loading();
    try {
      final wallpapers = await _service.getWallpapersByCategory(category);
      state = AsyncValue.data(wallpapers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchWallpapers(String query) async {
    state = const AsyncValue.loading();
    try {
      final wallpapers = await _service.searchWallpapers(query);
      state = AsyncValue.data(wallpapers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadFeaturedWallpapers() async {
    state = const AsyncValue.loading();
    try {
      final wallpapers = await _service.getFeaturedWallpapers();
      state = AsyncValue.data(wallpapers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadTrendingWallpapers() async {
    state = const AsyncValue.loading();
    try {
      final wallpapers = await _service.getTrendingWallpapers();
      state = AsyncValue.data(wallpapers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final firestoreWallpapersProvider = StateNotifierProvider<FirestoreWallpapersNotifier, AsyncValue<List<Wallpaper>>>((ref) {
  return FirestoreWallpapersNotifier(FirestoreService(), CacheService());
});

// Categories provider
class FirestoreCategoriesNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final FirestoreService _service;
  final CacheService _cacheService;
  
  FirestoreCategoriesNotifier(this._service, this._cacheService) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      // First, try to load from cache
      final cachedCategories = _cacheService.getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        state = AsyncValue.data(cachedCategories);
      }
      
      // Then load from Firestore
      final categories = await _service.getCategories();
      
      // Cache the categories
      await _cacheService.cacheCategories(categories);
      
      state = AsyncValue.data(categories);
    } catch (error, stackTrace) {
      // If Firestore fails, try to load from cache
      final cachedCategories = _cacheService.getCachedCategories();
      if (cachedCategories.isNotEmpty) {
        state = AsyncValue.data(cachedCategories);
      } else {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  Future<void> refresh() async {
    await loadCategories();
  }
}

final firestoreCategoriesProvider = StateNotifierProvider<FirestoreCategoriesNotifier, AsyncValue<List<Category>>>((ref) {
  return FirestoreCategoriesNotifier(FirestoreService(), CacheService());
});

final firestoreCategoryWallpapersProvider = StateNotifierProvider.family<FirestoreWallpapersNotifier, AsyncValue<List<Wallpaper>>, String>((ref, categoryName) {
  return FirestoreWallpapersNotifier(FirestoreService(), CacheService())..loadWallpapersByCategory(categoryName);
}); 