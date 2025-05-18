import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final String phoneNumber;

  const ChangePasswordScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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

  bool _validatePassword(String value) {
    // Password must be at least 8 characters long and contain:
    // - At least one uppercase letter
    // - At least one lowercase letter
    // - At least one number
    // - At least one special character
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(value);
  }

  Future<void> _handleChangePassword() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      print('\n=== Making Change Password API Call ===');
      final requestData = {
        'phone_number': widget.phoneNumber,
        'password': _passwordController.text,
      };

      print('Request Body: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}change-password/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=== End Change Password API Call ===\n');

      if (!mounted) return;

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to login screen
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        String errorMessage = 'Password change failed. Please try again.';

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
      print('Error during password change: $e');
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
          title: const Text('Change Password'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _sessionTimer?.cancel();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
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
                    'Enter your new password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // New Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your new password';
                      }
                      if (!_validatePassword(value)) {
                        return 'Password must be at least 8 characters long and contain:\n- At least one uppercase letter\n- At least one lowercase letter\n- At least one number\n- At least one special character';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Change Password Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleChangePassword,
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
                        : const Text('Change Password'),
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
 