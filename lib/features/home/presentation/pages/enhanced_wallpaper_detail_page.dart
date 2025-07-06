import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'button_animation.dart';
import '../../../../core/models/wallpaper.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/premium_service.dart';
import 'dart:async';

class WallpaperDetailPage extends ConsumerStatefulWidget {
  final Wallpaper wallpaper;

  const WallpaperDetailPage({
    super.key,
    required this.wallpaper,
  });

  @override
  ConsumerState<WallpaperDetailPage> createState() => _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends ConsumerState<WallpaperDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _showInfo = false;
  bool _fullImageLoaded = false;
  bool _downloadComplete = false;
  bool _isUnlocked = false;
  bool _isCheckingUnlockStatus = true;
  StreamSubscription<String>? _unlockSub;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
    
    // Track view in Firestore
    final firestoreService = FirestoreService();
    firestoreService.init().then((_) {
      firestoreService.incrementViewCount(widget.wallpaper.id);
    });

    // Check unlock status
    _checkUnlockStatus();

    _unlockSub = PremiumService().unlockStream.listen((wallpaperId) {
      if (wallpaperId == widget.wallpaper.id && mounted) {
        setState(() {
          _isUnlocked = true;
          _downloadComplete = false;
        });
        debugPrint('UNLOCK EVENT: _isUnlocked=$_isUnlocked, _downloadComplete=$_downloadComplete');
        _showSuccessMessage('Wallpaper unlocked successfully! You can now download it.');
      }
    });
  }

  Future<void> _checkUnlockStatus() async {
    final premiumService = PremiumService();
    await premiumService.init();
    final isUnlocked = await premiumService.isWallpaperUnlocked(widget.wallpaper.id);
    
    if (mounted) {
      setState(() {
        _isUnlocked = isUnlocked;
        _isCheckingUnlockStatus = false;
      });
    }
  }

  @override
  void dispose() {
    _unlockSub?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  bool get _isPremium => widget.wallpaper.featured == true;
  bool get _canDownload => !_isPremium || _isUnlocked;

  String get _buttonText {
    if (_isCheckingUnlockStatus) return 'Loading...';
    if (_isPremium && !_isUnlocked) return 'Unlock ₹1';
    return 'Download';
  }

  VoidCallback? get _buttonAction {
    debugPrint('buttonAction: _isCheckingUnlockStatus=$_isCheckingUnlockStatus, _isPremium=$_isPremium, _isUnlocked=$_isUnlocked');
    if (_isCheckingUnlockStatus) return null;
    if (_isPremium && !_isUnlocked) return _unlockWallpaper;
    return _downloadWallpaper;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('BUILD: _isUnlocked=$_isUnlocked, _isPremium=$_isPremium, _isCheckingUnlockStatus=$_isCheckingUnlockStatus, _canDownload=$_canDownload');
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Full Screen Wallpaper with Zoom
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Hero(
              tag: widget.wallpaper.id,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Stack(
                  children: [
                    // Thumbnail (always visible)
                    CachedNetworkImage(
                      imageUrl: widget.wallpaper.thumbnailUrl ?? widget.wallpaper.imageUrl,
                      fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                    ),
                    // Full image (fades in when loaded)
                    AnimatedOpacity(
                      opacity: _fullImageLoaded ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                  child: CachedNetworkImage(
                    imageUrl: widget.wallpaper.imageUrl,
                    fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
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
                            width: double.infinity,
                            height: double.infinity,
                          );
                        },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Top Controls (Back, Info)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16.w,
                right: 16.w,
                bottom: 16.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 20.w,
                      ),
                    ),
                  ),
                  
                  // Action Buttons
                  Row(
                    children: [
                      // Info Button
                      // Removed info button as requested
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls (Download, Share, Set as Wallpaper)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: MediaQuery.of(context).padding.bottom + 16.h,
                top: 24.h,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Action Buttons Row
                  Center(
                    child: ButtonAnimation(
                      key: ValueKey(_isUnlocked),
                      Colors.white.withOpacity(0.15), // Glass color
                      Colors.white.withOpacity(0.25), // Slightly more opaque for the bar
                      onDownload: _buttonAction ?? () {},
                      isComplete: _downloadComplete,
                      borderRadius: 24.0, // Pass this to ButtonAnimation for more rounding
                      buttonText: _buttonText,
                      isEnabled: !_isCheckingUnlockStatus && !_isDownloading,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info Panel
          // Removed AnimatedPositioned info panel as requested
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: isPrimary ? 20.w : 16.w),
        decoration: BoxDecoration(
          color: isPrimary 
              ? Colors.white 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: isPrimary 
              ? null 
              : Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.black : Colors.white,
              size: 18.w,
            ),
            if (isPrimary) ...[
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.8),
          size: 24.w,
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleInfo() {
    // Removed as info panel is gone
  }

  Future<void> _downloadWallpaper() async {
    debugPrint('Download wallpaper tapped!');
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      _showErrorMessage('Storage permission denied');
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadComplete = false;
    });

    try {
      final dio = Dio();
      final response = await dio.get(
        widget.wallpaper.imageUrl,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/wallpaper_${widget.wallpaper.id}.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      // Save to gallery using gal (works for both Android and iOS)
      try {
        await Gal.putImage(filePath);
        
        // Track download in Firestore after successful download
        try {
          final firestoreService = FirestoreService();
          await firestoreService.init();
          await firestoreService.incrementDownloadCount(widget.wallpaper.id);
          print('Download tracked successfully for wallpaper: ${widget.wallpaper.id}');
        } catch (e) {
          print('Failed to track download in Firestore: $e');
          // Don't show error to user as download was successful
        }
        
        // Success: do not show notification
      } on GalException catch (e) {
        _showErrorMessage(e.type.message);
      }
      setState(() {
        _downloadComplete = true;
      });
    } catch (e) {
      _showErrorMessage('Download failed: $e');
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadProgress = 0.0;
      });
    }
  }

  void _shareWallpaper() {
    // Implement share functionality
    _showInfoMessage('Share functionality will be implemented');
  }

  void _setAsWallpaper() {
    // Implement set as wallpaper functionality
    _showInfoMessage('Set as wallpaper functionality will be implemented');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(6.w),
              child: Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.grey[900]?.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        duration: Duration(seconds: 2),
        elevation: 0,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.info,
              color: Colors.blue,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(message),
          ],
        ),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Future<void> _unlockWallpaper() async {
    debugPrint('_unlockWallpaper called');
    try {
      final premiumService = PremiumService();
      await premiumService.init();
      
      final success = await premiumService.unlockWallpaper(
        widget.wallpaper.id,
        widget.wallpaper.title,
      );
      
      if (success) {
        _showSuccessMessage('Payment initiated! Please complete the payment to unlock this wallpaper.');
        
        // Listen for payment success
        _listenForPaymentSuccess();
      } else {
        _showErrorMessage('Failed to initiate payment. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Error: $e');
    }
  }

  void _listenForPaymentSuccess() {
    // Check unlock status periodically after payment initiation
    Future.delayed(const Duration(seconds: 2), () async {
      await _checkUnlockStatus();
      if (_isUnlocked) {
        _showSuccessMessage('Wallpaper unlocked successfully! You can now download it.');
      }
    });
  }
}
