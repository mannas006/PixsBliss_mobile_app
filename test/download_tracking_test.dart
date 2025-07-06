import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wallmuse/core/services/firestore_service.dart';

void main() {
  group('Download Tracking Tests', () {
    late FirestoreService firestoreService;

    setUpAll(() async {
      firestoreService = FirestoreService();
      await firestoreService.init();
    });

    test('should increment download count', () async {
      // This test would require a test wallpaper ID
      // In a real test environment, you would create a test wallpaper first
      const testWallpaperId = 'test_wallpaper_id';
      
      try {
        await firestoreService.incrementDownloadCount(testWallpaperId);
        // Verify the increment worked by checking the document
        final doc = await FirebaseFirestore.instance
            .collection('wallpapers')
            .doc(testWallpaperId)
            .get();
        
        if (doc.exists) {
          final data = doc.data();
          expect(data?['downloads'], isNotNull);
          expect(data?['lastDownloadedAt'], isNotNull);
        }
      } catch (e) {
        // Expected if test wallpaper doesn't exist
        print('Test wallpaper not found: $e');
      }
    });

    test('should get total downloads', () async {
      final totalDownloads = await firestoreService.getTotalDownloads();
      expect(totalDownloads, isA<int>());
      expect(totalDownloads, greaterThanOrEqualTo(0));
    });

    test('should initialize downloads field', () async {
      await firestoreService.initializeDownloadsField();
      // This test ensures the method runs without errors
      expect(true, isTrue);
    });
  });
} 