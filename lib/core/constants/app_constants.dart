/// App-wide constants for UniRide
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'UniRide Transit';
  static const String appTagline = 'Live University Bus Tracking';

  // Super Admin Bootstrap Email
  static const String superAdminEmail = 'meeranxbalochi@gmail.com';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String busesCollection = 'buses';
  static const String routesCollection = 'routes';

  // Firestore Custom Database ID (your Firebase project uses a non-default DB)
  static const String firestoreDatabaseId =
      'ai-studio-dbc3b6d6-5228-498a-814c-23dc87d38fa1';

  // Proximity Alert Threshold
  static const double proximityAlertMeters = 450.0;
  static const double proximityResetMeters = 600.0;

  // QR Code Deep Link Prefix
  static const String qrDeepLinkPrefix = 'uniride://bus/join/';

  // Default Map Center (fallback when no location available)
  static const double defaultLat = 30.1798;  // Quetta, Pakistan
  static const double defaultLng = 66.9750;
}
