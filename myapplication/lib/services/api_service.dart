// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:frontend/config/api_config.dart';
// import 'package:frontend/models/user.dart';
// import 'package:frontend/models/health_data.dart';
// import 'package:frontend/services/auth_service.dart';

// class ApiService {
//   // HTTP client with timeout
//   static final http.Client _client = http.Client();
//   static const Duration _timeout = Duration(seconds: 30);

//   // User API - Login and Register removed, only profile management remains

//   static Future<ApiResponse<User>> getProfile() async {
//     try {
//       // Try to get token, but don't require it
//       final token = await AuthService.getToken();

//       final response = await _client
//           .get(
//             Uri.parse(ApiConfig.profile),
//             headers: ApiConfig.getHeaders(token: token),
//           )
//           .timeout(_timeout);

//       final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

//       if (response.statusCode == 200) {
//         return ApiResponse.fromJson(
//           jsonData,
//           (data) => User.fromJson(data as Map<String, dynamic>),
//         );
//       } else {
//         throw Exception(jsonData['message'] ?? 'Failed to get profile');
//       }
//     } catch (e) {
//       throw Exception('Get profile error: $e');
//     }
//   }

//   static Future<ApiResponse<User>> updateProfile(
//       UserUpdateRequest request) async {
//     try {
//       // Try to get token, but don't require it
//       final token = await AuthService.getToken();

//       final response = await _client
//           .put(
//             Uri.parse(ApiConfig.updateProfile),
//             headers: ApiConfig.getHeaders(token: token),
//             body: jsonEncode(request.toJson()),
//           )
//           .timeout(_timeout);

//       final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

//       if (response.statusCode == 200) {
//         return ApiResponse.fromJson(
//           jsonData,
//           (data) => User.fromJson(data as Map<String, dynamic>),
//         );
//       } else {
//         throw Exception(jsonData['message'] ?? 'Failed to update profile');
//       }
//     } catch (e) {
//       throw Exception('Update profile error: $e');
//     }
//   }

//   // Health Data API
//   static Future<ApiResponse<HealthData>> createHealthData(
//     HealthDataRequest request,
//   ) async {
//     try {
//       final token = await AuthService.getToken();

//       final response = await _client
//           .post(
//             Uri.parse(ApiConfig.healthData),
//             headers: ApiConfig.getHeaders(token: token),
//             body: jsonEncode(request.toJson()),
//           )
//           .timeout(_timeout);

//       final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

//       if (response.statusCode == 201) {
//         return ApiResponse.fromJson(
//           jsonData,
//           (data) => HealthData.fromJson(data as Map<String, dynamic>),
//         );
//       } else {
//         throw Exception(jsonData['message'] ?? 'Failed to create health data');
//       }
//     } catch (e) {
//       throw Exception('Create health data error: $e');
//     }
//   }

//   static Future<ApiResponse<List<HealthData>>> getHealthData({
//     int? limit,
//     int? offset,
//     int retries = 2,
//   }) async {
//     Exception? lastError;

//     for (int attempt = 0; attempt <= retries; attempt++) {
//       try {
//         final token = await AuthService.getToken();

//         String url = ApiConfig.healthData;
//         if (limit != null || offset != null) {
//           final params = <String, String>{};
//           if (limit != null) params['limit'] = limit.toString();
//           if (offset != null) params['offset'] = offset.toString();
//           url += '?${Uri(queryParameters: params).query}';
//         }

//         final response = await _client
//             .get(
//               Uri.parse(url),
//               headers: ApiConfig.getHeaders(token: token),
//             )
//             .timeout(_timeout);

//         final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

