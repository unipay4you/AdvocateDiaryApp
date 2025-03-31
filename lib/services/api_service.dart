import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
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
      print('Test 1: Preparing request body');

      // Get access token
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
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

      // Convert date format from DD MMM YYYY to YYYY-MM-DD
      String formattedDate = userData['user_dob'];
      if (formattedDate.isNotEmpty) {
        try {
          final months = {
            'Jan': '01',
            'Feb': '02',
            'Mar': '03',
            'Apr': '04',
            'May': '05',
            'Jun': '06',
            'Jul': '07',
            'Aug': '08',
            'Sep': '09',
            'Oct': '10',
            'Nov': '11',
            'Dec': '12'
          };

          final parts = formattedDate.split(' ');
          if (parts.length == 3) {
            final day = parts[0].padLeft(2, '0');
            final month = months[parts[1]];
            final year = parts[2];

            if (month != null) {
              formattedDate = '$year-$month-$day';
              print('Converted date format: $formattedDate');
            }
          }
        } catch (e) {
          print('Error converting date format: $e');
        }
      }

      // Prepare request body
      final requestBody = {
        "id": userInfo['id'],
        "user_profile_image": userData['user_profile_image'] ?? "",
        "email": userData['email'],
        "phone_number": userData['phone_number'],
        "user_name": userData['user_name'],
        "user_dob": formattedDate,
        "user_address1": userData['user_address1'],
        "user_address2": userData['user_address2'],
        "user_address3": userData['user_address3'],
        "user_district_pincode": userData['user_district_pincode'],
        "advocate_registration_number":
            userData['advocate_registration_number'],
        "user_state": stateId,
        "user_district": districtId
      };

      print('Test 4: Request Body:');
      print(requestBody);
      print('Test 5: Access Token: $token');

      print('Test 6: Making API call');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}user/update/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Test 7: Response Status: ${response.statusCode}');
      print('Test 8: Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Test 9: Profile update successful');
        return {
          'status': 200,
          'message': responseData['message'] ?? 'Profile updated successfully',
        };
      } else {
        print('Test 10: Profile update failed');
        return {
          'status': response.statusCode,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e, stackTrace) {
      print('\n=== Error in updateProfile ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('================\n');

      return {
        'status': 500,
        'message': e.toString(),
      };
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
