import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firestore_service.dart';
import 'dart:io';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style for splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rotateController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Start animations
    _fadeController.forward();
    _scaleController.repeat(reverse: true);
    _rotateController.repeat();

    // Navigate to home after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
    _handleInstallTracking();
    _sendActiveUserHeartbeat();
  }

  Future<void> _handleInstallTracking() async {
    final prefs = await SharedPreferences.getInstance();
    const installKey = 'install_tracked_id';
    String? installId = prefs.getString(installKey);
    if (installId == null) {
      // First launch, generate UUID and track install
      installId = const Uuid().v4();
      await prefs.setString(installKey, installId);
      final platform = Platform.isAndroid ? 'android' : Platform.operatingSystem;
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;
      final firestoreService = FirestoreService();
      await firestoreService.init();
      await firestoreService.trackInstall(
        id: installId,
        platform: platform,
        appVersion: appVersion,
        timestamp: Timestamp.now(),
      );
    }
  }

  Future<void> _sendActiveUserHeartbeat() async {
    final prefs = await SharedPreferences.getInstance();
    const installKey = 'install_tracked_id';
    String? deviceId = prefs.getString(installKey);
    if (deviceId == null) {
      // If not present, generate and store (should not happen if install tracking is working)
      deviceId = const Uuid().v4();
      await prefs.setString(installKey, deviceId);
    }
    final platform = Platform.isAndroid ? 'android' : Platform.operatingSystem;
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;
    final firestoreService = FirestoreService();
    await firestoreService.init();
    await firestoreService.sendActiveUserHeartbeat(
      deviceId: deviceId,
      platform: platform,
      appVersion: appVersion,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF0a0a0a),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Icon with animations
              AnimatedBuilder(
                animation: Listenable.merge([_fadeController, _scaleController, _rotateController]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (_scaleController.value * 0.2),
                    child: Transform.rotate(
                      angle: _rotateController.value * 0.1,
                      child: Opacity(
                        opacity: _fadeController.value,
                        child: Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.r),
                            child: Image.asset(
                              'icon.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 40.h),
              
              // App Name with fade animation
              FadeTransition(
                opacity: _fadeController,
                child: Text(
                  'PixsBliss',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
              
              SizedBox(height: 8.h),
              
              // Tagline with fade animation
              FadeTransition(
                opacity: _fadeController,
                child: Text(
                  'Your Daily Dose of Anime Aesthetic',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
              ),
              

            ],
          ),
        ),
      ),
    );
  }
} 