//         if (response.statusCode == 200) {
//           return ApiResponse.fromJson(
//             jsonData,
//             (data) {
//               if (data is List) {
//                 return data
//                     .map((item) =>
//                         HealthData.fromJson(item as Map<String, dynamic>))
//                     .toList();
//               }
//               return <HealthData>[];
//             },
//           );
//         } else {
//           throw Exception(jsonData['message'] ?? 'Failed to get health data');
//         }
//       } on Exception catch (e) {
//         lastError = e;
//         // Jika bukan timeout atau connection error, langsung throw
//         if (!e.toString().contains('TimeoutException') &&
//             !e.toString().contains('timeout') &&
//             !e.toString().contains('Connection') &&
//             attempt < retries) {
//           // Retry untuk timeout/connection errors saja
//           await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
//           continue;
//         }
//         // Jika sudah retry terakhir atau bukan network error, throw
//         if (attempt == retries) {
//           break;
//         }
//       } catch (e) {
//         lastError = Exception('Get health data error: $e');
//         if (attempt == retries) {
//           break;
//         }
//         await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
//       }
//     }

//     // Format error message yang lebih jelas
//     final errorMsg = lastError?.toString() ?? 'Unknown error';
//     if (errorMsg.contains('TimeoutException') || errorMsg.contains('timeout')) {
//       throw Exception('Backend tidak merespons dalam 30 detik.\n\n'
//           'Pastikan:\n'
//           '1. Backend Go running: cd backend && go run cmd/server/main.go\n'
//           '2. Database PostgreSQL connected\n'
//           '3. IP benar: ${ApiConfig.baseUrl}\n'
//           '4. Device dan komputer di WiFi yang sama');
//     } else if (errorMsg.contains('Connection') ||
//         errorMsg.contains('Failed host lookup')) {
//       throw Exception('Tidak bisa connect ke backend.\n\n'
//           'Backend URL: ${ApiConfig.baseUrl}\n\n'
//           'Cek:\n'
//           '1. Backend sudah running?\n'
//           '2. IP address benar?\n'
//           '3. Firewall tidak block port 8080?');
//     }

//     throw Exception('Get health data error: $errorMsg');
//   }

//   static Future<ApiResponse<HealthStats>> getHealthStats({
//     DateTime? date,
//   }) async {
//     try {
//       final token = await AuthService.getToken();

//       String url = ApiConfig.healthStats;
//       if (date != null) {
//         final dateStr = date.toIso8601String().split('T')[0];
//         url += '?date=$dateStr';
//       }

//       final response = await _client
//           .get(
//             Uri.parse(url),
//             headers: ApiConfig.getHeaders(token: token),
//           )
//           .timeout(_timeout);

//       final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

//       if (response.statusCode == 200) {
//         return ApiResponse.fromJson(
//           jsonData,
//           (data) => HealthStats.fromJson(data as Map<String, dynamic>),
//         );
//       } else {
//         throw Exception(jsonData['message'] ?? 'Failed to get health stats');
//       }
//     } catch (e) {
//       throw Exception('Get health stats error: $e');
//     }
//   }

//   static Future<ApiResponse<HealthData>> getLatestHealthData() async {
//     try {
//       final healthDataResponse =
//           await getHealthData(limit: 1).timeout(_timeout, onTimeout: () {
//         throw Exception(
//             'Request timeout: Backend tidak merespons. Pastikan backend running di ${ApiConfig.baseUrl}');
//       });

//       if (healthDataResponse.success &&
//           healthDataResponse.data != null &&
//           healthDataResponse.data!.isNotEmpty) {
//         return ApiResponse<HealthData>(
//           success: true,
//           message: 'Latest health data retrieved',
//           data: healthDataResponse.data!.first,
//         );
//       } else {
//         // Return success dengan data null jika tidak ada data (bukan error)
//         return ApiResponse<HealthData>(
//           success: true,
//           message: 'No health data found',
//           data: null,
//         );
//       }
//     } on Exception catch (e) {
//       // Re-throw dengan pesan yang lebih jelas
//       if (e.toString().contains('TimeoutException') ||
//           e.toString().contains('timeout')) {
//         throw Exception(
//             'Timeout: Backend tidak merespons. Pastikan:\n1. Backend running di ${ApiConfig.baseUrl}\n2. Database PostgreSQL connected\n3. Koneksi internet stabil');
//       }
//       throw Exception('Get latest health data error: $e');
//     } catch (e) {
//       throw Exception('Get latest health data error: $e');
//     }
//   }
// }
