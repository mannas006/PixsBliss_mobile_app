import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../core/providers/firestore_wallpaper_provider.dart';
import '../../../../core/models/wallpaper.dart';
import 'wallpaper_detail_page.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/firestore_service.dart';

// Removed all references to local_wallpaper_provider and local logic. This tab now only uses Supabase.

class UserUploadsTab extends ConsumerStatefulWidget {
  const UserUploadsTab({super.key});

  @override
  ConsumerState<UserUploadsTab> createState() => _UserUploadsTabState();
}

class _UserUploadsTabState extends ConsumerState<UserUploadsTab> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(firestoreWallpapersProvider.notifier).loadWallpapers();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallpapersAsync = ref.watch(firestoreWallpapersProvider);
    final trendingAsync = ref.watch(_trendingWallpapersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
          top: false,
          bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(firestoreWallpapersProvider.notifier).refresh();
            await ref.read(_trendingWallpapersProvider.notifier).loadTrendingWallpapers();
          },
          child: CustomScrollView(
            slivers: [
              // Discover Title
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 20.h),
                  child: Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: 1.5,
                    ),
                  ),
                ).animate().slideY(begin: -0.2, end: 0, duration: 600.ms),
              ),

              // Trending section
              // Note: No ordering by createdAt due to possible missing createdAt fields in some trending wallpapers.
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 20.w, top: 0, bottom: 15.h),
                  child: Text(
                    'TRENDING',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: trendingAsync.when(
                  loading: () => const TrendingSkeletonLoader(),
                  error: (error, stack) => SizedBox(
                    height: 140.h,
                    child: Center(child: Text('Failed to load trending wallpapers: \\${error.toString()}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
                  ),
                  data: (trendingWallpapers) => trendingWallpapers.isEmpty
                      ? SizedBox(
                          height: 140.h,
                          child: Center(child: Text('No trending wallpapers found', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color))),
                        )
                      : SizedBox(
                          height: 140.h,
                          child: Builder(
                            builder: (context) {
                              // Shuffle the trendingWallpapers list for random order
                              final shuffledTrending = List<Wallpaper>.from(trendingWallpapers)..shuffle();
                              return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 10.w),
                                itemCount: shuffledTrending.length,
                                itemBuilder: (context, index) {
                                  final wallpaper = shuffledTrending[index];
                                  return Padding(
                                    padding: index == 0
                                    ? EdgeInsets.only(left: 10.w, right: 10.w)
                                    : EdgeInsets.only(right: 10.w),
                                    child: SizedBox(
                                      width: 90.w,
                                      height: 140.h,
                                      child: WallpaperCard(
                                        wallpaper: wallpaper,
                                        heightFactor: 0.5,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                ),
              ),

              // What's New section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: 20.w, top: 25.h, bottom: 15.h),
                child: Text(
                  "WHAT'S NEW",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                        letterSpacing: 1.2,
                    ),
                      ),
                ),
              ),
              wallpapersAsync.when(
                loading: () => SliverToBoxAdapter(child: WallpapersSkeletonLoader()),
                error: (error, stackTrace) => SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load wallpapers',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(firestoreWallpapersProvider.notifier).refresh();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                    ),
                  ),
                  data: (wallpapers) {
                    if (wallpapers.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_upload_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No user uploads found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'User uploaded wallpapers will appear here.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(firestoreWallpapersProvider.notifier).refresh();
                              },
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                        ),
                      );
                    }
                  // Shuffle the wallpapers list for random order
                  final shuffledWallpapers = List<Wallpaper>.from(wallpapers)..shuffle();
                  return SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                    sliver: SliverMasonryGrid.count(
                            crossAxisCount: 2,
                            mainAxisSpacing: 20.h,
                            crossAxisSpacing: 20.w,
                      childCount: shuffledWallpapers.length,
                      itemBuilder: (context, index) {
                              final wallpaper = shuffledWallpapers[index];
                              final size = switch (index % 5) {
                          0 => 1.2,
                          1 => 0.8,
                          2 => 1.0,
                          3 => 0.9,
                          _ => 1.1,
                              };
                        return SizedBox(
                          height: 300.h * size,
                                child: WallpaperCard(
                                  wallpaper: wallpaper,
                                  heightFactor: size,
                                ),
                              );
                      },
                      ),
                    );
                  },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class WallpaperCard extends StatelessWidget {
  final Wallpaper wallpaper;
  final double heightFactor;
  final PlaceholderWidgetBuilder? shimmerPlaceholder;

  const WallpaperCard({
    super.key,
    required this.wallpaper,
    this.heightFactor = 1.0,
    this.shimmerPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Hero(
      tag: wallpaper.id,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WallpaperDetailPage(wallpaper: wallpaper),
            ),
          );
        },
        child: Container(
          height: 300.h * heightFactor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
              child: _ThumbnailToFullImage(
                thumbnailUrl: wallpaper.thumbnailUrl ?? wallpaper.imageUrl,
                imageUrl: wallpaper.imageUrl,
                  height: 300.h * heightFactor,
                  width: double.infinity,
                shimmerPlaceholder: shimmerPlaceholder,
                ),
              ),
          ),
        ),
      ),
    );
  }
}

