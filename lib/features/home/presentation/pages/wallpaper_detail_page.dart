import 'package:flutter/material.dart';
import '../../../../core/models/wallpaper.dart';
import 'enhanced_wallpaper_detail_page.dart' as Enhanced;

// This file redirects to the enhanced wallpaper detail page to avoid conflicts
class WallpaperDetailPage extends StatelessWidget {
  final Wallpaper wallpaper;

  const WallpaperDetailPage({
    super.key,
    required this.wallpaper,
  });

  @override
  Widget build(BuildContext context) {
    // Forward to the enhanced version
    return Enhanced.WallpaperDetailPage(wallpaper: wallpaper);
  }
}
