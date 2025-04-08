import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _mobileOtpController = TextEditingController();
  final _emailOtpController = TextEditingController();
  bool _isLoading = false;
  bool _isVerifyingOtp = false;
  Timer? _sessionTimer;
  final Duration _sessionTimeout = const Duration(minutes: 2);

  @override
  void initState() {
    super.initState();
    _startSessionTimer();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_sessionTimeout, _handleSessionTimeout);
  }

  void _handleSessionTimeout() {
    if (!mounted) return;

    // Show session expired message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Please try again.'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    // Navigate to login screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _resetSessionTimer() {
    _startSessionTimer();
  }

  bool _validateMobile(String value) {
    // Check if mobile number is numeric and exactly 10 digits
    final mobileRegex = RegExp(r'^[0-9]{10}$');
    return mobileRegex.hasMatch(value);
  }

  bool _validateOtp(String value) {
    final otpRegex = RegExp(r'^[0-9]{6}$');
    return otpRegex.hasMatch(value);
  }

  Future<void> _verifyOtp() async {
    if (_isVerifyingOtp) return;

    try {
      setState(() {
        _isVerifyingOtp = true;
      });

      print('\n=== Making OTP Verification API Call ===');
      final requestData = {
        'phone_number': _mobileController.text,
        'mobile_otp': _mobileOtpController.text,
        'email_otp': _emailOtpController.text,
      };

      print('Request Body: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}otp-verify-changepwd/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== End OTP Verification API Call ===\n');

      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'OTP verified successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to change password screen
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChangePasswordScreen(
                phoneNumber: _mobileController.text,
              ),
            ),
          );
        }
      } else {
        String errorMessage = 'OTP verification failed. Please try again.';

        if (data['error'] != null) {
          final errorData = data['error'] as Map<String, dynamic>;
          final firstError = errorData.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError[0];
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingOtp = false;
        });
      }
    }
  }

  void _showOtpDialog() {
    // Clear previous OTPs
    _mobileOtpController.clear();
    _emailOtpController.clear();

    final otpFormKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: Form(
            key: otpFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _mobileOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Mobile OTP',
                    hintText: 'Enter 6-digit OTP sent to your mobile',
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter mobile OTP';
                    }
                    if (!_validateOtp(value)) {
                      return 'Please enter a valid 6-digit OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailOtpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Email OTP',
                    hintText: 'Enter 6-digit OTP sent to your email',
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email OTP';
                    }
                    if (!_validateOtp(value)) {
                      return 'Please enter a valid 6-digit OTP';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isVerifyingOtp
                  ? null
                  : () {
                      if (otpFormKey.currentState!.validate()) {
                        _verifyOtp();
                      }
                    },
              child: _isVerifyingOtp
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleForgotPassword() async {
    if (_isLoading) return;

    print('\n=== Starting Forgot Password Process ===');
    print('Test 1: Validating form data');

    // Validate mobile number
    if (!_validateMobile(_mobileController.text)) {
      print('Test 2: Invalid mobile number');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('\n=== Making Forgot Password API Call ===');
      final requestData = {
        'phone_number': _mobileController.text,
      };

      print('Request Body: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}forgotpwd/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== End Forgot Password API Call ===\n');

      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'OTP sent successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Show OTP dialog
        _showOtpDialog();
      } else {
        // Handle error responses
        String errorMessage = 'Password reset failed. Please try again.';

        if (data['error'] != null) {
          final errorData = data['error'] as Map<String, dynamic>;
          final firstError = errorData.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError[0];
          }
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error during password reset: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _resetSessionTimer();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forgot Password'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _sessionTimer?.cancel();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Company Logo
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/hey.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Enter your registered mobile number to reset your password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Mobile Number Field
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.length != 10) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleForgotPassword,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                  const SizedBox(height: 20),
                  // Back to Login Link
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _mobileController.dispose();
    _mobileOtpController.dispose();
    _emailOtpController.dispose();
    super.dispose();
  }
}
