import 'package:hive_flutter/hive_flutter.dart';
import '../models/wallpaper.dart';
import 'dart:convert';

class CacheService {
  static const String _wallpapersBoxName = 'wallpapers';
  static const String _categoriesBoxName = 'categories';
  static const String _lastUpdateKey = 'last_update';
  static const String _pexelsWallpapersBoxName = 'pexels_wallpapers';
  static const String _pexelsTrendingWallpapersBoxName = 'pexels_trending_wallpapers';
  
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Box<String>? _wallpapersBox;
  Box<String>? _categoriesBox;
  Box<String>? _pexelsWallpapersBox;
  Box<String>? _pexelsTrendingWallpapersBox;

  Future<void> init() async {
    await Hive.initFlutter();
    
    _wallpapersBox = await Hive.openBox<String>(_wallpapersBoxName);
    _categoriesBox = await Hive.openBox<String>(_categoriesBoxName);
    _pexelsWallpapersBox = await Hive.openBox<String>(_pexelsWallpapersBoxName);
    _pexelsTrendingWallpapersBox = await Hive.openBox<String>(_pexelsTrendingWallpapersBoxName);
  }

  /// Cache wallpapers
  Future<void> cacheWallpapers(List<Wallpaper> wallpapers) async {
    try {
      if (_wallpapersBox == null) return;
      
      await _wallpapersBox!.clear();
      
      for (final wallpaper in wallpapers) {
        await _wallpapersBox!.put(wallpaper.id, jsonEncode(wallpaper.toJson()));
      }
      
      await _wallpapersBox!.put(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching wallpapers: $e');
    }
  }

  /// Get cached wallpapers
  List<Wallpaper> getCachedWallpapers() {
    try {
      if (_wallpapersBox == null) return [];
      
      final wallpapers = <Wallpaper>[];
      
      for (final key in _wallpapersBox!.keys) {
        if (key != _lastUpdateKey) {
          final wallpaperJson = _wallpapersBox!.get(key);
          if (wallpaperJson != null) {
            final wallpaperData = jsonDecode(wallpaperJson) as Map<String, dynamic>;
            wallpapers.add(Wallpaper.fromJson(wallpaperData));
          }
        }
      }
      
      return wallpapers;
    } catch (e) {
      print('Error getting cached wallpapers: $e');
      return [];
    }
  }

  /// Cache categories
  Future<void> cacheCategories(List<Category> categories) async {
    try {
      if (_categoriesBox == null) return;
      
      await _categoriesBox!.clear();
      
      for (final category in categories) {
        await _categoriesBox!.put(category.id, jsonEncode(category.toJson()));
      }
    } catch (e) {
      print('Error caching categories: $e');
    }
  }

  /// Get cached categories
  List<Category> getCachedCategories() {
    try {
      if (_categoriesBox == null) return [];
      
      final categories = <Category>[];
      
      for (final key in _categoriesBox!.keys) {
        final categoryJson = _categoriesBox!.get(key);
        if (categoryJson != null) {
          final categoryData = jsonDecode(categoryJson) as Map<String, dynamic>;
          categories.add(Category.fromJson(categoryData));
        }
      }
      
      return categories;
    } catch (e) {
      print('Error getting cached categories: $e');
      return [];
    }
  }

  /// Check if cache is stale (older than 1 hour)
  bool isCacheStale() {
    try {
      if (_wallpapersBox == null) return true;
      
      final lastUpdate = _wallpapersBox!.get(_lastUpdateKey);
      if (lastUpdate == null) return true;
      
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);
      
      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      if (_wallpapersBox != null) await _wallpapersBox!.clear();
      if (_categoriesBox != null) await _categoriesBox!.clear();
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Check if cache has data
  bool hasCachedData() {
    if (_wallpapersBox == null) return false;
    return _wallpapersBox!.length > 1; // More than just the last_update key
  }

  /// Cache Pexels wallpapers
  Future<void> cachePexelsWallpapers(List<Wallpaper> wallpapers) async {
    try {
      if (_pexelsWallpapersBox == null) return;
      await _pexelsWallpapersBox!.clear();
      for (final wallpaper in wallpapers) {
        await _pexelsWallpapersBox!.put(wallpaper.id, jsonEncode(wallpaper.toJson()));
      }
      await _pexelsWallpapersBox!.put(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching Pexels wallpapers: $e');
    }
  }

  /// Get cached Pexels wallpapers
  List<Wallpaper> getCachedPexelsWallpapers() {
    try {
      if (_pexelsWallpapersBox == null) return [];
      final wallpapers = <Wallpaper>[];
      for (final key in _pexelsWallpapersBox!.keys) {
        if (key != _lastUpdateKey) {
          final wallpaperJson = _pexelsWallpapersBox!.get(key);
          if (wallpaperJson != null) {
            final wallpaperData = jsonDecode(wallpaperJson) as Map<String, dynamic>;
            wallpapers.add(Wallpaper.fromJson(wallpaperData));
          }
        }
      }
      return wallpapers;
    } catch (e) {
      print('Error getting cached Pexels wallpapers: $e');
      return [];
    }
  }

  /// Check if Pexels cache is stale (older than 1 hour)
  bool isPexelsCacheStale() {
    try {
      if (_pexelsWallpapersBox == null) return true;
      final lastUpdate = _pexelsWallpapersBox!.get(_lastUpdateKey);
      if (lastUpdate == null) return true;
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);
      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }

  /// Clear Pexels cache
  Future<void> clearPexelsCache() async {
    try {
      if (_pexelsWallpapersBox != null) await _pexelsWallpapersBox!.clear();
    } catch (e) {
      print('Error clearing Pexels cache: $e');
    }
  }

  /// Check if Pexels cache has data
  bool hasCachedPexelsData() {
    if (_pexelsWallpapersBox == null) return false;
    return _pexelsWallpapersBox!.length > 1; // More than just the last_update key
  }

  /// Cache Pexels trending wallpapers
  Future<void> cachePexelsTrendingWallpapers(List<Wallpaper> wallpapers) async {
    try {
      if (_pexelsTrendingWallpapersBox == null) return;
      await _pexelsTrendingWallpapersBox!.clear();
      for (final wallpaper in wallpapers) {
        await _pexelsTrendingWallpapersBox!.put(wallpaper.id, jsonEncode(wallpaper.toJson()));
      }
      await _pexelsTrendingWallpapersBox!.put(_lastUpdateKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching Pexels trending wallpapers: $e');
    }
  }

  /// Get cached Pexels trending wallpapers
  List<Wallpaper> getCachedPexelsTrendingWallpapers() {
    try {
      if (_pexelsTrendingWallpapersBox == null) return [];
      final wallpapers = <Wallpaper>[];
      for (final key in _pexelsTrendingWallpapersBox!.keys) {
        if (key != _lastUpdateKey) {
          final wallpaperJson = _pexelsTrendingWallpapersBox!.get(key);
          if (wallpaperJson != null) {
            final wallpaperData = jsonDecode(wallpaperJson) as Map<String, dynamic>;
            wallpapers.add(Wallpaper.fromJson(wallpaperData));
          }
        }
      }
      return wallpapers;
    } catch (e) {
      print('Error getting cached Pexels trending wallpapers: $e');
      return [];
    }
  }

  /// Check if Pexels trending cache is stale (older than 1 hour)
  bool isPexelsTrendingCacheStale() {
    try {
      if (_pexelsTrendingWallpapersBox == null) return true;
      final lastUpdate = _pexelsTrendingWallpapersBox!.get(_lastUpdateKey);
      if (lastUpdate == null) return true;
      final lastUpdateTime = DateTime.parse(lastUpdate);
      final now = DateTime.now();
      final difference = now.difference(lastUpdateTime);
      return difference.inHours >= 1;
    } catch (e) {
      return true;
    }
  }

  /// Clear Pexels trending cache
  Future<void> clearPexelsTrendingCache() async {
    try {
      if (_pexelsTrendingWallpapersBox != null) await _pexelsTrendingWallpapersBox!.clear();
    } catch (e) {
      print('Error clearing Pexels trending cache: $e');
    }
  }

  /// Check if Pexels trending cache has data
  bool hasCachedPexelsTrendingData() {
    if (_pexelsTrendingWallpapersBox == null) return false;
    return _pexelsTrendingWallpapersBox!.length > 1; // More than just the last_update key
  }
} 