import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/rendering.dart';

import '../../../../core/providers/pexels_provider.dart';
import 'enhanced_wallpaper_detail_page.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  String _query = '';
  bool _showClearButton = false;
  final ScrollController _scrollController = ScrollController(); // Added for smooth scroll

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _searchController.addListener(() {
      setState(() {
        _showClearButton = _searchController.text.isNotEmpty;
      });
    });
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _scrollController.dispose(); // Dispose scroll controller
    super.dispose();
  }

  void _performSearch() {
    if (_searchController.text.trim().isNotEmpty) {
      setState(() {
        _query = _searchController.text.trim();
      });
      _focusNode.unfocus();
      // Perform search using Pexels API
      ref.read(pexelsSearchProvider.notifier).searchWallpapers(_query, refresh: true);
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
              padding: EdgeInsets.all(16.w),
      color: const Color(0xFF23232B), // Use a solid color for performance
              child: Row(
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 20.w,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Search Bar
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _slideAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                  offset: Offset(30 * _slideAnimation.value, 0), // Less movement
                          child: Opacity(
                            opacity: _fadeAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                        color: const Color(0xFF23232B),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: _focusNode.hasFocus 
                                      ? Colors.purple.withOpacity(0.3)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: TextField(
                                autofocus: true,
                                focusNode: _focusNode,
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: "Search for amazing wallpapers...",
                                  border: InputBorder.none,
                                  prefixIcon: Icon(
                                    Icons.search,
                            color: Colors.grey[300],
                                    size: 22.w,
                                  ),
                                  suffixIcon: _showClearButton
                                      ? GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() {
                                              _query = '';
                                            });
                                          },
                                          child: Icon(
                                            Icons.clear,
                                            color: Colors.grey[400],
                                            size: 22.w,
                                          ),
                                        )
                                      : null,
                                  hintStyle: TextStyle(
                            color: Colors.grey[400],
                                    fontSize: 16.sp,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 14.h,
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 16.sp,
                          color: Colors.white,
                                ),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => _performSearch(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Search Button
                  GestureDetector(
                    onTap: _performSearch,
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                color: Colors.purple, // Use a solid color for performance
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.search,
                        size: 20.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Set dark background immediately
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            // Search Results
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_query.isEmpty) {
      return AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0), // Reduce top padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Removed extra SizedBox, so text is closer to search bar
                  Text(
                    "Discover Amazing Wallpapers",
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Search for beautiful wallpapers from Pexels",
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return _buildWallpaperGrid();
  }

  Widget _buildWallpaperGrid() {
    final searchState = ref.watch(pexelsSearchProvider);
    if (searchState.isLoading && searchState.wallpapers.isEmpty) {
      // Show skeleton loader grid
      return _buildSkeletonGrid();
    }
    
    if (searchState.error != null && searchState.wallpapers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64.w,
                color: Colors.red.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "Something went wrong",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Use white for dark bg
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              searchState.error!,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => ref.read(pexelsSearchProvider.notifier).searchWallpapers(_query, refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                "Try Again",
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    final wallpapers = searchState.wallpapers;
    
    if (wallpapers.isEmpty && !searchState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64.w,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              "No wallpapers found",
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white, // Use white for dark bg
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Try searching for something else",
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          ref.read(pexelsSearchProvider.notifier).loadMore();
        }
        return false;
      },
      child: AnimatedSwitcher(
        duration: 400.ms,
        child: CustomScrollView(
          key: ValueKey(wallpapers.length),
          controller: _scrollController, // Attach controller
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // Smooth scroll
          slivers: [
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20.h,
                crossAxisSpacing: 20.w,
                childCount: wallpapers.length + (searchState.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= wallpapers.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.h),
                        child: CircularProgressIndicator(
                          color: Colors.purple,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }
                  final wallpaper = wallpapers[index];
                  return _buildWallpaperCard(wallpaper, index)
                    .animate()
                    .fadeIn(duration: 350.ms, delay: (index * 40).ms)
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      end: const Offset(1, 1),
                      duration: 350.ms,
                      delay: (index * 40).ms,
                      curve: Curves.easeOutCubic,
                    );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    // Show 6 skeleton cards as placeholders
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 20.h,
        crossAxisSpacing: 20.w,
        itemCount: 6,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (context, index) {
          return Container(
            height: (index % 2 == 0 ? 220.h : 160.h),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(18.r),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 1200.ms,
              color: Colors.grey[700]!,
              angle: 20,
            );
        },
      ),
    );
  }

  Widget _buildWallpaperCard(wallpaper, int index) {
    return Hero(
      tag: wallpaper.id,
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.r),
          child: GestureDetector(
            onTap: () async {
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
    );
  }

  @override
  bool get wantKeepAlive => true;
}
