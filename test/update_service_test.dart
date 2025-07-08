import 'package:flutter_test/flutter_test.dart';
import 'package:pixsbliss/core/services/update_service.dart';

void main() {
  group('UpdateService Tests', () {
    test('should parse update info from JSON', () {
      final json = {
        'version': '1.0.5',
        'apk_url': 'https://example.com/app.apk',
        'changelog': 'Test changelog',
      };

      final updateInfo = UpdateInfo.fromJson(json);

      expect(updateInfo.version, '1.0.5');
      expect(updateInfo.apkUrl, 'https://example.com/app.apk');
      expect(updateInfo.changelog, 'Test changelog');
    });

    test('should compare versions correctly', () {
      final updateService = UpdateService();

      // Test version comparison
      expect(updateService.isNewerVersion('1.0.5', '1.0.4'), true);
      expect(updateService.isNewerVersion('1.0.5', '1.0.5'), false);
      expect(updateService.isNewerVersion('1.0.4', '1.0.5'), false);
      expect(updateService.isNewerVersion('2.0.0', '1.9.9'), true);
      expect(updateService.isNewerVersion('1.0.10', '1.0.9'), true);
    });

    test('should format file size correctly', () {
      final updateService = UpdateService();

      expect(updateService.formatFileSize(0), '0 B');
      expect(updateService.formatFileSize(1024), '1.0 KB');
      expect(updateService.formatFileSize(1048576), '1.0 MB');
      expect(updateService.formatFileSize(1073741824), '1.0 GB');
    });

    test('should calculate progress percentage correctly', () {
      final updateService = UpdateService();

      expect(updateService.getProgressPercentage(50, 100), 50.0);
      expect(updateService.getProgressPercentage(0, 100), 0.0);
      expect(updateService.getProgressPercentage(100, 100), 100.0);
      expect(updateService.getProgressPercentage(25, 50), 50.0);
    });
  });
} 