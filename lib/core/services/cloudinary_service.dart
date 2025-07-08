import 'package:cloudinary_public/cloudinary_public.dart';
import 'dart:io';

class CloudinaryService {
  static final CloudinaryService _instance = CloudinaryService._internal();
  factory CloudinaryService() => _instance;
  CloudinaryService._internal();

  late CloudinaryPublic _cloudinary;
  static const String cloudName = 'dcu35avaw';

  Future<void> init() async {
    _cloudinary = CloudinaryPublic(
      cloudName, // Cloudinary cloud name
      'pixsbliss-unsigned', // Cloudinary upload preset
      cache: false,
    );
  }

  /// Upload image to Cloudinary
  Future<CloudinaryResponse?> uploadImage(File imageFile) async {
    try {
      CloudinaryResponse response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      return response;
    } catch (e) {
      print('Error uploading image to Cloudinary: $e');
      return null;
    }
  }

  /// Get optimized image URL
  String getOptimizedImageUrl(String publicId, {
    int width = 1080,
    int height = 1920,
    String format = 'auto',
    String quality = 'auto',
  }) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/'
           'w_$width,h_$height,f_$format,q_$quality/$publicId';
  }

  /// Get thumbnail URL
  String getThumbnailUrl(String publicId, {
    int width = 300,
    int height = 400,
    String format = 'auto',
    String quality = 'auto',
  }) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/'
           'w_$width,h_$height,f_$format,q_$quality,c_fill/$publicId';
  }

  /// Get original image URL
  String getOriginalImageUrl(String publicId) {
    return 'https://res.cloudinary.com/$cloudName/image/upload/$publicId';
  }

  /// Extract public ID from Cloudinary URL
  String? extractPublicIdFromUrl(String url) {
    try {
      if (url.contains('cloudinary.com')) {
        // Handle different Cloudinary URL formats
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        
        // Find the upload segment and get everything after it
        final uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex != -1 && uploadIndex + 1 < pathSegments.length) {
          // Skip the version if present (v1234567890)
          int startIndex = uploadIndex + 1;
          if (pathSegments[startIndex].startsWith('v')) {
            startIndex++;
          }
          
          // Join all remaining segments as the public ID
          return pathSegments.skip(startIndex).join('/');
        }
      }
      return null;
    } catch (e) {
      print('Error extracting public ID from URL: $e');
      return null;
    }
  }

  /// Convert any Cloudinary URL to thumbnail URL
  String convertToThumbnailUrl(String originalUrl, {
    int width = 300,
    int height = 400,
  }) {
    final publicId = extractPublicIdFromUrl(originalUrl);
    if (publicId != null) {
      return getThumbnailUrl(publicId, width: width, height: height);
    }
    // If we can't extract public ID, return original URL
    return originalUrl;
  }

  /// Convert any Cloudinary URL to optimized URL
  String convertToOptimizedUrl(String originalUrl, {
    int width = 1080,
    int height = 1920,
  }) {
    final publicId = extractPublicIdFromUrl(originalUrl);
    if (publicId != null) {
      return getOptimizedImageUrl(publicId, width: width, height: height);
    }
    // If we can't extract public ID, return original URL
    return originalUrl;
  }

  /// Validate if URL is a valid Cloudinary URL
  bool isValidCloudinaryUrl(String url) {
    return url.contains('cloudinary.com') && url.contains(cloudName);
  }

  /// Debug: Print URL information
  void debugUrl(String url, String context) {
    print('=== Cloudinary Debug: $context ===');
    print('URL: $url');
    print('Is Cloudinary URL: ${isValidCloudinaryUrl(url)}');
    print('Public ID: ${extractPublicIdFromUrl(url)}');
    print('Thumbnail URL: ${convertToThumbnailUrl(url)}');
    print('Optimized URL: ${convertToOptimizedUrl(url)}');
    print('================================');
  }

  /// Delete image from Cloudinary
  Future<bool> deleteImage(String publicId) async {
    try {
      // Note: This requires server-side implementation or signed URLs
      // For now, we'll return true as a placeholder
      print('Delete image with public ID: $publicId');
      return true;
    } catch (e) {
      print('Error deleting image from Cloudinary: $e');
      return false;
    }
  }

  /// Transform image URL with custom parameters
  String transformImageUrl(String publicId, {
    int? width,
    int? height,
    String? format,
    String? quality,
    String? crop,
    String? gravity,
    String? effect,
  }) {
    String url = 'https://res.cloudinary.com/$cloudName/image/upload/';
    
    List<String> transformations = [];
    
    if (width != null && height != null) {
      transformations.add('w_$width,h_$height');
    } else if (width != null) {
      transformations.add('w_$width');
    } else if (height != null) {
      transformations.add('h_$height');
    }
    
    if (format != null) {
      transformations.add('f_$format');
    }
    
    if (quality != null) {
      transformations.add('q_$quality');
    }
    
    if (crop != null) {
      transformations.add('c_$crop');
    }
    
    if (gravity != null) {
      transformations.add('g_$gravity');
    }
    
    if (effect != null) {
      transformations.add('e_$effect');
    }
    
    if (transformations.isNotEmpty) {
      url += '${transformations.join(',')}/';
    }
    
    url += publicId;
    return url;
  }
} 