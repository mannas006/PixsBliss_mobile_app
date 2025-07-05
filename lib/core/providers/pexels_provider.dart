import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pexels_api_service.dart';
import '../models/wallpaper.dart';
import '../services/cache_service.dart';

// Pexels API service provider
final pexelsApiServiceProvider = Provider<PexelsApiService>((ref) {
  return PexelsApiService();
});

// Pexels wallpapers provider
final pexelsWallpapersProvider = StateNotifierProvider.autoDispose<PexelsWallpapersNotifier, PexelsWallpapersState>((ref) {
  return PexelsWallpapersNotifier(ref.read(pexelsApiServiceProvider));
});

// Pexels categories provider
final pexelsCategoriesProvider = StateNotifierProvider<PexelsCategoriesNotifier, PexelsCategoriesState>((ref) {
  return PexelsCategoriesNotifier(ref.read(pexelsApiServiceProvider));
});

// Pexels search provider
final pexelsSearchProvider = StateNotifierProvider<PexelsSearchNotifier, PexelsSearchState>((ref) {
  return PexelsSearchNotifier(ref.read(pexelsApiServiceProvider));
});

// Trending Wallpapers State/Notifier/Provider
class PexelsTrendingWallpapersNotifier extends StateNotifier<PexelsWallpapersState> {
  final PexelsApiService _apiService;
  final CacheService _cacheService = CacheService();
  bool _hasLoadedFromCache = false;

  PexelsTrendingWallpapersNotifier(this._apiService) : super(const PexelsWallpapersState()) {
    loadTrendingWallpapers();
  }

  Future<void> loadTrendingWallpapers({bool refresh = false}) async {
    if (state.isLoading) return;

    // On first load or refresh, try cache first
    if (!_hasLoadedFromCache && !refresh) {
      final cached = _cacheService.getCachedPexelsTrendingWallpapers();
      if (cached.isNotEmpty && !_cacheService.isPexelsTrendingCacheStale()) {
        state = state.copyWith(wallpapers: cached, isLoading: false, error: null, currentPage: 2);
        _hasLoadedFromCache = true;
        // Fetch fresh data in background
        _fetchAndUpdateTrendingWallpapers(refresh: true);
        return;
      }
    }

    // If refresh or no cache, fetch from API
    await _fetchAndUpdateTrendingWallpapers(refresh: refresh);
    _hasLoadedFromCache = true;
  }

  Future<void> _fetchAndUpdateTrendingWallpapers({bool refresh = false}) async {
    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final wallpapers = await _apiService.getPopularWallpapers(
        page: page,
        perPage: 20,
      );
      if (refresh) {
        state = state.copyWith(
          wallpapers: wallpapers,
          isLoading: false,
          currentPage: 2,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 20,
        );
        // Update cache
        await _cacheService.cachePexelsTrendingWallpapers(wallpapers);
      } else {
        final updated = [...state.wallpapers, ...wallpapers];
        state = state.copyWith(
          wallpapers: updated,
          isLoading: false,
          currentPage: state.currentPage + 1,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 20,
        );
        await _cacheService.cachePexelsTrendingWallpapers(updated);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await _cacheService.clearPexelsTrendingCache();
    _hasLoadedFromCache = false;
    await loadTrendingWallpapers(refresh: true);
  }

  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoading) {
      await loadTrendingWallpapers();
    }
  }
}

final pexelsTrendingWallpapersProvider = StateNotifierProvider<PexelsTrendingWallpapersNotifier, PexelsWallpapersState>((ref) {
  return PexelsTrendingWallpapersNotifier(ref.read(pexelsApiServiceProvider));
});

// Wallpapers State
class PexelsWallpapersState {
  final List<Wallpaper> wallpapers;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const PexelsWallpapersState({
    this.wallpapers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
  });

