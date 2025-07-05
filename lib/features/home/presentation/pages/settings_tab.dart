import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:io';
import 'package:hive/hive.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/wallpaper_provider.dart';

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

                // Storage Section
                _buildSectionHeader('Storage'),
                SizedBox(height: 12.h),
                _buildSettingsCard([
                  _buildSettingsTile(
                    icon: MdiIcons.broom,
                    title: 'Clear Cache',
                    subtitle: 'Free up storage space',
                    trailing: Icon(
                      MdiIcons.chevronRight,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _showClearCacheDialog(),
                  ),
                  _buildSettingsTile(
                    icon: MdiIcons.database,
                    title: 'Cache Size',
                    subtitle: _isCalculatingCache
                        ? 'Calculating...'
                        : (_cacheSize != null
                            ? 'Total Cache Size: $_cacheSize'
                            : 'Tap to calculate'),
                    trailing: _isCalculatingCache
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _isCalculatingCache ? null : _calculateCacheSize,
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
                    onTap: () => _openPrivacyPolicy(),
                  ),
                  _buildSettingsTile(
                    icon: MdiIcons.fileDocument,
                    title: 'Terms of Service',
                    subtitle: 'Read terms and conditions',
                    trailing: Icon(
                      MdiIcons.openInNew,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _openTermsOfService(),
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
                    onTap: () => _contactSupport(),
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
                    subtitle: '1.0.0 (Build 1)',
                    trailing: null,
                  ),
                  _buildSettingsTile(
                    icon: MdiIcons.update,
                    title: 'Check for Updates',
                    subtitle: 'You\'re using the latest version',
                    trailing: Icon(
                      MdiIcons.chevronRight,
                      color: AppColors.grey400,
                    ),
                    onTap: () => _checkForUpdates(),
                  ),
                ]),

                SizedBox(height: 40.h),

                // App Logo and Credits
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          MdiIcons.wallpaper,
                          color: Colors.white,
                          size: 32.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
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

  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Privacy Policy for PixsBliss\n\n'
            'PixsBliss is committed to protecting your privacy. This app does not collect, store, or share any personal information from users.\n\n'
            '1. Data Collection: PixsBliss does not require you to create an account or provide any personal data.\n'
            '2. Usage Data: The app may collect anonymous usage statistics to improve user experience, but this data cannot be used to identify you.\n'
            '3. Third-Party Services: Wallpapers may be sourced from third-party providers (such as Pexels). Please review their privacy policies for more information.\n'
            '4. Permissions: The app may request permissions (such as storage access) solely to save wallpapers to your device.\n'
            '5. Children\'s Privacy: PixsBliss does not knowingly collect information from children under 13.\n\n'
            'By using PixsBliss, you agree to this privacy policy. If you have questions, contact us via the support option in the app.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service for PixsBliss\n\n'
            '1. Acceptance: By using PixsBliss, you agree to these terms. If you do not agree, please do not use the app.\n'
            '2. Personal Use: Wallpapers provided by PixsBliss are for personal, non-commercial use only. You may not redistribute, sell, or use them for commercial purposes.\n'
            '3. Intellectual Property: All wallpapers remain the property of their respective creators or sources.\n'
            '4. Content: PixsBliss strives to provide high-quality, appropriate content, but is not responsible for third-party images.\n'
            '5. Modifications: We may update these terms at any time. Continued use of the app means you accept any changes.\n'
            '6. Disclaimer: PixsBliss is provided as-is without warranties of any kind.\n\n'
            'For questions or concerns, please contact us via the support option in the app.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() async {
    final url = Uri.parse('https://madebymanas.me');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showInfoMessage('Could not open the website.');
    }
  }

  void _checkForUpdates() {
    // TODO: Check for app updates
    _showInfoMessage('You\'re using the latest version');
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

