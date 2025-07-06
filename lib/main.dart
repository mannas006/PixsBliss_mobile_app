import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/firestore_service.dart';
import 'core/services/cache_service.dart';
import 'core/providers/wallpaper_provider.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase and cache services
  final firestoreService = FirestoreService();
  await firestoreService.init();
  await CacheService().init();
  
  // Ensure downloads and views fields exist for all wallpapers
  try {
    await firestoreService.initializeDownloadsField();
    await firestoreService.initializeViewsField();
  } catch (e) {
    print('Error initializing downloads/views field: $e');
  }
  
  // Set system UI overlay style will be handled in the app based on theme

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: WallMuseApp(),
    ),
  );
}

class WallMuseApp extends ConsumerWidget {
  const WallMuseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkTheme = ref.watch(themeProvider);
    
    // Set system UI overlay style based on theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkTheme ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: isDarkTheme ? Brightness.light : Brightness.dark,
      ),
    );
    
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone 12 Pro size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDarkTheme ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomePage(),
          },
        );
      },
    );
  }
}
