import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/providers/pexels_provider.dart';
import 'enhanced_wallpaper_detail_page.dart';

class ExploreTab extends ConsumerStatefulWidget {
  const ExploreTab({super.key});

  @override
  ConsumerState<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends ConsumerState<ExploreTab>
    with AutomaticKeepAliveClientMixin {
  
  late ScrollController _scrollController; // Controller for the main CustomScrollView
  late ScrollController _trendingScrollController; // Controller for the Trending ListView

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _trendingScrollController = ScrollController();
    _trendingScrollController.addListener(_onTrendingScroll);
    
    // Explicitly load wallpapers for the 'What's New' section on initialization
    // Adding a small delay to potentially improve reliability on hot reboot.
    Future.delayed(const Duration(milliseconds: 50), () {
      ref.read(pexelsWallpapersProvider.notifier).loadWallpapers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _trendingScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more wallpapers when near bottom of the main list (What's New)
      ref.read(pexelsWallpapersProvider.notifier).loadWallpapers();
    }
  }

  void _onTrendingScroll() {
    if (_trendingScrollController.position.pixels >=
        _trendingScrollController.position.maxScrollExtent - 200) {
      // Load more wallpapers when near the end of the trending list
      // This assumes loadWallpapers appends to the overall list.
      ref.read(pexelsWallpapersProvider.notifier).loadWallpapers();
    }
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, top: 25.h, bottom: 15.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    ).animate()
      .slideX(begin: -0.2, end: 0, duration: 600.ms);
  }

  Widget _buildWallpaperCard(dynamic wallpaper, {bool isLarge = false}) {
    return Hero(
      tag: wallpaper.id,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: GestureDetector(
            onTap: () async {
              // Preload the full image before navigating (no loading UI)
              await precacheImage(CachedNetworkImageProvider(
                wallpaper.imageUrl,
                cacheKey: wallpaper.id.toString(),
              ), context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => WallpaperDetailPage(wallpaper: wallpaper),
                ),
              );
            },
            child: Container(
              // Removed margin for uniform spacing
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18.r),
                child: CachedNetworkImage(
                  imageUrl: wallpaper.imageUrl,
                  cacheKey: wallpaper.id.toString(),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 350.ms)
      .scale(
        begin: const Offset(0.97, 0.97),
        end: const Offset(1, 1),
        duration: 350.ms,
        curve: Curves.easeOutCubic,
      );
  }

  Widget _buildShimmerGrid(int count) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h), // Match grid padding
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 20.h, // Match grid spacing
        crossAxisSpacing: 20.w, // Match grid spacing
        childCount: count,
        itemBuilder: (context, index) {
          final size = switch (index % 5) {
            0 => 1.1,
            1 => 0.75,
            2 => 0.9,
            3 => 0.85,
            _ => 1.0,
          };
          final theme = Theme.of(context);
          return Padding(
            padding: EdgeInsets.zero, // Remove extra padding for uniformity
            child: SizedBox(
              height: 300.h * size,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(18.r), // Match card radius
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.08),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1200.ms,
                color: theme.colorScheme.surface,
                angle: 20
              )
              .fadeIn(duration: 400.ms, delay: (index * 80).ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 400.ms,
                delay: (index * 80).ms
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingShimmerList(int count) {
    return SizedBox(
      height: 140.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount: count,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: SizedBox(
              width: 90.w,
              height: 140.h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(
                duration: 1200.ms,
                color: Colors.grey[700]!,
                angle: 20
              )
              .fadeIn(duration: 400.ms, delay: (index * 80).ms)
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1, 1),
                duration: 400.ms,
                delay: (index * 80).ms
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final wallpapersState = ref.watch(pexelsWallpapersProvider);
    final trendingState = ref.watch(pexelsTrendingWallpapersProvider);
    
    // Trigger initial load if the list is empty and not currently loading or in an error state
    if (wallpapersState.wallpapers.isEmpty && !wallpapersState.isLoading && wallpapersState.error == null) {
      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() => ref.read(pexelsWallpapersProvider.notifier).loadWallpapers());
    }

    // Auto-load more if content does not fill viewport and more data is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          wallpapersState.hasMore &&
          !wallpapersState.isLoading &&
          _scrollController.position.maxScrollExtent <= _scrollController.position.viewportDimension) {
        ref.read(pexelsWallpapersProvider.notifier).loadWallpapers();
      }
    });

    if (wallpapersState.error != null && wallpapersState.wallpapers.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              "Couldn't load wallpapers",
              style: TextStyle(
                fontSize: 18.sp,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(pexelsWallpapersProvider.notifier).refresh(),
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    final wallpapers = wallpapersState.wallpapers;
    final trendingWallpapers = trendingState.wallpapers;
    final newWallpapers = wallpapers; // Use all wallpapers for the grid

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(pexelsWallpapersProvider.notifier).refresh();
      },
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Title with settings
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 65.h, 20.w, 4.h),
                child: Text(
                  'Featured Wall ✨',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ).animate().slideY(begin: -0.2, end: 0, duration: 600.ms),
            ),

            if (wallpapersState.isLoading && wallpapers.isEmpty)
              _buildShimmerGrid(8)
            else
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h), // Uniform side padding
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20.h, // Uniform spacing
                  crossAxisSpacing: 20.w, // Uniform spacing
                  childCount: newWallpapers.length + (wallpapersState.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= newWallpapers.length) {
                      // Remove spinner for loading more, show a shimmer placeholder instead
                      final size = switch (index % 5) {
                        0 => 1.1,
                        1 => 0.75,
                        2 => 0.9,
                        3 => 0.85,
                        _ => 1.0,
                      };
                      return Padding(
                        padding: EdgeInsets.zero,
                        child: SizedBox(
                          height: 300.h * size,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(18.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .shimmer(
                            duration: 1200.ms,
                            color: Colors.grey[700]!,
                            angle: 20
                          )
                          .fadeIn(duration: 400.ms, delay: (index * 80).ms)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1, 1),
                            duration: 400.ms,
                            delay: (index * 80).ms
                          ),
                        ),
                      );
                    }
                    final wallpaper = newWallpapers[index];
                    final size = switch (index % 5) {
                      0 => 1.1,
                      1 => 0.75,
                      2 => 0.9,
                      3 => 0.85,
                      _ => 1.0,
                    };
                    return Padding(
                      padding: EdgeInsets.zero, // Remove extra padding for uniformity
                      child: SizedBox(
                        height: 300.h * size,
                        child: _buildWallpaperCard(
                          wallpaper,
                          isLarge: false,
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // Removed bottom padding as CustomScrollView handles it
          ],
        ),
      ),
    );
  }
}
