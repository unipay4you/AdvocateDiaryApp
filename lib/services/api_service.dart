import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseURL =
      AppConfig.baseAPI; // Using baseAPI without /api/
  final _storage = const FlutterSecureStorage();
  String? _userProfileImage;

  String? get userProfileImage => _userProfileImage;
  set userProfileImage(String? value) => _userProfileImage = value;

  Future<Map<String, dynamic>> login(
      String mobileNumber, String password) async {
    try {
      // Get previous token before login
      final previousToken = await _storage.read(key: 'access_token');
      print('\n=== Previous Token ===');
      print('Previous Access Token: $previousToken');
      print('====================\n');

      final url = Uri.parse('${AppConfig.baseUrl}login/');

      // Convert phone number to integer
      final phoneNumber = int.parse(mobileNumber);

      // Print request details
      print('\n=== Login Request Details ===');
      print('Request URL: $url');
      print('Request Method: POST');
      print('Request Body:');
      print('  phone_number: $phoneNumber');
      print('  password: $password');
      print('========================\n');

      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone_number': phoneNumber,
          'password': password,
        }),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Connection timeout. Please check your internet connection and try again.');
        },
      );

      // Print response details
      print('\n=== Login Response Details ===');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body:');
      print(response.body);
      print('========================\n');

      final data = json.decode(response.body);

      if (data['status'] == 200) {
        // Get new token from response
        final newToken = data['data']['access_token'];
        print('\n=== Token Comparison ===');
        print('Previous Token: $previousToken');
        print('New Token: $newToken');
        print('Tokens are different: ${previousToken != newToken}');
        print('====================\n');

        // Store new tokens
        await _storage.write(
            key: 'access_token', value: data['data']['access_token']);
        await _storage.write(
            key: 'refresh_token', value: data['data']['refresh_token']);
        return data;
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } on SocketException catch (e) {
      print('\n=== Connection Error ===');
      print('Error in login: $e');
      print('================\n');
      throw Exception(
          'Unable to connect to server. Please check your internet connection and try again.');
    } catch (e) {
      print('\n=== Login Error ===');
      print('Error in login: $e');
      print('================\n');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('\n=== Token Error ===');
        print('No access token found in storage');
        print('==================\n');
        throw Exception('No access token found');
      }

      print('\n=== Token Details ===');
      print('Token from storage: $token');
      print('Token length: ${token.length}');
      print(
          'Token format check: ${token.startsWith('ey') ? 'Valid JWT format' : 'Invalid JWT format'}');
      print('==================\n');

      final url = Uri.parse('${AppConfig.baseUrl}user/');

      // Print request details
      print('\n=== API Request Details ===');
      print('Request URL: $url');
      print('Request Method: POST');
      print('Request Headers:');
      print('  Authorization: Bearer $token');
      print('  Content-Type: application/json');
      print('========================\n');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Print response details
      print('\n=== API Response Details ===');
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('Response Body:');
      print(response.body);
      print('========================\n');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else if (data['code'] == 'token_not_valid') {
        print('\n=== Token Invalid ===');
        print('Token was invalid or expired');
        print('Deleting token from storage');
        print('==================\n');
        await _storage.delete(key: 'access_token');
        throw Exception('Token is invalid or expired');
      } else {
        throw Exception('Failed to get user data');
      }
    } catch (e) {
      print('\n=== API Error ===');
      print('Error in getUserData: $e');
      print('================\n');
      rethrow;
    }
  }

  Future<void> clearAccessToken() async {
    await _storage.delete(key: 'access_token');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<Map<String, dynamic>> resendOtp(String phoneNumber) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        throw Exception('No access token found');
      }

      final url = Uri.parse('${AppConfig.baseUrl}otp-resend/');

      // Print request details
      print('\n=== OTP Resend Request Details ===');
      print('Request URL: $url');
      print('Request Method: POST');
      print('Request Headers:');
      print('  Authorization: Bearer $token');
      print('Request Body:');
      print('  phone_number: $phoneNumber');
      print('========================\n');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone_number': int.parse(phoneNumber),
        }),
      );

      // Print response details
      print('\n=== OTP Resend Response Details ===');
      print('Response Status Code: ${response.statusCode}');
      print('Response Body:');
      print(response.body);
      print('========================\n');

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('\n=== OTP Resend Error ===');
      print('Error in resendOtp: $e');
      print('================\n');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      // Get the latest token
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('\n=== Token Error ===');
        print('No access token found in storage');
        print('==================\n');
        throw Exception('No access token found');
      }

      print('\n=== Token Details ===');
      print('Token from storage: $token');
      print('Token length: ${token.length}');
      print(
          'Token format check: ${token.startsWith('ey') ? 'Valid JWT format' : 'Invalid JWT format'}');
      print('==================\n');

      final url = Uri.parse('${AppConfig.baseUrl}otp-verify/');

      // Print request details
      print('\n=== OTP Verify Request Details ===');
      print('Request URL: $url');
      print('Request Method: POST');
      print('Request Headers:');
      print('  Authorization: Bearer $token');
      print('  Content-Type: application/json');
      print('Request Body:');
      print('  phone_number: $phoneNumber');
      print('  otp: $otp');
      print('========================\n');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone_number': phoneNumber,
          'otp': otp,
        }),
      );

      // Print response details
      print('\n=== OTP Verify Response Details ===');
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('Response Body:');
      print(response.body);
      print('========================\n');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return data;
      } else if (data['code'] == 'token_not_valid') {
        print('\n=== Token Invalid ===');
        print('Token was invalid or expired');
        print('Deleting token from storage');
        print('==================\n');
        await _storage.delete(key: 'access_token');
        throw Exception('Token is invalid or expired');
      } else {
        throw Exception(data['message'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      print('\n=== OTP Verify Error ===');
      print('Error in verifyOtp: $e');
      print('================\n');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> userData) async {
    try {
      print('\n=== Starting Profile Update ===');
      print('Test 1: Getting access token');
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Get user data to get correct ID
      print('Test 2: Getting user data for correct ID');
      final userResponse = await getUserData();
      if (userResponse['status'] != 200) {
        throw Exception('Failed to get user data');
      }
      final userInfo = userResponse['userData'][0];
      print('User ID from API: ${userInfo['id']}');

      // Get districts data to get state and district IDs
      print('Test 3: Getting districts data for state/district IDs');
      final districtsResponse = await getDistricts();
      if (districtsResponse['status'] != 200) {
        throw Exception('Failed to get districts data');
      }
      final districtsData = districtsResponse['payload'];

      // Find state and district IDs
      String? stateId;
      String? districtId;

      for (var district in districtsData) {
        if (district['state']['state'] == userData['user_state']) {
          stateId = district['state']['id'].toString();
          if (district['district'] == userData['user_district']) {
            districtId = district['id'].toString();
          }
        }
      }

      print('State ID: $stateId, District ID: $districtId');

      print('Test 4: Creating multipart request');
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}user/update/'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add user ID to request fields
      request.fields['id'] = userInfo['id'].toString();

      // Add all text fields
      userData.forEach((key, value) {
        if (value != null &&
            key != 'user_profile_image' &&
            key != 'user_state' &&
            key != 'user_district') {
          request.fields[key] = value.toString();
        }
      });

      // Add state and district IDs
      if (stateId != null) {
        request.fields['user_state'] = stateId;
      }
      if (districtId != null) {
        request.fields['user_district'] = districtId;
      }

      // Print request body details
      print('\n=== Profile Update Request Body ===');
      print('Text Fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });

      // Add image file if present
      if (userData['user_profile_image'] != null) {
        if (userData['user_profile_image'] is File) {
          print('Test 5: Adding new image file to request');
          final file = userData['user_profile_image'] as File;
          print('Image File Details:');
          print('  Path: ${file.path}');
          print('  Size: ${file.lengthSync()} bytes');

          // Add the file to the request
          request.files.add(
            await http.MultipartFile.fromPath(
              'user_profile_image',
              file.path,
              contentType: MediaType('image', 'jpeg'),
            ),
          );
        } else {
          // If it's not a File, it's the existing image path
          print('Test 5: Using existing image path');
          request.fields['user_profile_image'] =
              userData['user_profile_image'].toString();
        }
      } else {
        print('No image file selected');
      }
      print('================================\n');

      print('Test 6: Sending request');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Test 7: Response status: ${response.statusCode}');
      print('Test 8: Response body: ${response.body}');

      final responseData = json.decode(response.body);
      return responseData;
    } catch (e) {
      print('\n=== Error in Profile Update ===');
      print('Error: $e');
      print('================\n');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDistricts() async {
    try {
      print('\n=== Calling getDistricts API ===');
      print('Test 1: Getting access token');
      final token = await _storage.read(key: 'access_token');
      print('Access token: $token');

      print('Test 2: Preparing request');
      final url = '${AppConfig.baseUrl}getdistrict/';
      print('Request URL: $url');
      print('Request Method: GET');
      print('Auth Type: Bearer Token');

      print('Test 3: Making API call');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Test 4: Response received');
      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Raw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Test 5: Response parsed successfully');
        final data = json.decode(response.body);
        print('Parsed Response: $data');

        // Check if data is a List or Map
        if (data is List) {
          return {
            'status': 200,
            'payload': data,
          };
        } else if (data is Map) {
          return {
            'status': 200,
            'payload': data['payload'] ?? data['data'] ?? [],
          };
        } else {
          return {
            'status': 200,
            'payload': [],
          };
        }
      } else {
        print('Test 5: Response error');
        print('Error Status Code: ${response.statusCode}');
        print('Error Response: ${response.body}');
        return {
          'status': response.statusCode,
          'message': 'Failed to load districts',
        };
      }
    } catch (e) {
      print('\n=== Error in getDistricts ===');
      print('Error: $e');
      print('Stack trace: ${StackTrace.current}');
      print('================\n');
      return {
        'status': 500,
        'message': 'An error occurred while loading districts',
      };
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    _userProfileImage = null;
  }

  Future<Map<String, dynamic>> resendVerificationEmail() async {
    print('\n=== Resending Verification Email ===');
    print('Test 1: Preparing API request');

    try {
      final token = await _storage.read(key: 'access_token');
      print('Test 2: Access token retrieved');

      if (token == null) {
        print('Test 3: No access token found');
        throw Exception('No access token found');
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}email-resend/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Test 4: API response received');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Test 5: Response parsed successfully');
        return json.decode(response.body);
      } else {
        print('Test 6: Error response received');
        final errorData = json.decode(response.body);
        return {
          'status': response.statusCode,
          'message':
              errorData['message'] ?? 'Failed to resend verification email',
        };
      }
    } catch (e) {
      print('\nError in resendVerificationEmail: $e');
      return {
        'status': 500,
        'message': 'Failed to resend verification email: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getCases() async {
    try {
      print('\n=== Getting Cases Data ===');
      print('Test 1: Getting access token');
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        throw Exception('No access token found');
      }

      print('Test 2: Making API request');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}cases/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Test 3: Response received');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Test 4: Response parsed successfully');
        return json.decode(response.body);
      } else {
        print('Test 5: Error response received');
        throw Exception('Failed to fetch cases data');
      }
    } catch (e) {
      print('\n=== Error in getCases ===');
      print('Error: $e');
      print('================\n');
      rethrow;
    }
  }
}
