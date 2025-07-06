import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdateInfo {
  final String version;
  final String apkUrl;
  final String changelog;

  UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.changelog,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    String changelog = json['changelog'] ?? '';
    // Handle escaped newlines
    changelog = changelog.replaceAll('\\n', '\n');
    
    return UpdateInfo(
      version: json['version'] ?? '',
      apkUrl: json['apk_url'] ?? '',
      changelog: changelog,
    );
  }
}

class UpdateService {
  static const String _updateUrl = 'https://raw.githubusercontent.com/mannas006/PixsBliss_mobile_app/refs/heads/main/update.json?token=GHSAT0AAAAAADGDJGLZI3BVXT7Q3EHQTAVM2DK62BQ';
  late final Dio _dio;

  UpdateService() {
    _dio = Dio(BaseOptions(
      headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        'Accept': 'application/octet-stream',
        'Accept-Encoding': 'gzip, deflate, br',
      },
      followRedirects: true,
      maxRedirects: 10,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ));
  }

  /// Check for available updates
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get(_updateUrl);
      if (response.statusCode == 200) {
        // Handle both string and Map responses
        Map<String, dynamic> jsonData;
        if (response.data is String) {
          // Parse string response as JSON
          jsonData = json.decode(response.data as String);
        } else {
          // Response is already a Map
          jsonData = response.data as Map<String, dynamic>;
        }
        
        final updateInfo = UpdateInfo.fromJson(jsonData);
        final currentVersion = await _getCurrentVersion();
        
        if (isNewerVersion(updateInfo.version, currentVersion)) {
          return updateInfo;
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  /// Get current app version
  Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      print('Error getting current version: $e');
      return '1.0.0';
    }
  }

  /// Compare versions to determine if new version is available
  bool isNewerVersion(String newVersion, String currentVersion) {
    final newParts = newVersion.split('.').map(int.parse).toList();
    final currentParts = currentVersion.split('.').map(int.parse).toList();
    
    for (int i = 0; i < 3; i++) {
      final newPart = i < newParts.length ? newParts[i] : 0;
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      
      if (newPart > currentPart) return true;
      if (newPart < currentPart) return false;
    }
    return false;
  }

  /// Get the actual download URL from GitHub API
  Future<String?> _getActualDownloadUrl(String apkUrl) async {
    try {
      // For now, let's skip the GitHub API approach and use the direct URL
      // The API approach is causing issues with 415 status codes
      print('Using direct download URL: $apkUrl');
      return apkUrl;
    } catch (e) {
      print('Error getting actual download URL: $e');
      return apkUrl;
    }
  }

  /// Download APK file
  Future<String?> downloadApk(String apkUrl, Function(int, int) onProgress) async {
    try {
      print('Starting download from: $apkUrl');
      
      // Try to get the actual download URL, fallback to original
      String downloadUrl = apkUrl;
      try {
        final actualUrl = await _getActualDownloadUrl(apkUrl);
        if (actualUrl != null) {
          downloadUrl = actualUrl;
        }
      } catch (e) {
        print('Failed to get actual download URL, using original: $e');
      }
      print('Using download URL: $downloadUrl');
      
      // Get downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
        if (!await downloadsDir.exists()) {
          downloadsDir = await getExternalStorageDirectory();
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      if (downloadsDir == null) {
        throw Exception('Could not access downloads directory');
      }

      print('Download directory: ${downloadsDir.path}');

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'PixsBliss_${timestamp}.apk';
      final filePath = '${downloadsDir.path}/$fileName';

      print('Downloading to: $filePath');

      // Download file with progress
      await _dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('Download progress: $received / $total bytes');
            onProgress(received, total);
          }
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
            'Accept': 'application/octet-stream, application/vnd.android.package-archive',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://github.com/',
          },
          followRedirects: true,
          maxRedirects: 10,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      // Verify file was downloaded
      final file = File(filePath);
      if (await file.exists()) {
        final fileSize = await file.length();
        print('Download completed. File size: $fileSize bytes');
        
        // Check if file is too small (likely an HTML error page)
        if (fileSize < 1000) {
          final content = await file.readAsString();
          if (content.contains('<!DOCTYPE html>') || content.contains('<html')) {
            throw Exception('Downloaded file is HTML (error page), not APK. File size: $fileSize bytes');
          }
        }
        
        return filePath;
      } else {
        throw Exception('File was not created after download');
      }
    } catch (e) {
      print('Error downloading APK: $e');
      if (e is DioException) {
        print('DioException details: ${e.response?.statusCode} - ${e.response?.statusMessage}');
        print('Response data: ${e.response?.data}');
      }
      return null;
    }
  }

  /// Request necessary permissions
  Future<bool> requestPermissions() async {
    try {
      // Request storage permission for Android < 10
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt < 29) { // Android 10 = API 29
          final storageStatus = await Permission.storage.request();
          if (!storageStatus.isGranted) {
            return false;
          }
        }
      }

      // Request install permission for Android 8+
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (androidInfo.version.sdkInt >= 26) { // Android 8 = API 26
          final installStatus = await Permission.requestInstallPackages.request();
          if (!installStatus.isGranted) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Install APK file
  Future<bool> installApk(String apkPath) async {
    try {
      if (Platform.isAndroid) {
        // Use open_file to trigger the system package installer
        final result = await OpenFile.open(apkPath);
        return result.type == ResultType.done;
      } else {
        // Use open_file for other platforms (for testing)
        final result = await OpenFile.open(apkPath);
        return result.type == ResultType.done;
      }
    } catch (e) {
      print('Error installing APK: $e');
      return false;
    }
  }

  /// Get download progress percentage
  double getProgressPercentage(int received, int total) {
    if (total <= 0) return 0.0;
    return (received / total) * 100;
  }

  /// Format file size
  String formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    final i = (bytes == 0) ? 0 : (log(bytes) / log(1024)).floor();
    final size = bytes / pow(1024, i);
    return "${size.toStringAsFixed(1)} ${suffixes[i]}";
  }
} 