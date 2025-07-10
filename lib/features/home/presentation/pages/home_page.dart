import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'explore_tab.dart';
import 'categories_tab.dart';
import 'local_wallpapers_tab.dart';
import 'settings_tab.dart';
import 'search_page.dart';
import 'update_page.dart';
import '../../../../core/providers/pexels_provider.dart';
import '../../../../core/providers/firestore_wallpaper_provider.dart';
import '../../../../core/services/update_service.dart';
import '../../../../core/theme/app_colors.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final AnimationController _animationController;
  bool _hasCheckedForUpdates = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Check for updates after a short delay to allow the UI to load
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_hasCheckedForUpdates) {
        _checkForUpdates();
      }
    });
  }

  Future<void> _checkForUpdates() async {
    if (_hasCheckedForUpdates) return;
    _hasCheckedForUpdates = true;
    
    try {
      final updateService = UpdateService();
      final updateInfo = await updateService.checkForUpdate();
      
      if (updateInfo != null && mounted) {
        _showUpdateDialog(updateInfo);
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog(UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.system_update,
              color: AppColors.primary,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              'Update Available',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${updateInfo.version}',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 12.h),
            if (updateInfo.changelog.isNotEmpty) ...[
              Text(
                'What\'s New:',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  updateInfo.changelog,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.grey700,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
            Text(
              'A new version of PixsBliss is available!',
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Later',
              style: TextStyle(
                color: AppColors.grey600,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UpdatePage(initialUpdateInfo: updateInfo),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.update,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Update Now',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  Widget _buildRefreshableTab(Widget child, VoidCallback onRefresh) {
    return child.animate()
      .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }
  
  List<Widget> get _pages => [
    _buildRefreshableTab(
      const UserUploadsTab(),
      () => ref.read(firestoreWallpapersProvider.notifier).loadWallpapers(),
    ),
    _buildRefreshableTab(
      const CategoriesTab(),
      () => ref.read(pexelsCategoriesProvider.notifier).loadCategories(),
    ),
    _buildRefreshableTab(
      const ExploreTab(),
      () => ref.read(pexelsWallpapersProvider.notifier).refresh(),
    ),
  ];

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
          icon: Icon(
            icon,
            color: Theme.of(context).colorScheme.onBackground,
            size: 22.sp,
          ),
          onPressed: onPressed,
      splashRadius: 24,
    );
  }

  Route _createSettingsRoute() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const SettingsTab(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Slide from bottom + Fade
        final slide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeIn);
        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: fade,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF232A36), // top, slightly lighter
              Color(0xFF181C24), // middle
              Color(0xFF181A20), // bottom, very dark
            ],
          ),
        ),
        child: Stack(
        children: [
          // Content
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() {
                _selectedIndex = page;
              });
              _animationController.forward(from: 0);
            },
            itemBuilder: (BuildContext context, int index) {
              return _pages[index];
            },
            itemCount: _pages.length,
          ),
          
          // Top bar buttons with glassmorphism effect
          if (_selectedIndex != 1)
          Positioned(
            top: MediaQuery.of(context).padding.top + 1,
            right: 10,
            child: Row(
              children: [
                  // _buildGlassButton(
                  //   icon: Icons.search,
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       CupertinoPageRoute(builder: (context) => const SearchPage()),
                  //     );
                  //   },
                  // ),
                  // SizedBox(width: 2.w),
                _buildGlassButton(
                  icon: Icons.settings_rounded,
                  onPressed: () {
                    Navigator.of(context, rootNavigator: true).push(_createSettingsRoute());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) => 
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _selectedIndex == index ? 24.w : 8.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: _selectedIndex == index 
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
