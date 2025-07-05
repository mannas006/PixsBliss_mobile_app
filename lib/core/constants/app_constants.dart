class AppConstants {
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:5001/api';
  
  // App Information
  static const String appName = '';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String themeKey = 'app_theme';
  static const String favoritesKey = 'favorites';
  static const String downloadHistoryKey = 'download_history';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  
  // Download Settings
  static const String downloadFolder = 'WallMuse';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 800);
  
  // Grid Settings
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.6;
  static const double gridSpacing = 8.0;
}
