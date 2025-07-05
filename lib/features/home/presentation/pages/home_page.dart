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
import '../../../../core/providers/pexels_provider.dart';
import '../../../../core/providers/firestore_wallpaper_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  late final AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
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
            top: MediaQuery.of(context).padding.top + 2,
            right: 16,
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
                    Navigator.of(context, rootNavigator: true).push(
                      CupertinoPageRoute(
                        builder: (context) => const SettingsTab(),
                        settings: const RouteSettings(name: '/settings'),
                      ),
                    );
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
