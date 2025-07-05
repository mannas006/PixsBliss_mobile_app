import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/wallpaper.dart';
import '../network/api_client.dart';

// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return apiClient;
});

// Wallpaper repository provider
final wallpaperRepositoryProvider = Provider<WallpaperRepository>((ref) {
  return WallpaperRepository(ref.read(apiClientProvider));
});

// Wallpapers state provider
final wallpapersProvider = StateNotifierProvider<WallpapersNotifier, WallpapersState>((ref) {
  return WallpapersNotifier(ref.read(wallpaperRepositoryProvider));
});

// Categories provider
final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier(ref.read(wallpaperRepositoryProvider));
});

// Favorites provider
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(wallpaperRepositoryProvider));
});

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});

// Wallpapers State
class WallpapersState {
  final List<Wallpaper> wallpapers;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int currentPage;

  const WallpapersState({
    this.wallpapers = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.error,
    this.currentPage = 1,
  });

  WallpapersState copyWith({
    List<Wallpaper>? wallpapers,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? currentPage,
  }) {
    return WallpapersState(
      wallpapers: wallpapers ?? this.wallpapers,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Categories State
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  const CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Search State
class SearchState {
  final List<Wallpaper> results;
  final bool isLoading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<Wallpaper>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return SearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      query: query ?? this.query,
    );
  }
}

// Category model
class Category {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final int wallpaperCount;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    required this.wallpaperCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      wallpaperCount: json['wallpaperCount'] ?? 0,
    );
  }
}

// Wallpapers Notifier
class WallpapersNotifier extends StateNotifier<WallpapersState> {
  final WallpaperRepository _repository;

  WallpapersNotifier(this._repository) : super(const WallpapersState());

  Future<void> loadWallpapers({bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        wallpapers: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      );
    }

    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getWallpapers(
        page: refresh ? 1 : state.currentPage,
        limit: 20,
      );

      final newWallpapers = response['wallpapers'] as List<Wallpaper>;
      final hasMore = response['hasMore'] as bool;

      state = state.copyWith(
        wallpapers: refresh 
          ? newWallpapers 
          : [...state.wallpapers, ...newWallpapers],
        isLoading: false,
        hasMore: hasMore,
        currentPage: refresh ? 2 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadWallpapersByCategory(String categoryId, {bool refresh = false}) async {
    if (state.isLoading) return;

    if (refresh) {
      state = state.copyWith(
        wallpapers: [],
        currentPage: 1,
        hasMore: true,
        error: null,
      );
    }

    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _repository.getWallpapersByCategory(
        categoryId,
        page: refresh ? 1 : state.currentPage,
        limit: 20,
      );

      final newWallpapers = response['wallpapers'] as List<Wallpaper>;
      final hasMore = response['hasMore'] as bool;

      state = state.copyWith(
        wallpapers: refresh 
          ? newWallpapers 
          : [...state.wallpapers, ...newWallpapers],
        isLoading: false,
        hasMore: hasMore,
        currentPage: refresh ? 2 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// Categories Notifier
class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final WallpaperRepository _repository;

  CategoriesNotifier(this._repository) : super(const CategoriesState());

  Future<void> loadCategories() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final categories = await _repository.getCategories();
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

// Favorites Notifier
class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(<String>{});

  void toggleFavorite(String wallpaperId) {
    if (state.contains(wallpaperId)) {
      state = Set.from(state)..remove(wallpaperId);
    } else {
      state = Set.from(state)..add(wallpaperId);
    }
  }

  bool isFavorite(String wallpaperId) {
    return state.contains(wallpaperId);
  }
}

// Search Notifier
class SearchNotifier extends StateNotifier<SearchState> {
  final WallpaperRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null, query: query);

    try {
      final results = await _repository.searchWallpapers(query);
      state = state.copyWith(
        results: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearSearch() {
    state = const SearchState();
  }
}

// Theme Notifier
class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(true); // Default to dark theme

  void toggleTheme() {
    state = !state;
  }

  void setTheme(bool isDark) {
    state = isDark;
  }
}

// Wallpaper Repository
class WallpaperRepository {
  final ApiClient _apiClient;

  WallpaperRepository(this._apiClient);

  Future<Map<String, dynamic>> getWallpapers({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallpapers',
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'];
      final wallpapers = (data['wallpapers'] as List)
          .map((json) => Wallpaper.fromJson(json))
          .toList();

      return {
        'wallpapers': wallpapers,
        'hasMore': data['hasMore'] ?? false,
        'total': data['total'] ?? 0,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getWallpapersByCategory(
    String categoryId, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '/wallpapers',
        queryParameters: {
          'category': categoryId,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data['data'];
      final wallpapers = (data['wallpapers'] as List)
          .map((json) => Wallpaper.fromJson(json))
          .toList();

      return {
        'wallpapers': wallpapers,
        'hasMore': data['hasMore'] ?? false,
        'total': data['total'] ?? 0,
      };
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.get('/categories');
      final data = response.data['data'] as List;
      return data.map((json) => Category.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Wallpaper>> searchWallpapers(String query) async {
    try {
      final response = await _apiClient.get(
        '/wallpapers/search',
        queryParameters: {'q': query},
      );

      final data = response.data['data'] as List;
      return data.map((json) => Wallpaper.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> downloadWallpaper(String wallpaperId) async {
    try {
      await _apiClient.post('/wallpapers/$wallpaperId/download');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> likeWallpaper(String wallpaperId) async {
    try {
      await _apiClient.post('/wallpapers/$wallpaperId/like');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 404) {
          return 'Resource not found.';
        } else if (e.response?.statusCode == 500) {
          return 'Server error. Please try again later.';
        }
        return e.response?.data['message'] ?? 'Something went wrong.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        return 'No internet connection.';
      default:
        return 'Something went wrong.';
    }
  }
}
