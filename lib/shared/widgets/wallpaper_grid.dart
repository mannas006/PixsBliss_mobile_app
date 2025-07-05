import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../core/models/wallpaper.dart';
import '../../core/providers/wallpaper_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../features/home/presentation/pages/enhanced_wallpaper_detail_page.dart';

class WallpaperGrid extends ConsumerStatefulWidget {
  final String? categoryId;
  final bool isSearch;
  final String? searchQuery;

  const WallpaperGrid({
    super.key,
    this.categoryId,
    this.isSearch = false,
    this.searchQuery,
  });

  @override
  ConsumerState<WallpaperGrid> createState() => _WallpaperGridState();
}

class _WallpaperGridState extends ConsumerState<WallpaperGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isSearch && widget.searchQuery != null) {
        ref.read(searchProvider.notifier).search(widget.searchQuery!);
      } else if (widget.categoryId != null) {
        ref.read(wallpapersProvider.notifier).loadWallpapersByCategory(
          widget.categoryId!,
          refresh: true,
        );
      } else {
        ref.read(wallpapersProvider.notifier).loadWallpapers(refresh: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more wallpapers when near bottom
      if (!widget.isSearch) {
        if (widget.categoryId != null) {
          ref.read(wallpapersProvider.notifier).loadWallpapersByCategory(
            widget.categoryId!,
          );
        } else {
          ref.read(wallpapersProvider.notifier).loadWallpapers();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSearch) {
      final searchState = ref.watch(searchProvider);
      final wallpapers = searchState.results;
      final isLoading = searchState.isLoading;
      final error = searchState.error;

      return _buildGridContent(wallpapers, isLoading, error);
    } else {
      final wallpapersState = ref.watch(wallpapersProvider);
      final wallpapers = wallpapersState.wallpapers;
      final isLoading = wallpapersState.isLoading;
      final error = wallpapersState.error;

      return _buildGridContent(wallpapers, isLoading, error);
    }
  }

  Widget _buildGridContent(List<Wallpaper> wallpapers, bool isLoading, String? error) {
    if (error != null && wallpapers.isEmpty) {
      return _buildErrorWidget(error);
    }

    if (isLoading && wallpapers.isEmpty) {
      return _buildLoadingWidget();
    }

    if (wallpapers.isEmpty) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.isSearch && widget.searchQuery != null) {
          await ref.read(searchProvider.notifier).search(widget.searchQuery!);
        } else if (widget.categoryId != null) {
          await ref.read(wallpapersProvider.notifier).loadWallpapersByCategory(
            widget.categoryId!,
            refresh: true,
          );
        } else {
          await ref.read(wallpapersProvider.notifier).loadWallpapers(refresh: true);
        }
      },
      child: MasonryGridView.count(
        controller: _scrollController,
        crossAxisCount: 2,
        mainAxisSpacing: 8.w,
        crossAxisSpacing: 8.w,
        padding: EdgeInsets.all(16.w),
        itemCount: wallpapers.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= wallpapers.length) {
            return _buildLoadingItem();
          }

          final wallpaper = wallpapers[index];
          return WallpaperGridItem(
            wallpaper: wallpaper,
            onTap: () => _navigateToDetail(wallpaper),
          );
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.primary,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading wallpapers...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              MdiIcons.alertCircle,
              size: 64.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 16.h),
            Text(
              'Oops!',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.grey500,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.isSearch && widget.searchQuery != null) {
                  ref.read(searchProvider.notifier).search(widget.searchQuery!);
                } else if (widget.categoryId != null) {
                  ref.read(wallpapersProvider.notifier).loadWallpapersByCategory(
                    widget.categoryId!,
                    refresh: true,
                  );
                } else {
                  ref.read(wallpapersProvider.notifier).loadWallpapers(refresh: true);
                }
              },
              icon: Icon(MdiIcons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    String title = 'No wallpapers found';
    String subtitle = 'Try a different search or category';
    IconData icon = MdiIcons.imageOff;

    if (widget.isSearch) {
      title = 'No results for "${widget.searchQuery}"';
      subtitle = 'Try different keywords or browse categories';
      icon = MdiIcons.magnify;
    } else if (widget.categoryId != null) {
      title = 'No wallpapers in this category';
      subtitle = 'Check back later for new additions';
      icon = MdiIcons.folderOpen;
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64.sp,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingItem() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  void _navigateToDetail(Wallpaper wallpaper) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WallpaperDetailPage(wallpaper: wallpaper),
      ),
    );
  }
}

class WallpaperGridItem extends ConsumerWidget {
  final Wallpaper wallpaper;
  final VoidCallback onTap;

  const WallpaperGridItem({
    super.key,
    required this.wallpaper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(wallpaper.id);

    return RepaintBoundary(
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          ),
          child: Stack(
            children: [
              // Wallpaper image with rounded corners only if needed
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: CachedNetworkImage(
                  imageUrl: wallpaper.thumbnailUrl ?? wallpaper.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200.h,
                  color: AppColors.grey100,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200.h,
                  color: AppColors.grey100,
                  child: Center(
                    child: Icon(
                      MdiIcons.imageOff,
                      color: AppColors.grey400,
                      size: 32.sp,
                      ),
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
                  height: 60.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Favorite button
              Positioned(
                top: 8.h,
                right: 8.w,
                child: GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggleFavorite(wallpaper.id);
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFavorite ? MdiIcons.heart : MdiIcons.heartOutline,
                      color: isFavorite ? AppColors.error : Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ),
              
              // Download count and resolution
              Positioned(
                bottom: 8.h,
                left: 8.w,
                right: 8.w,
                child: Row(
                  children: [
                    // Resolution
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        wallpaper.resolution,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Download count
                    if (wallpaper.downloadCount > 0)
                      Row(
                        children: [
                          Icon(
                            MdiIcons.download,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            _formatCount(wallpaper.downloadCount),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
