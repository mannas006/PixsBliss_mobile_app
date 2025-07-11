import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PremiumService {
  static final PremiumService _instance = PremiumService._internal();
  factory PremiumService() => _instance;
  PremiumService._internal();

  late Razorpay _razorpay;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  // Razorpay configuration
  static const String _razorpayKeyId = 'rzp_live_j2iRZuhALUmC6O';

  final StreamController<String> _unlockController = StreamController.broadcast();
  Stream<String> get unlockStream => _unlockController.stream;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize Razorpay
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

      _isInitialized = true;
      log('✅ PremiumService initialized successfully');
    } catch (e) {
      log('❌ Error initializing PremiumService: $e');
      rethrow;
    }
  }

  /// Check if a wallpaper is unlocked
  Future<bool> isWallpaperUnlocked(String wallpaperId) async {
    if (!_isInitialized) await init();
    return _prefs.getBool('unlocked_$wallpaperId') ?? false;
  }

  /// Unlock a wallpaper
  Future<bool> unlockWallpaper(String wallpaperId, String wallpaperTitle) async {
    try {
      if (!_isInitialized) await init();

      // Create payment options
      var options = {
        'key': _razorpayKeyId,
        'amount': 100, // ₹1 = 100 paise
        'name': 'PixsBliss',
        'description': 'Unlock Premium Wallpaper: $wallpaperTitle',
        'timeout': 180, // 3 minutes
        'prefill': {
          'contact': '',
          'email': '',
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      log('Opening Razorpay payment gateway for wallpaper: $wallpaperId');
      
      // Open payment gateway
      _razorpay.open(options);
      
      // Store wallpaper ID for payment success callback
      await _prefs.setString('pending_unlock', wallpaperId);
      
      return true;
    } catch (e) {
      log('❌ Error initiating payment: $e');
      return false;
    }
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    log('Payment successful:  [32m${response.paymentId} [0m');
    
    // Get the pending unlock wallpaper ID
    final wallpaperId = _prefs.getString('pending_unlock');
    if (wallpaperId != null) {
      // Mark wallpaper as unlocked
      await _prefs.setBool('unlocked_$wallpaperId', true);
      _prefs.remove('pending_unlock');
      _unlockController.add(wallpaperId); // Notify listeners
      
      log('Wallpaper $wallpaperId unlocked successfully');
    }
  }

  /// Handle payment error
  void _handlePaymentError(PaymentFailureResponse response) {
    log('Payment failed: ${response.code} - ${response.message}');
    _prefs.remove('pending_unlock');
  }

  /// Handle external wallet
  void _handleExternalWallet(ExternalWalletResponse response) {
    log('External wallet selected: ${response.walletName}');
  }

  /// Manually unlock a wallpaper (for testing or admin purposes)
  Future<void> manuallyUnlockWallpaper(String wallpaperId) async {
    if (!_isInitialized) await init();
    await _prefs.setBool('unlocked_$wallpaperId', true);
    log('Wallpaper $wallpaperId manually unlocked');
  }

  /// Get all unlocked wallpapers
  Future<List<String>> getUnlockedWallpapers() async {
    if (!_isInitialized) await init();
    
    final keys = _prefs.getKeys();
    final unlockedWallpapers = keys
        .where((key) => key.startsWith('unlocked_'))
        .where((key) => _prefs.getBool(key) == true)
        .map((key) => key.replaceFirst('unlocked_', ''))
        .toList();
    
    return unlockedWallpapers;
  }

  /// Clear unlock status for a wallpaper
  Future<void> clearUnlockStatus(String wallpaperId) async {
    if (!_isInitialized) await init();
    await _prefs.remove('unlocked_$wallpaperId');
    log('Unlock status cleared for wallpaper $wallpaperId');
  }

  /// Clear all unlock statuses (for testing)
  Future<void> clearAllUnlockStatuses() async {
    if (!_isInitialized) await init();
    
    final keys = _prefs.getKeys();
    final unlockKeys = keys.where((key) => key.startsWith('unlocked_')).toList();
    
    for (final key in unlockKeys) {
      await _prefs.remove(key);
    }
    
    log('All unlock statuses cleared');
  }

  /// Dispose Razorpay instance
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
    }
    _unlockController.close();
  }
} 