import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';

class AdMobNotifier extends StateNotifier<AdMobState> {
  final AdMobService _adMobService = AdMobService();

  AdMobNotifier() : super(AdMobState.initial()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isInitializing: true);
    await _adMobService.initialize();
    state = state.copyWith(
      isInitializing: false,
      isInitialized: true,
    );
    
    // Preload some ads
    await preloadAds(3);
  }

  Future<void> preloadAds(int count) async {
    if (!state.isInitialized) return;
    
    state = state.copyWith(isPreloading: true);
    
    try {
      await _adMobService.preloadAds(count);
      state = state.copyWith(
        isPreloading: false,
        loadedAdCount: _adMobService.loadedAdCount,
      );
    } catch (e) {
      state = state.copyWith(
        isPreloading: false,
        error: e.toString(),
      );
    }
  }

  BannerAd? getAd() {
    final ad = _adMobService.getLoadedAd();
    if (ad != null) {
      state = state.copyWith(
        loadedAdCount: _adMobService.loadedAdCount,
      );
    }
    return ad;
  }

  Future<BannerAd?> loadAd() async {
    if (!state.isInitialized) return null;
    
    state = state.copyWith(isLoading: true);
    
    try {
      final ad = await _adMobService.loadBannerAd();
      state = state.copyWith(
        isLoading: false,
        loadedAdCount: _adMobService.loadedAdCount,
      );
      return ad;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  bool get hasLoadedAds => _adMobService.hasLoadedAds;
  bool get isLoadingAds => _adMobService.isLoadingAds;

  @override
  void dispose() {
    _adMobService.dispose();
    super.dispose();
  }
}

class AdMobState {
  final bool isInitializing;
  final bool isInitialized;
  final bool isLoading;
  final bool isPreloading;
  final int loadedAdCount;
  final String? error;

  const AdMobState({
    required this.isInitializing,
    required this.isInitialized,
    required this.isLoading,
    required this.isPreloading,
    required this.loadedAdCount,
    this.error,
  });

  factory AdMobState.initial() => const AdMobState(
    isInitializing: false,
    isInitialized: false,
    isLoading: false,
    isPreloading: false,
    loadedAdCount: 0,
  );

  AdMobState copyWith({
    bool? isInitializing,
    bool? isInitialized,
    bool? isLoading,
    bool? isPreloading,
    int? loadedAdCount,
    String? error,
  }) {
    return AdMobState(
      isInitializing: isInitializing ?? this.isInitializing,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      isPreloading: isPreloading ?? this.isPreloading,
      loadedAdCount: loadedAdCount ?? this.loadedAdCount,
      error: error ?? this.error,
    );
  }
}

final adMobProvider = StateNotifierProvider<AdMobNotifier, AdMobState>((ref) {
  return AdMobNotifier();
}); 