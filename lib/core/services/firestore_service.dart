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
          .limit(10)
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
} 