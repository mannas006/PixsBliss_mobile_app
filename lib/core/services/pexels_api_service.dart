import 'package:dio/dio.dart';
import '../models/wallpaper.dart';

class PexelsApiService {
  static const String _baseUrl = 'https://api.pexels.com/v1';
  static const String _apiKey = '7eCMnL27XrgUusdRHhmy4F4c1VP2FlkYguvx00XAnIYthUodo2xoiKyX';
  
  final Dio _dio;

  PexelsApiService() : _dio = Dio() {
    _dio.options.headers['Authorization'] = _apiKey;
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    
    // Add interceptor for debugging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🌐 Making request to: ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response received: ${response.statusCode}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ Network error: ${error.message}');
          print('❌ Error type: ${error.type}');
          handler.next(error);
        },
      ),
    );
  }

  /// Get curated wallpapers
  Future<List<Wallpaper>> getCuratedWallpapers({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      print('🔄 Fetching curated wallpapers - Page: $page, PerPage: $perPage');
      
      final response = await _dio.get(
        '/curated',
        queryParameters: {
          'page': page,
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final photos = data['photos'] as List;
        print('✅ Successfully fetched ${photos.length} wallpapers');
        return photos.map((photo) => _mapPexelsPhotoToWallpaper(photo)).toList();
      }
      throw Exception('Failed to load curated wallpapers: Status ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Dio error: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout - please check your internet connection');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Receive timeout - server took too long to respond');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error - failed to connect to Pexels API');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ General error: $e');
      throw Exception('Error fetching curated wallpapers: $e');
    }
  }

  /// Search wallpapers by query
  Future<List<Wallpaper>> searchWallpapers({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      print('🔍 Searching wallpapers: "$query" - Page: $page');
      
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'query': query,
          'page': page,
          'per_page': perPage,
          'orientation': 'portrait', // Better for mobile wallpapers
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final photos = data['photos'] as List;
        print('✅ Found ${photos.length} wallpapers for "$query"');
        return photos.map((photo) => _mapPexelsPhotoToWallpaper(photo)).toList();
      }
      throw Exception('Failed to search wallpapers: Status ${response.statusCode}');
    } on DioException catch (e) {
      print('❌ Search Dio error: ${e.type} - ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout - please check your internet connection');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Connection error - failed to connect to Pexels API');
      }
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('❌ Search error: $e');
      throw Exception('Error searching wallpapers: $e');
    }
  }

  /// Get wallpapers by category (using predefined search terms)
  Future<List<Wallpaper>> getWallpapersByCategory({
    required String category,
    int page = 1,
    int perPage = 20,
  }) async {
    // Map categories to search terms that work well with Pexels
    final searchTerms = {
      'nature': 'nature landscape',
      'abstract': 'abstract art',
      'animals': 'animals wildlife',
      'architecture': 'architecture building',
      'cars': 'cars automotive',
      'city': 'city urban',
      'dark': 'dark moody',
      'flowers': 'flowers botanical',
      'food': 'food photography',
      'love': 'love romantic',
      'macro': 'macro close up',
      'minimal': 'minimal simple',
      'mountains': 'mountains landscape',
      'ocean': 'ocean sea water',
      'people': 'people portrait',
      'space': 'space galaxy stars',
      'sports': 'sports action',
      'technology': 'technology digital',
      'travel': 'travel destination',
      'vintage': 'vintage retro',
    };

    final searchTerm = searchTerms[category.toLowerCase()] ?? category;
    return searchWallpapers(query: searchTerm, page: page, perPage: perPage);
  }

  /// Get popular/trending wallpapers (using popular search terms)
  Future<List<Wallpaper>> getPopularWallpapers({
    int page = 1,
    int perPage = 20,
  }) async {
    final popularTerms = [
      'wallpaper',
      'background',
      'aesthetic',
      'beautiful',
      'stunning',
    ];
    
    // Rotate through popular terms based on page
    final term = popularTerms[page % popularTerms.length];
    return searchWallpapers(query: term, page: page, perPage: perPage);
  }

  /// Convert Pexels photo data to Wallpaper model
  Wallpaper _mapPexelsPhotoToWallpaper(Map<String, dynamic> photo) {
    final src = photo['src'] as Map<String, dynamic>;
    final width = photo['width']?.toInt() ?? 1080;
    final height = photo['height']?.toInt() ?? 1920;
    
    return Wallpaper(
      id: photo['id'].toString(),
      title: photo['alt'] ?? 'Beautiful Wallpaper',
      description: photo['alt'],
      imageUrl: src['large2x'] ?? src['large'] ?? src['medium'] ?? src['original'],
      thumbnailUrl: src['medium'] ?? src['small'],
      originalUrl: src['original'] ?? src['large2x'],
      dimensions: Dimensions(width: width, height: height),
      fileSize: 0, // Pexels doesn't provide file size
      format: 'jpg',
      colors: ['#000000'], // Default color, could extract from image
      featured: false,
      trending: false,
      downloads: 0, // Not available from Pexels
      likes: 0, // Not available from Pexels
      views: 0, // Not available from Pexels
      status: 'active',
      tags: _extractTagsFromAlt(photo['alt'] ?? ''),
      category: Category(
        id: 'pexels',
        name: 'Pexels',
        slug: 'pexels',
        color: '#05A081',
        featured: true,
        order: 1,
        status: 'active',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Extract tags from alt text
  List<String> _extractTagsFromAlt(String alt) {
    if (alt.isEmpty) return ['wallpaper'];
    
    // Simple tag extraction from alt text
    final words = alt.toLowerCase().split(RegExp(r'[,\s]+'));
    final commonWords = {'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by'};
    
    return words
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .take(5)
        .toList();
  }

  /// Get available categories
  List<Category> getCategories() {
    return [
      Category(
        id: 'nature',
        name: 'Nature',
        slug: 'nature',
        color: '#4CAF50',
        featured: true,
        order: 1,
        status: 'active',
      ),
      Category(
        id: 'abstract',
        name: 'Abstract',
        slug: 'abstract',
        color: '#9C27B0',
        featured: true,
        order: 2,
        status: 'active',
      ),
      Category(
        id: 'animals',
        name: 'Animals',
        slug: 'animals',
        color: '#FF9800',
        featured: true,
        order: 3,
        status: 'active',
      ),
      Category(
        id: 'cars',
        name: 'Cars',
        slug: 'cars',
        color: '#F44336',
        featured: true,
        order: 5,
        status: 'active',
      ),
      Category(
        id: 'city',
        name: 'City',
        slug: 'city',
        color: '#2196F3',
        featured: true,
        order: 6,
        status: 'active',
      ),
      Category(
        id: 'dark',
        name: 'Dark',
        slug: 'dark',
        color: '#424242',
        featured: true,
        order: 7,
        status: 'active',
      ),
      Category(
        id: 'flowers',
        name: 'Flowers',
        slug: 'flowers',
        color: '#E91E63',
        featured: true,
        order: 8,
        status: 'active',
      ),
      Category(
        id: 'space',
        name: 'Space',
        slug: 'space',
        color: '#3F51B5',
        featured: true,
        order: 10,
        status: 'active',
      ),
    ];
  }

  /// Fetch a daily image URL for a category using the current date as a seed
  Future<String?> fetchDailyCategoryImageUrl({
    required String category,
    required DateTime date,
    int perPage = 15,
  }) async {
    try {
      final results = await searchWallpapers(
        query: category,
        page: 1,
        perPage: perPage,
      );
      if (results.isEmpty) return null;
      // Use the date as a seed to pick a different image each day
      final index = date.day % results.length;
      return results[index].imageUrl;
    } catch (e) {
      print('Error fetching daily category image: $e');
      return null;
    }
  }
}
