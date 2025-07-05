import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/wallpaper_provider.dart';

class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final favorites = ref.watch(favoritesProvider);
    final wallpapersState = ref.watch(wallpapersProvider);

    // Filter wallpapers to show only favorites
    final favoriteWallpapers = wallpapersState.wallpapers
        .where((wallpaper) => favorites.contains(wallpaper.id))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                left: 20.w,
                bottom: 16.h,
              ),
              title: Text(
                'Favorites',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.error.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (favoriteWallpapers.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(right: 16.w, top: 8.h),
                  child: PopupMenuButton<String>(
                    icon: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        MdiIcons.dotsVertical,
                        color: AppColors.error,
                        size: 20.sp,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'clear_all') {
                        _showClearAllDialog();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'clear_all',
                        child: Row(
                          children: [
                            Icon(
                              MdiIcons.deleteEmpty,
                              color: AppColors.error,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            const Text('Clear All'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Favorites Stats
          if (favoriteWallpapers.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        MdiIcons.heart,
                        color: AppColors.error,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${favoriteWallpapers.length} Favorites',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Your collection of liked wallpapers',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content
          if (favoriteWallpapers.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else ...[
            SliverToBoxAdapter(
              child: SizedBox(height: 20.h),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: _buildFavoritesGrid(favoriteWallpapers),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                MdiIcons.heartOutline,
                size: 64.sp,
                color: AppColors.error.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              'No Favorites Yet',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Start exploring wallpapers and tap the heart icon to add them to your favorites.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.grey500,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to explore tab
                // This would typically be handled by the parent widget
              },
              icon: Icon(MdiIcons.compass),
              label: const Text('Explore Wallpapers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesGrid(List favoriteWallpapers) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16.h,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final wallpaper = favoriteWallpapers[index];
          return _buildFavoriteItem(wallpaper);
        },
        childCount: favoriteWallpapers.length,
      ),
    );
  }

  Widget _buildFavoriteItem(dynamic wallpaper) {
    return GestureDetector(
      onTap: () {
        // Navigate to wallpaper detail
        // This would use the same wallpaper detail page
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.r),
          child: Stack(
            children: [
              // Wallpaper Image
              Positioned.fill(
                child: Container(
                  color: AppColors.grey200,
                  child: Center(
                    child: Icon(
                      MdiIcons.image,
                      color: AppColors.grey400,
                      size: 48.sp,
                    ),
                  ),
                ),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // Remove from favorites button
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(wallpaper.id);
                    _showRemovedFeedback();
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      MdiIcons.heart,
                      color: AppColors.error,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),

              // Wallpaper info
              Positioned(
                bottom: 12.h,
                left: 12.w,
                right: 12.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallpaper.title ?? 'Untitled',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          wallpaper.resolution ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11.sp,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          MdiIcons.download,
                          color: Colors.white.withOpacity(0.8),
                          size: 12.sp,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          '${wallpaper.downloadCount ?? 0}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Favorites'),
        content: const Text(
          'Are you sure you want to remove all wallpapers from your favorites? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllFavorites();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearAllFavorites() {
    final favorites = ref.read(favoritesProvider);
    for (final favoriteId in favorites.toList()) {
      ref.read(favoritesProvider.notifier).toggleFavorite(favoriteId);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All favorites cleared'),
        backgroundColor: AppColors.grey800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRemovedFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Removed from favorites'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.grey800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
