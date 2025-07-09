import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../models/wallpaper.dart';
import 'dart:developer';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late FirebaseFirestore _firestore;

  Future<void> init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firestore = FirebaseFirestore.instance;
  }

  /// Get all wallpapers from Firestore
  Future<List<Wallpaper>> getWallpapers() async {
    try {
      print('=== FirestoreService.getWallpapers Debug ===');
      print('Fetching wallpapers from Firestore...');
      
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .orderBy('createdAt', descending: true)
          .get();

      print('Query snapshot size: ${querySnapshot.docs.length}');
      
      final wallpapers = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Add document ID
        
        print('Document ID: ${doc.id}');
        print('Document data: $data');
        
        final wallpaper = Wallpaper.fromFirestore(data);
        print('Created wallpaper: ${wallpaper.title}');
        print('Wallpaper imageUrl: ${wallpaper.imageUrl}');
        print('Wallpaper thumbnailUrl: ${wallpaper.thumbnailUrl}');
        
        return wallpaper;
      }).toList();
      
      print('Total wallpapers created: ${wallpapers.length}');
      print('==========================================');
      
      return wallpapers;
    } catch (e) {
      print('Error fetching wallpapers from Firestore: $e');
      log('Error fetching wallpapers from Firestore: $e');
      return [];
    }
  }

  /// Get wallpapers by category
  Future<List<Wallpaper>> getWallpapersByCategory(String category, {int limit = 0}) async {
    print('Querying Firestore for wallpapers with category: ' + category);
    try {
      var query = _firestore
          .collection('wallpapers')
          .where('categories', arrayContains: category);
      if (limit > 0) {
        query = query.limit(limit);
      }
      final querySnapshot = await query.get();
      print('Found ' + querySnapshot.docs.length.toString() + ' wallpapers for category: ' + category);
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Add document ID
        return Wallpaper.fromFirestore(data);
      }).toList();
    } catch (e) {
      log('Error fetching wallpapers by category from Firestore: $e');
      return [];
    }
  }

  /// Get categories from Firestore
  Future<List<Category>> getCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .orderBy('order', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Add document ID
        return Category.fromFirestore(data);
      }).toList();
    } catch (e) {
      log('Error fetching categories from Firestore: $e');
      return [];
    }
  }

  /// Search wallpapers by tags
  Future<List<Wallpaper>> searchWallpapers(String query) async {
    try {
      // Firestore doesn't support full-text search, so we'll search in tags
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .where('tags', arrayContains: query.toLowerCase())
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Add document ID
        return Wallpaper.fromFirestore(data);
      }).toList();
    } catch (e) {
      log('Error searching wallpapers in Firestore: $e');
      return [];
    }
  }

  /// Get featured wallpapers
  Future<List<Wallpaper>> getFeaturedWallpapers() async {
    try {
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .where('featured', isEqualTo: true)
          .limit(10)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Add document ID
        return Wallpaper.fromFirestore(data);
      }).toList();
    } catch (e) {
      log('Error fetching featured wallpapers from Firestore: $e');
      return [];
    }
  }

  /// Get trending wallpapers
  Future<List<Wallpaper>> getTrendingWallpapers() async {
    try {
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .where('trending', isEqualTo: true)
          // .orderBy('createdAt', descending: true) // Removed ordering to support missing createdAt
          .limit(20)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['_id'] = doc.id; // Add document ID
        return Wallpaper.fromFirestore(data);
      }).toList();
    } catch (e) {
      log('Error fetching trending wallpapers from Firestore: $e');
      return [];
    }
  }

  /// Increment download count for a wallpaper
  Future<void> incrementDownloadCount(String wallpaperId) async {
    try {
      final wallpaperRef = _firestore.collection('wallpapers').doc(wallpaperId);
      
      // Use FieldValue.increment to atomically increment the downloads count
      await wallpaperRef.update({
        'downloads': FieldValue.increment(1),
        'lastDownloadedAt': FieldValue.serverTimestamp(),
      });
      
      print('Successfully incremented download count for wallpaper: $wallpaperId');
    } catch (e) {
      print('Error incrementing download count: $e');
      log('Error incrementing download count for wallpaper $wallpaperId: $e');
      throw e;
    }
  }

  /// Get total downloads across all wallpapers
  Future<int> getTotalDownloads() async {
    try {
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .get();

      int totalDownloads = 0;
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        totalDownloads += (data['downloads'] as int?) ?? 0;
      }
      
      return totalDownloads;
    } catch (e) {
      print('Error getting total downloads: $e');
      log('Error getting total downloads: $e');
      return 0;
    }
  }

  /// Initialize downloads field for wallpapers that don't have it
  Future<void> initializeDownloadsField() async {
    try {
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['downloads'] == null) {
          batch.update(doc.reference, {
            'downloads': 0,
            'lastDownloadedAt': null,
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('Initialized downloads field for $updateCount wallpapers');
      }
    } catch (e) {
      print('Error initializing downloads field: $e');
      log('Error initializing downloads field: $e');
    }
  }

  /// Increment view count for a wallpaper
  Future<void> incrementViewCount(String wallpaperId) async {
    try {
      final wallpaperRef = _firestore.collection('wallpapers').doc(wallpaperId);
      await wallpaperRef.update({
        'views': FieldValue.increment(1),
        'lastViewedAt': FieldValue.serverTimestamp(),
      });
      print('Successfully incremented view count for wallpaper: $wallpaperId');
    } catch (e) {
      print('Error incrementing view count: $e');
      log('Error incrementing view count for wallpaper $wallpaperId: $e');
      throw e;
    }
  }

  /// Initialize views field for wallpapers that don't have it
  Future<void> initializeViewsField() async {
    try {
      final querySnapshot = await _firestore
          .collection('wallpapers')
          .get();

      final batch = _firestore.batch();
      int updateCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['views'] == null) {
          batch.update(doc.reference, {
            'views': 0,
            'lastViewedAt': null,
          });
          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        print('Initialized views field for $updateCount wallpapers');
      }
    } catch (e) {
      print('Error initializing views field: $e');
      log('Error initializing views field: $e');
    }
  }

  /// Track app install in Firestore
  Future<void> trackInstall({
    required String id,
    required String platform,
    required String appVersion,
    required Timestamp timestamp,
  }) async {
    try {
      await _firestore.collection('installs').doc(id).set({
        'id': id,
        'platform': platform,
        'app_version': appVersion,
        'timestamp': timestamp,
      });
      print('Install tracked: id=$id, platform=$platform, app_version=$appVersion');
    } catch (e) {
      print('Error tracking install: $e');
      log('Error tracking install: $e');
    }
  }

  /// Send heartbeat for active user tracking
  Future<void> sendActiveUserHeartbeat({
    required String deviceId,
    required String platform,
    required String appVersion,
  }) async {
    try {
      await _firestore.collection('active_users').doc(deviceId).set({
        'deviceId': deviceId,
        'platform': platform,
        'app_version': appVersion,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Active user heartbeat sent: deviceId=$deviceId');
    } catch (e) {
      print('Error sending active user heartbeat: $e');
      log('Error sending active user heartbeat: $e');
    }
  }
} 