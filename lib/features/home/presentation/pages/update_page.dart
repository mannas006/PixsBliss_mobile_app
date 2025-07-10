import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/update_provider.dart';
import '../../../../core/services/update_service.dart';
import '../../../../shared/widgets/update_dialog.dart';
import '../../../../shared/widgets/download_progress_dialog.dart';

class UpdatePage extends ConsumerStatefulWidget {
  final UpdateInfo? initialUpdateInfo;
  
  const UpdatePage({
    super.key,
    this.initialUpdateInfo,
  });

  @override
  ConsumerState<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends ConsumerState<UpdatePage> {
  String _currentVersion = '';
  bool _isChecking = false;
  UpdateInfo? _updateInfo;
  String? _errorMessage;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
    
    // If update info is provided, use it immediately
    if (widget.initialUpdateInfo != null) {
      _updateInfo = widget.initialUpdateInfo;
    }
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _currentVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _currentVersion = 'Unknown';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _updateInfo = null;
      _errorMessage = null;
    });

    try {
      final updateService = ref.read(updateServiceProvider);
      final updateInfo = await updateService.checkForUpdate();
      
      setState(() {
        _isChecking = false;
        _updateInfo = updateInfo;
      });
    } catch (e) {
      setState(() {
        _isChecking = false;
        _errorMessage = 'Failed to check for updates. Please try again.';
      });
    }
  }

  Future<void> _downloadUpdate(UpdateInfo updateInfo) async {
    _cancelToken = CancelToken();
    try {
      // Request permissions first
      final updateService = ref.read(updateServiceProvider);
      final hasPermissions = await updateService.requestPermissions();
      if (!hasPermissions) {
        _showInfoMessage('Storage and install permissions are required to download updates.');
        return;
      }

      // Set downloading state
      ref.read(isDownloadingProvider.notifier).state = true;
      ref.read(downloadStatusProvider.notifier).state = 'Preparing download...';

      // Show download progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Consumer(
          builder: (context, ref, child) {
            final progress = ref.watch(updateDownloadProgressProvider);
            final status = ref.watch(downloadStatusProvider);
            
            return DownloadProgressDialog(
              progress: progress,
              status: status,
              onCancel: () {
                _cancelToken?.cancel();
                ref.read(isDownloadingProvider.notifier).state = false;
                Navigator.of(context).pop();
                _showInfoMessage('Download canceled');
              },
            );
          },
        ),
      );

      // Download APK
      final apkPath = await updateService.downloadApk(
        updateInfo.apkUrl,
        (received, total) {
          final progress = updateService.getProgressPercentage(received, total);
          final status = 'Downloading... ${updateService.formatFileSize(received)} / ${updateService.formatFileSize(total)}';
          
          ref.read(updateDownloadProgressProvider.notifier).state = progress;
          ref.read(downloadStatusProvider.notifier).state = status;
        },
        cancelToken: _cancelToken,
      );

      // Hide download dialog
      if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      }

      if (apkPath != null) {
        // Update status
        ref.read(downloadStatusProvider.notifier).state = 'Download completed! Installing...';
        
        // Install APK
        final success = await updateService.installApk(apkPath);
        
        if (success) {
          _showInfoMessage('Update downloaded successfully! Please complete the installation.');
        } else {
          _showInfoMessage('Download completed! Please install the APK manually from your Downloads folder.');
        }
      } else if (!(_cancelToken?.isCancelled ?? false)) {
        _showInfoMessage('Failed to download update. Please try again.');
      }
    } catch (e) {
      // Hide download dialog if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (e is DioException && (e.type == DioExceptionType.cancel || (_cancelToken?.isCancelled ?? false))) {
        _showInfoMessage('Download canceled');
      } else {
      _showInfoMessage('Failed to download update. Please try again.');
      }
    } finally {
      // Reset states
      ref.read(isDownloadingProvider.notifier).state = false;
      ref.read(updateDownloadProgressProvider.notifier).state = 0.0;
      ref.read(downloadStatusProvider.notifier).state = '';
      _cancelToken = null;
    }
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.grey800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'App Updates',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Version Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(
                          MdiIcons.information,
                          color: AppColors.primary,
                          size: 24.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Version',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'v$_currentVersion',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Check for Updates Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isChecking ? null : _checkForUpdates,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: _isChecking
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        MdiIcons.update,
                        size: 20.sp,
                      ),
                label: Text(
                  _isChecking ? 'Checking for Updates...' : 'Check for Updates',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: 24.h),

            // Update Status
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      MdiIcons.alertCircle,
                      color: AppColors.error,
                      size: 20.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_updateInfo != null) ...[
              // Update Available Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            MdiIcons.update,
                            color: AppColors.primary,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Available',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'v${_updateInfo!.version}',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _updateInfo!.changelog,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.grey700,
                          height: 1.4,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadUpdate(_updateInfo!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: Icon(
                          MdiIcons.download,
                          size: 18.sp,
                        ),
                        label: Text(
                          'Download Update',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_isChecking && _errorMessage == null) ...[
              // No Update Available
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.grey400.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        MdiIcons.checkCircle,
                        color: AppColors.grey400,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Up to Date',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey600,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'You\'re using the latest version',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 