import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  // Ad unit IDs
  static const String _androidBannerAdUnitId = 'ca-app-pub-4991521917195620/4198923780';
  static const String _iosBannerAdUnitId = 'ca-app-pub-4991521917195620/7478024947';
  
  // Test ad unit IDs (for development)
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';

  bool _isInitialized = false;
  final List<BannerAd> _loadedAds = [];
  final List<BannerAd> _loadingAds = [];

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return _androidBannerAdUnitId;
    } else if (Platform.isIOS) {
      return _iosBannerAdUnitId;
    }
    return _testBannerAdUnitId;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    }
  }

  Future<BannerAd?> loadBannerAd() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final BannerAd ad = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            _loadedAds.add(ad as BannerAd);
            _loadingAds.remove(ad);
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            _loadingAds.remove(ad);
            ad.dispose();
          },
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) => debugPrint('Banner ad closed'),
        ),
      );

      _loadingAds.add(ad);
      await ad.load();
      
      // Wait a bit for the ad to load
      await Future.delayed(const Duration(seconds: 2));
      
      if (_loadedAds.contains(ad)) {
        return ad;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      return null;
    }
  }

  BannerAd? getLoadedAd() {
    if (_loadedAds.isNotEmpty) {
      return _loadedAds.removeAt(0);
    }
    return null;
  }

  bool get hasLoadedAds => _loadedAds.isNotEmpty;
  bool get isLoadingAds => _loadingAds.isNotEmpty;
  int get loadedAdCount => _loadedAds.length;

  void dispose() {
    for (final ad in _loadedAds) {
      ad.dispose();
    }
    for (final ad in _loadingAds) {
      ad.dispose();
    }
    _loadedAds.clear();
    _loadingAds.clear();
  }

  // Preload multiple ads
  Future<void> preloadAds(int count) async {
    for (int i = 0; i < count; i++) {
      await loadBannerAd();
    }
  }
} 