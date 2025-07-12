import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class StyledAdWidget extends StatelessWidget {
  final BannerAd? ad;
  final bool isLoading;
  final double? height;
  final double? width;

  const StyledAdWidget({
    super.key,
    this.ad,
    this.isLoading = false,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: height ?? 300.h,
      width: width,
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
        child: isLoading
            ? _buildShimmerPlaceholder(theme)
            : ad != null
                ? _buildAdContent(theme)
                : _buildErrorPlaceholder(theme),
      ),
    ).animate()
      .fadeIn(duration: 350.ms)
      .scale(
        begin: const Offset(0.97, 0.97),
        end: const Offset(1, 1),
        duration: 350.ms,
        curve: Curves.easeOutCubic,
      );
  }

  Widget _buildShimmerPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: 1200.ms,
      color: theme.colorScheme.surface,
      angle: 20,
    );
  }

  Widget _buildAdContent(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Stack(
        children: [
          // Ad content
          AdWidget(ad: ad!),
          
          // Ad label overlay
          Positioned(
            top: 8.h,
            left: 8.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Ad',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              size: 32.sp,
            ),
            SizedBox(height: 8.h),
            Text(
              'Ad unavailable',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 