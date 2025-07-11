import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/wallpaper_provider.dart';
import '../../../../core/providers/update_provider.dart';
import '../../../../core/services/update_service.dart';
import '../../../../shared/widgets/update_dialog.dart';
import '../../../../shared/widgets/download_progress_dialog.dart';
import 'update_page.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _cacheSize;
  bool _isCalculatingCache = false;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version} (Build ${info.buildNumber})';
    });
  }

  Future<void> _calculateCacheSize() async {
    setState(() {
      _isCalculatingCache = true;
      _cacheSize = null;
    });
    final boxNames = [
      'wallpapers',
      'categories',
      'pexels_wallpapers',
      'pexels_trending_wallpapers',
    ];
    int totalBytes = 0;
    for (final boxName in boxNames) {
      try {
        final box = await Hive.openBox(boxName);
        final path = box.path;
        if (path != null) {
          final file = File(path);
          final dir = file.parent;
          final files = dir.listSync().whereType<File>().where((f) {
            final fname = f.uri.pathSegments.last;
            return fname.startsWith(boxName);
          }).toList();
          for (final f in files) {
            if (await f.exists()) {
              final len = await f.length();
              totalBytes += len;
              // Debug print
              // ignore: avoid_print
              print('Cache file: \'${f.path}\' size: $len bytes');
            }
          }
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error checking cache for box $boxName: $e');
      }
    }
    // ignore: avoid_print
    print('Total cache size: $totalBytes bytes');
    setState(() {
      _isCalculatingCache = false;
      _cacheSize = _formatBytes(totalBytes);
    });
  }

  String _formatBytes(int bytes, [int decimals = 2]) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    final i = (bytes == 0) ? 0 : (math.log(bytes) / math.log(1024)).floor();
    final size = bytes / math.pow(1024, i);
    return "${size.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDarkTheme = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120.h,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(
                left: 20.w,
                bottom: 16.h,
              ),
              title: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.grey600.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Settings Content
          SliverPadding(
            padding: EdgeInsets.all(20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // App Preferences Section
                _buildSectionHeader('App Preferences'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: isDarkTheme ? MdiIcons.weatherNight : MdiIcons.weatherSunny,
                    title: 'Dark Theme',
                    subtitle: isDarkTheme ? 'Dark mode enabled' : 'Light mode enabled',
                    trailing: Switch(
                      value: isDarkTheme,
                      onChanged: (value) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                ]),

                SizedBox(height: 24.h),

                // Privacy Section
                _buildSectionHeader('Privacy'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: MdiIcons.shield,
                    title: 'Privacy Policy',
                    subtitle: 'Read our privacy policy',
                    trailing: Icon(
                      MdiIcons.openInNew,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _launchUrl('https://pixsbliss-app.vercel.app/privacy'),
                  ),
                  _buildSettingsTile(
                    icon: MdiIcons.fileDocument,
                    title: 'Terms of Service',
                    subtitle: 'Read terms and conditions',
                    trailing: Icon(
                      MdiIcons.openInNew,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _launchUrl('https://pixsbliss-app.vercel.app/terms'),
                  ),
                  _buildSettingsTile(
                    icon: MdiIcons.cancel,
                    title: 'Cancellation/Refund',
                    subtitle: 'Read our cancellation/refund policy',
                    trailing: Icon(
                      MdiIcons.openInNew,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _launchUrl('https://pixsbliss-app.vercel.app/refund'),
                  ),
                ]),

                SizedBox(height: 24.h),

                // Support Section
                _buildSectionHeader('Support'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: MdiIcons.email,
                    title: 'Contact Us',
                    subtitle: 'Get help and support',
                    trailing: Icon(
                      MdiIcons.openInNew,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _launchUrl('https://pixsbliss-app.vercel.app/contact'),
                  ),
                ]),

                SizedBox(height: 24.h),

                // About Section
                _buildSectionHeader('About'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: MdiIcons.information,
                    title: 'App Version',
                    subtitle: _appVersion ?? 'Loading...',
                    trailing: null,
                  ),
                  _buildSettingsTile(
                    icon: MdiIcons.update,
                    title: 'Check for Updates',
                    subtitle: 'Check for app updates',
                    trailing: Icon(
                      MdiIcons.chevronRight,
                      color: AppColors.grey400,
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const UpdatePage(initialUpdateInfo: null),
                      ),
                    ),
                  ),
                ]),

                SizedBox(height: 40.h),

                // App Logo and Credits
                Center(
                  child: Column(
                    children: [
                      Image.asset(
                        'icon.png',
                        width: 64.w,
                        height: 64.w,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 5.h),
                      Text(
                        'PixsBliss',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Your Daily Dose of Anime Aesthetic',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.grey500,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Made with ❤️ for Anime lovers',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 40.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20.sp,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.titleLarge?.color,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.titleMedium?.color,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all cached images and free up storage space. The app may take longer to load images after clearing cache.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Clear Cache',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _clearCache() {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cache cleared successfully'),
        backgroundColor: AppColors.grey800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showInfoMessage('Could not open the link.');
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
}

