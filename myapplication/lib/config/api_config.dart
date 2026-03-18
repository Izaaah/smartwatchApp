class ApiConfig {
  // Change this to your backend URL
  // For Android emulator, use: http://10.0.2.2:8080
  // For iOS simulator, use: http://localhost:8080
  // For physical device, use your computer's IP: http://192.168.x.x:8080
  static const String baseUrl = 'http://192.168.1.16';

  // API endpoints
  static const String apiBase = '$baseUrl/api';

  // User endpoints
  static const String register = '$apiBase/users/register';
  static const String login = '$apiBase/users/login';
  static const String profile = '$apiBase/users/profile';
  static const String updateProfile = '$apiBase/users/profile';

  // Health endpoints
  static const String healthData = '$apiBase/health';
  static const String healthStats = '$apiBase/health/stats';
  static const String healthPredict = '$apiBase/health/predict';

  // Headers
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
