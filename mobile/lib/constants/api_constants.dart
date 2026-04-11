class APIConstants {
  // Change to your machine's LAN IP when testing on a physical device.
  // For Android emulator, use 10.0.2.2.
  // For iOS simulator, use localhost.
  static const String baseServerUrl = 'http://192.168.137.132:5000';

  static const String chatUrl = '$baseServerUrl/chat';
  static const String authUrl = '$baseServerUrl/auth';
}

