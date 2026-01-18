class AppConstants {
  // Animation Durations
  static const quickAnimation = Duration(milliseconds: 150);
  static const normalAnimation = Duration(milliseconds: 300);
  static const slowAnimation = Duration(milliseconds: 500);

  // UI Dimensions
  static const double minWindowWidth = 1400;
  static const double minWindowHeight = 900;
  static const double sidebarWidth = 280;
  static const double cardBorderRadius = 16;
  static const double buttonBorderRadius = 12;

  // Sync Configuration
  static const int defaultSyncInterval = 30; // minutes
  static const String defaultSyncStrategy = 'pull';

  // Feature Flags
  static const bool enableParticles = true;
  static const bool enableShortcuts = true;
  static const bool enableNotifications = true;
}