class _ThumbnailToFullImage extends StatefulWidget {
  final String thumbnailUrl;
  final String imageUrl;
  final double height;
  final double width;
  final PlaceholderWidgetBuilder? shimmerPlaceholder;

  const _ThumbnailToFullImage({
    required this.thumbnailUrl,
    required this.imageUrl,
    required this.height,
    required this.width,
    this.shimmerPlaceholder,
  });

  @override
  State<_ThumbnailToFullImage> createState() => _ThumbnailToFullImageState();
}

class _ThumbnailToFullImageState extends State<_ThumbnailToFullImage> {
  bool _fullImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Thumbnail (always visible)
        CachedNetworkImage(
          imageUrl: widget.thumbnailUrl,
          fit: BoxFit.cover,
          width: widget.width,
          height: widget.height,
          placeholder: widget.shimmerPlaceholder ?? (context, url) => Container(),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.broken_image,
                  color: Colors.grey,
                  size: 48,
                ),
              ),
            ),
        // Full image (fades in when loaded)
        AnimatedOpacity(
          opacity: _fullImageLoaded ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 400),
          child: CachedNetworkImage(
            imageUrl: widget.imageUrl,
            fit: BoxFit.cover,
            width: widget.width,
            height: widget.height,
            fadeInDuration: Duration.zero, // disable default fade
            placeholder: (context, url) => const SizedBox.shrink(),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
            imageBuilder: (context, imageProvider) {
              if (!_fullImageLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _fullImageLoaded = true);
                });
              }
              return Image(
                image: imageProvider,
                fit: BoxFit.cover,
                width: widget.width,
                height: widget.height,
              );
            },
          ),
        ),
      ],
    );
  }
}

// Skeleton loader widget for loading state
class WallpapersSkeletonLoader extends StatelessWidget {
  const WallpapersSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 20.h,
        crossAxisSpacing: 20.w,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8, // Show 8 skeleton tiles
        itemBuilder: (context, index) {
          final size = switch (index % 5) {
            0 => 1.2,
            1 => 0.8,
            2 => 1.0,
            3 => 0.9,
            _ => 1.1,
          };
          return Shimmer.fromColors(
            baseColor: Colors.grey[800]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              height: 300.h * size,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Skeleton loader for trending section
class TrendingSkeletonLoader extends StatelessWidget {
  const TrendingSkeletonLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: index == 0
                ? EdgeInsets.only(left: 10.w, right: 10.w)
                : EdgeInsets.only(right: 10.w),
            child: Container(
              width: 90.w,
              height: 140.h,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        },
      ),
    );
  }
}

final _trendingWallpapersProvider = StateNotifierProvider<_TrendingWallpapersNotifier, AsyncValue<List<Wallpaper>>>((ref) {
  return _TrendingWallpapersNotifier();
});

class _TrendingWallpapersNotifier extends StateNotifier<AsyncValue<List<Wallpaper>>> {
  _TrendingWallpapersNotifier() : super(const AsyncValue.loading()) {
    loadTrendingWallpapers();
  }

  Future<void> loadTrendingWallpapers() async {
    state = const AsyncValue.loading();
    try {
      // Fetch only trending wallpapers
      final wallpapers = await FirestoreService().getTrendingWallpapers();
      print('Fetched trending wallpapers: \\${wallpapers.length}');
      state = AsyncValue.data(wallpapers);
    } catch (e, st) {
      print('Error fetching trending wallpapers: \\${e.toString()}');
      state = AsyncValue.error(e, st);
    }
  }
}