  PexelsWallpapersState copyWith({
    List<Wallpaper>? wallpapers,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return PexelsWallpapersState(
      wallpapers: wallpapers ?? this.wallpapers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Wallpapers Notifier
class PexelsWallpapersNotifier extends StateNotifier<PexelsWallpapersState> {
  final PexelsApiService _apiService;
  final CacheService _cacheService = CacheService();
  bool _hasLoadedFromCache = false;

  PexelsWallpapersNotifier(this._apiService) : super(const PexelsWallpapersState()) {
    loadWallpapers();
  }

  Future<void> loadWallpapers({bool refresh = false}) async {
    if (state.isLoading) return;

    // On first load or refresh, try cache first
    if (!_hasLoadedFromCache && !refresh) {
      final cached = _cacheService.getCachedPexelsWallpapers();
      if (cached.isNotEmpty && !_cacheService.isPexelsCacheStale()) {
        state = state.copyWith(wallpapers: cached, isLoading: false, error: null, currentPage: 2);
        _hasLoadedFromCache = true;
        // Fetch fresh data in background
        _fetchAndUpdateWallpapers(refresh: true);
        return;
      }
    }

    // If refresh or no cache, fetch from API
    await _fetchAndUpdateWallpapers(refresh: refresh);
    _hasLoadedFromCache = true;
  }

  Future<void> _fetchAndUpdateWallpapers({bool refresh = false}) async {
    final page = refresh ? 1 : state.currentPage;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final wallpapers = await _apiService.getCuratedWallpapers(
        page: page,
        perPage: 80,
      );
      if (refresh) {
        state = state.copyWith(
          wallpapers: wallpapers,
          isLoading: false,
          currentPage: 2,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 80,
        );
        // Update cache
        await _cacheService.cachePexelsWallpapers(wallpapers);
      } else {
        final updated = [...state.wallpapers, ...wallpapers];
        state = state.copyWith(
          wallpapers: updated,
          isLoading: false,
          currentPage: state.currentPage + 1,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 80,
        );
        await _cacheService.cachePexelsWallpapers(updated);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network connection failed. Please check your internet connection and try again.',
      );
    }
  }

  Future<void> refresh() async {
    await _cacheService.clearPexelsCache();
    _hasLoadedFromCache = false;
    await loadWallpapers(refresh: true);
  }

  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoading) {
      await loadWallpapers();
    }
  }
}

// Categories State
class PexelsCategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  const PexelsCategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  PexelsCategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return PexelsCategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Categories Notifier
class PexelsCategoriesNotifier extends StateNotifier<PexelsCategoriesState> {
  final PexelsApiService _apiService;

  PexelsCategoriesNotifier(this._apiService) : super(const PexelsCategoriesState()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = _apiService.getCategories();
      state = state.copyWith(
        categories: categories,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Search State
class PexelsSearchState {
  final List<Wallpaper> wallpapers;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final String query;
  final int currentPage;

  const PexelsSearchState({
    this.wallpapers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.query = '',
    this.currentPage = 1,
  });

  PexelsSearchState copyWith({
    List<Wallpaper>? wallpapers,
    bool? isLoading,
    bool? hasMore,
    String? error,
    String? query,
    int? currentPage,
  }) {
    return PexelsSearchState(
      wallpapers: wallpapers ?? this.wallpapers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      query: query ?? this.query,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Search Notifier
class PexelsSearchNotifier extends StateNotifier<PexelsSearchState> {
  final PexelsApiService _apiService;

  PexelsSearchNotifier(this._apiService) : super(const PexelsSearchState());

  Future<void> searchWallpapers(String query, {bool refresh = false}) async {
    if (query.isEmpty) {
      state = const PexelsSearchState();
      return;
    }

    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
      query: query,
    );

    try {
      final wallpapers = await _apiService.searchWallpapers(
        query: query,
        page: page,
        perPage: 80,
      );

      if (refresh || state.query != query) {
        state = state.copyWith(
          wallpapers: wallpapers,
          isLoading: false,
          currentPage: 2,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 80,
          query: query,
        );
      } else {
        state = state.copyWith(
          wallpapers: [...state.wallpapers, ...wallpapers],
          isLoading: false,
          currentPage: state.currentPage + 1,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 80,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoading && state.query.isNotEmpty) {
      await searchWallpapers(state.query);
    }
  }

  void clearSearch() {
    state = const PexelsSearchState();
  }
}

// Category wallpapers provider
final pexelsCategoryWallpapersProvider = StateNotifierProvider.family<PexelsCategoryWallpapersNotifier, PexelsWallpapersState, String>((ref, categoryId) {
  return PexelsCategoryWallpapersNotifier(ref.read(pexelsApiServiceProvider), categoryId);
});

// Category wallpapers notifier
class PexelsCategoryWallpapersNotifier extends StateNotifier<PexelsWallpapersState> {
  final PexelsApiService _apiService;
  final String categoryId;

  PexelsCategoryWallpapersNotifier(this._apiService, this.categoryId) : super(const PexelsWallpapersState()) {
    loadCategoryWallpapers();
  }

  Future<void> loadCategoryWallpapers({bool refresh = false}) async {
    if (state.isLoading) return;

    final page = refresh ? 1 : state.currentPage;
    
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final wallpapers = await _apiService.getWallpapersByCategory(
        category: categoryId,
        page: page,
        perPage: 80,
      );

      if (refresh) {
        state = state.copyWith(
          wallpapers: wallpapers,
          isLoading: false,
          currentPage: 2,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 80,
        );
      } else {
        state = state.copyWith(
          wallpapers: [...state.wallpapers, ...wallpapers],
          isLoading: false,
          currentPage: state.currentPage + 1,
          hasMore: wallpapers.isNotEmpty && wallpapers.length >= 80,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadCategoryWallpapers(refresh: true);
  }

  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoading) {
      await loadCategoryWallpapers();
    }
  }
}
