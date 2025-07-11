import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

class Wallpaper extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String thumbnailUrl;
  final String originalUrl;
  final Category category;
  final List<String> tags;
  final Dimensions dimensions;
  final int fileSize;
  final String format;
  final List<String> colors;
  final bool featured;
  final bool trending;
  final int downloads;
  final int likes;
  final int views;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source; // 'pexels' or 'local' or 'firestore'
  final bool isPremium;
  final int price;

  const Wallpaper({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.thumbnailUrl,
    required this.originalUrl,
    required this.category,
    required this.tags,
    required this.dimensions,
    required this.fileSize,
    required this.format,
    required this.colors,
    required this.featured,
    required this.trending,
    required this.downloads,
    required this.likes,
    required this.views,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.source = 'pexels', // Default to pexels
    this.isPremium = false,
    this.price = 0,
  });

  factory Wallpaper.fromLocalApi(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['_id'].toString(),
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      imageUrl: json['originalUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      originalUrl: json['originalUrl'] as String,
      category: json['category'] != null
          ? Category.fromLocalApi(json['category'] as Map<String, dynamic>)
          : const Category(
              id: '0',
              name: 'Unknown',
              slug: 'unknown',
              color: '#6366f1',
              featured: false,
              order: 0,
              status: 'active',
            ),
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      dimensions: json['dimensions'] != null
          ? Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : const Dimensions(width: 1920, height: 1080),
      fileSize: json['fileSize'] as int? ?? 0,
      format: 'jpg', // Default format
      colors: [], // Empty colors for local wallpapers
      featured: json['featured'] as bool? ?? false,
      trending: json['trending'] as bool? ?? false,
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      status: 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      source: 'local', // Mark as local source
      isPremium: json['isPremium'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
    );
  }

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      originalUrl: json['originalUrl'] as String,
      category: Category.fromJson(json['category'] as Map<String, dynamic>),
      tags: List<String>.from(json['tags'] as List),
      dimensions: Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>),
      fileSize: json['fileSize'] as int,
      format: json['format'] as String,
      colors: List<String>.from(json['colors'] as List),
      featured: json['featured'] as bool,
      trending: json['trending'] as bool,
      downloads: json['downloads'] as int,
      likes: json['likes'] as int,
      views: json['views'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isPremium: json['isPremium'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
    );
  }

  factory Wallpaper.fromFirestore(Map<String, dynamic> json) {
    final cloudinaryService = CloudinaryService();
    
    // Handle different possible field names for image URLs
    String imageUrl = '';
    String thumbnailUrl = '';
    
    // Try different possible field names
    if (json['imageUrl'] != null) {
      imageUrl = json['imageUrl'] as String;
    } else if (json['image_url'] != null) {
      imageUrl = json['image_url'] as String;
    } else if (json['url'] != null) {
      imageUrl = json['url'] as String;
    } else if (json['public_id'] != null) {
      imageUrl = cloudinaryService.getOriginalImageUrl(json['public_id'] as String);
    } else if (json['originalUrl'] != null) {
      imageUrl = json['originalUrl'] as String;
    } else if (json['originalPublicId'] != null) {
      imageUrl = cloudinaryService.getOriginalImageUrl(json['originalPublicId'] as String);
    }
    
    // Handle thumbnail URL
    if (json['thumbnailUrl'] != null) {
      thumbnailUrl = json['thumbnailUrl'] as String;
    } else if (json['thumbnail_url'] != null) {
      thumbnailUrl = json['thumbnail_url'] as String;
    } else if (imageUrl.isNotEmpty) {
      // If we have imageUrl but no thumbnail, create thumbnail from imageUrl
      thumbnailUrl = cloudinaryService.convertToThumbnailUrl(imageUrl);
    }
    
    // Debug the URLs
    print('=== Wallpaper.fromFirestore Debug ===');
    print('Document ID: ${json['_id']}');
    print('Title: ${json['title']}');
    print('Image URL: $imageUrl');
    print('Thumbnail URL: $thumbnailUrl');
    print('Public ID: ${json['public_id']}');
    print('====================================');
    
    // Debug Cloudinary URLs if they exist
    if (imageUrl.isNotEmpty) {
      cloudinaryService.debugUrl(imageUrl, 'Image URL');
    }
    if (thumbnailUrl.isNotEmpty) {
      cloudinaryService.debugUrl(thumbnailUrl, 'Thumbnail URL');
    }
    
    return Wallpaper(
      id: json['_id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      originalUrl: imageUrl, // Use imageUrl as originalUrl for Firestore
      category: json['category'] != null
          ? (json['category'] is Map<String, dynamic>
              ? Category.fromFirestore(json['category'] as Map<String, dynamic>)
              : Category.fromFirestore({'name': json['category'].toString(), '_id': json['category'].toString()}))
          : const Category(
              id: '0',
              name: 'Unknown',
              slug: 'unknown',
              color: '#6366f1',
              featured: false,
              order: 0,
              status: 'active',
            ),
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      dimensions: json['dimensions'] != null
          ? Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>)
          : const Dimensions(width: 1920, height: 1080),
      fileSize: json['fileSize'] as int? ?? 0,
      format: json['format'] as String? ?? 'jpg',
      colors: json['colors'] != null ? List<String>.from(json['colors'] as List) : [],
      featured: json['featured'] as bool? ?? false,
      trending: json['trending'] as bool? ?? false,
      downloads: json['downloads'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      views: json['views'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is Timestamp 
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.parse(json['createdAt'] as String))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is Timestamp 
              ? (json['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['updatedAt'] as String))
          : DateTime.now(),
      source: 'firestore', // Mark as Firestore source
      isPremium: json['isPremium'] as bool? ?? false,
      price: json['price'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'originalUrl': originalUrl,
      'category': category.toJson(),
      'tags': tags,
      'dimensions': dimensions.toJson(),
      'fileSize': fileSize,
      'format': format,
      'colors': colors,
      'featured': featured,
      'trending': trending,
      'downloads': downloads,
      'likes': likes,
      'views': views,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPremium': isPremium,
      'price': price,
    };
  }

  double get aspectRatio => dimensions.width / dimensions.height;

  String get resolution => '${dimensions.width}x${dimensions.height}';

  int get downloadCount => downloads;

  String get fileSizeFormatted {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get dimensionsFormatted => '${dimensions.width} × ${dimensions.height}';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        thumbnailUrl,
        originalUrl,
        category,
        tags,
        dimensions,
        fileSize,
        format,
        colors,
        featured,
        trending,
        downloads,
        likes,
        views,
        status,
        createdAt,
        updatedAt,
        source,
        isPremium,
        price,
      ];
}

class Category extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? icon;
  final String color;
  final String? coverImage;
  final bool featured;
  final int order;
  final int? wallpaperCount;
  final String status;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.icon,
    required this.color,
    this.coverImage,
    required this.featured,
    required this.order,
    this.wallpaperCount,
    required this.status,
  });

  factory Category.fromLocalApi(Map<String, dynamic> json) {
    return Category(
      id: json['_id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#6366f1',
      coverImage: json['coverImage'] as String?,
      featured: json['featured'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      wallpaperCount: json['wallpaperCount'] as int?,
      status: json['status'] as String? ?? 'active',
    );
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String,
      coverImage: json['coverImage'] as String?,
      featured: json['featured'] as bool,
      order: json['order'] as int,
      wallpaperCount: json['wallpaperCount'] as int?,
      status: json['status'] as String,
    );
  }

  factory Category.fromFirestore(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as String? ?? json['id'] as String? ?? 'unknown',
      name: json['name'] as String? ?? 'Unknown',
      slug: json['slug'] as String? ?? (json['name'] as String? ?? 'unknown').toLowerCase().replaceAll(' ', '-'),
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String? ?? '#6366f1',
      coverImage: json['coverImage'] as String?,
      featured: json['featured'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      wallpaperCount: json['wallpaperCount'] as int?,
      status: json['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'color': color,
      'coverImage': coverImage,
      'featured': featured,
      'order': order,
      'wallpaperCount': wallpaperCount,
      'status': status,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        description,
        icon,
        color,
        coverImage,
        featured,
        order,
        wallpaperCount,
        status,
      ];
}

class Dimensions extends Equatable {
  final int width;
  final int height;

  const Dimensions({
    required this.width,
    required this.height,
  });

  factory Dimensions.fromJson(Map<String, dynamic> json) {
    return Dimensions(
      width: json['width'] as int,
      height: json['height'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'width': width,
      'height': height,
    };
  }

  @override
  List<Object> get props => [width, height];
}
