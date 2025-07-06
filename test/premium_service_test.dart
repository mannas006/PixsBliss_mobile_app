import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallmuse/core/services/premium_service.dart';

void main() {
  group('PremiumService Tests', () {
    late PremiumService premiumService;

    setUpAll(() async {
      premiumService = PremiumService();
      await premiumService.init();
    });

    test('should check if wallpaper is unlocked', () async {
      const testWallpaperId = 'test_wallpaper_123';
      
      // Initially should be false
      final isUnlocked = await premiumService.isWallpaperUnlocked(testWallpaperId);
      expect(isUnlocked, false);
    });

    test('should manually unlock wallpaper', () async {
      const testWallpaperId = 'test_wallpaper_456';
      
      // Manually unlock
      await premiumService.manuallyUnlockWallpaper(testWallpaperId);
      
      // Check if unlocked
      final isUnlocked = await premiumService.isWallpaperUnlocked(testWallpaperId);
      expect(isUnlocked, true);
    });

    test('should get unlocked wallpapers list', () async {
      const testWallpaperId1 = 'test_wallpaper_789';
      const testWallpaperId2 = 'test_wallpaper_101';
      
      // Unlock two wallpapers
      await premiumService.manuallyUnlockWallpaper(testWallpaperId1);
      await premiumService.manuallyUnlockWallpaper(testWallpaperId2);
      
      // Get list
      final unlockedWallpapers = await premiumService.getUnlockedWallpapers();
      expect(unlockedWallpapers, contains(testWallpaperId1));
      expect(unlockedWallpapers, contains(testWallpaperId2));
    });

    test('should clear unlock status', () async {
      const testWallpaperId = 'test_wallpaper_clear';
      
      // Unlock then clear
      await premiumService.manuallyUnlockWallpaper(testWallpaperId);
      await premiumService.clearUnlockStatus(testWallpaperId);
      
      // Should be locked again
      final isUnlocked = await premiumService.isWallpaperUnlocked(testWallpaperId);
      expect(isUnlocked, false);
    });

    test('should clear all unlock statuses', () async {
      const testWallpaperId1 = 'test_wallpaper_all_1';
      const testWallpaperId2 = 'test_wallpaper_all_2';
      
      // Unlock multiple wallpapers
      await premiumService.manuallyUnlockWallpaper(testWallpaperId1);
      await premiumService.manuallyUnlockWallpaper(testWallpaperId2);
      
      // Clear all
      await premiumService.clearAllUnlockStatuses();
      
      // All should be locked
      final isUnlocked1 = await premiumService.isWallpaperUnlocked(testWallpaperId1);
      final isUnlocked2 = await premiumService.isWallpaperUnlocked(testWallpaperId2);
      expect(isUnlocked1, false);
      expect(isUnlocked2, false);
    });
  });
} 