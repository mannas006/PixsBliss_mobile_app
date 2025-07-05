import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'local_wallpapers_tab.dart'; // For WallpaperCard and skeleton loader
import 'package:shimmer/shimmer.dart';

import '../../../../core/models/wallpaper.dart';
import '../../../../core/providers/pexels_provider.dart';
import '../../../../core/providers/firestore_wallpaper_provider.dart';
import 'enhanced_wallpaper_detail_page.dart';

class CategoryWallpapersPage extends ConsumerStatefulWidget {
  final Category category;
  final bool isFirebaseCategory;

  const CategoryWallpapersPage({super.key, required this.category, this.isFirebaseCategory = false});

  @override
  ConsumerState<CategoryWallpapersPage> createState() => _CategoryWallpapersPageState();
}

class _CategoryWallpapersPageState extends ConsumerState<CategoryWallpapersPage> {
  @override
  void initState() {
    super.initState();
    // Load wallpapers for this category when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear previous search results first
      ref.read(pexelsSearchProvider.notifier).clearSearch();
      // Then search for the new category
      ref.read(pexelsSearchProvider.notifier).searchWallpapers(widget.category.name, refresh: true);
    });
  }

  @override
  void didUpdateWidget(CategoryWallpapersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the category changed, clear and reload data
    if (oldWidget.category.name != widget.category.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(pexelsSearchProvider.notifier).clearSearch();
        ref.read(pexelsSearchProvider.notifier).searchWallpapers(widget.category.name, refresh: true);
      });
    }
  }

  @override
  void dispose() {
    // Optionally clear search state when leaving the page
    // This prevents cached data from showing when returning
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFirebaseCategory) {
      final wallpapersState = ref.watch(firestoreCategoryWallpapersProvider(widget.category.id));
      return wallpapersState.when(
        data: (wallpapers) => _buildFirestoreContent(context, wallpapers),
        loading: () => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const WallpapersSkeletonLoader(),
        ),
        error: (error, stack) => Center(child: Text('Failed to load wallpapers: $error')),
      );
    } else {
      final wallpapersState = ref.watch(pexelsCategoryWallpapersProvider(widget.category.name));
      if (wallpapersState.isLoading && wallpapersState.wallpapers.isEmpty) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const WallpapersSkeletonLoader(),
        );
      }
      return _buildPexelsContent(context, wallpapersState);
    }
  }

  Widget _buildFirestoreContent(BuildContext context, List<Wallpaper> wallpapers) {
    if (wallpapers.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.category.name,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No wallpapers found for ${widget.category.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Wallpapers for this category will appear here.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.category.name,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(firestoreCategoryWallpapersProvider(widget.category.id).notifier).loadWallpapersByCategory(widget.category.id);
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20.h,
                crossAxisSpacing: 20.w,
                childCount: wallpapers.length,
                itemBuilder: (context, index) {
                  final wallpaper = wallpapers[index];
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPexelsContent(BuildContext context, PexelsWallpapersState wallpapersState) {
    List<Wallpaper> allWallpapers = wallpapersState.wallpapers;
    if (wallpapersState.error != null && allWallpapers.isEmpty) {
      return Center(
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
              wallpapersState.error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(pexelsCategoryWallpapersProvider(widget.category.name).notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (allWallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_not_supported,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No wallpapers found for ${widget.category.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Wallpapers for this category will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent && wallpapersState.hasMore && !wallpapersState.isLoading) {
          ref.read(pexelsCategoryWallpapersProvider(widget.category.name).notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            sliver: SliverMasonryGrid.count(
          crossAxisCount: 2,
          mainAxisSpacing: 20.h,
          crossAxisSpacing: 20.w,
              childCount: allWallpapers.length + (wallpapersState.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= allWallpapers.length) {
                  // Lightweight shimmer loader for loading more
                  return Container(
                    height: 300.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(16),
                    ),
                  );
                }
              final wallpaper = allWallpapers[index];
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
                  shimmerPlaceholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      color: Colors.grey[800],
                      height: 300.h * size,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
              },
                ),
              ),
          ],
      ),
    );
  }
}
