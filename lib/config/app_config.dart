class AppConfig {
  static const bool isDevelopment = false; // Change this to false for production
  static const String baseAPI = isDevelopment
      ? 'http://10.0.2.2:8000' // For Android Emulator
      : 'https://mylegaldiary.in';

  static String get baseUrl {
    return '$baseAPI/api/';
  }

  static String get mediaUrl {
    if (isDevelopment) {
      return 'http://10.0.2.2:8000/'; // For Android Emulator
      // return 'http://localhost:8000/'; // For iOS Simulator
      // return 'http://127.0.0.1:8000/'; // For physical device
    } else {
      return 'https://mylegaldiary.in/';
    }
  }
}
