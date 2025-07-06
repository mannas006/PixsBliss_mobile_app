import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/app_colors.dart';

class DownloadProgressDialog extends StatelessWidget {
  final double progress;
  final String status;
  final VoidCallback? onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.progress,
    required this.status,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.download,
            color: AppColors.primary,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            'Downloading Update',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: AppColors.grey300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8.h,
          ),
          SizedBox(height: 8.h),
          Text(
            '${progress.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 14.sp,
              ),
            ),
          ),
      ],
    );
  }
} 