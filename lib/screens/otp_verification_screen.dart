import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_update_screen.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';
import 'dart:async';
import 'login_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  final _apiService = ApiService();
  bool _isOtpVerified = false;

  // Add new variables for resend OTP functionality
  int _resendAttempts = 0;
  int _cooldownSeconds = 30;
  bool _isResendEnabled = false;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    setState(() {
      _isResendEnabled = false;
      _cooldownSeconds = 30;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        setState(() {
          _isResendEnabled = true;
        });
        timer.cancel();
      }
    });
  }

  void _navigateToEmailVerification(String email) {
    print('\n=== Navigating to Email Verification ===');
    print('Test 1: Preparing navigation with email: $email');

    // Pre-build the email verification screen
    final emailVerificationScreen = EmailVerificationScreen(email: email);

    // Use a microtask to ensure smooth transition
    Future.microtask(() {
      if (mounted) {
        print('Test 2: Starting navigation');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                emailVerificationScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        print('Test 3: Navigation completed');
      }
    });
  }

  void _navigateToProfileUpdate(Map<String, dynamic> userData) {
    print('\n=== Navigating to Profile Update ===');
    print('Test 1: Preparing navigation with user data');

    // Pre-build the profile update screen
    final profileScreen = ProfileUpdateScreen(userData: userData);

    // Use a microtask to ensure smooth transition
    Future.microtask(() {
      if (mounted) {
        print('Test 2: Starting navigation');
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                profileScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        print('Test 3: Navigation completed');
      }
    });
  }

  void _navigateToHome() async {
    print('\n=== Navigating to Home ===');
    print('Test 1: Preparing navigation');

    try {
      print('Test 2: Fetching user data');
      final userResponse = await _apiService.getUserData();

      if (userResponse['status'] == 200) {
        print('Test 3: Data fetched successfully');
        final userData = userResponse['userData'][0];
        final cases = userResponse['cases'] ?? [];
        final count = userResponse['count'] ??
            {
              'total_case': 0,
              'today_cases': 0,
              'tommarow_cases': 0,
              'date_awaited_case': 0,
            };

        print('Test 4: Cases data from user response:');
        print('  - Number of cases: ${cases.length}');
        print('  - Count data: $count');

        // Pre-build the home screen with data
        final homeScreen = HomeScreen(
          userData: userData,
          cases: cases,
          count: count,
        );

        // Use a microtask to ensure smooth transition
        Future.microtask(() {
          if (mounted) {
            print('Test 5: Starting navigation');
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    homeScreen,
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
            print('Test 6: Navigation completed');
          }
        });
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e) {
      print('\n=== Error in _navigateToHome ===');
      print('Error: $e');
      print('================\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _destroyToken() async {
    print('\n=== Destroying Access Token ===');
    print('Test 1: Removing access token from storage');
    try {
      await _apiService.removeAccessToken();
      print('Test 2: Access token removed successfully');
    } catch (e) {
      print('Error destroying token: $e');
    }
  }

  @override
  void dispose() {
    // Destroy token if OTP was not verified
    if (!_isOtpVerified) {
      _destroyToken();
    }
    _cooldownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show confirmation dialog when trying to go back
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Warning'),
            content: const Text(
                'Leaving without verification will log you out. Are you sure?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  await _destroyToken();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
        );

        if (shouldPop ?? false) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OTP Verification'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Warning'),
                  content: const Text(
                      'Leaving without verification will log you out. Are you sure?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _destroyToken();
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Yes'),
                    ),
                  ],
                ),
              );
              if (shouldPop ?? false) {
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              }
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
                Text(
                  'Enter the 6-digit OTP sent to ${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 40),
                // OTP Input Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (index) => SizedBox(
                      width: 45,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (value.length == 1) {
                            if (index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                          }
                        },
                        onEditingComplete: () {
                          if (index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Verify OTP Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
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
                          ),
                        )
                      : const Text('Verify OTP'),
                ),
                const SizedBox(height: 20),
                // Resend OTP Link
                  if (_resendAttempts < 3)
                TextButton(
                      onPressed: _isResendEnabled ? _resendOtp : null,
                      child: Text(
                        _isResendEnabled
                            ? 'Resend OTP'
                            : 'Resend OTP in $_cooldownSeconds seconds',
                        style: TextStyle(
                          color: _isResendEnabled ? Colors.blue : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Starting OTP Verification ===');
      print('Test 1: Calling verify OTP API');
      final response = await _apiService.verifyOtp(
        widget.phoneNumber,
        _otpControllers.map((controller) => controller.text).join(),
      );
      print('Test 2: Response received: ${response['status']}');

      if (response['status'] == 200) {
        setState(() {
          _isOtpVerified = true;
        });
        print('Test 3: OTP verification successful, calling user API');
        // Call user API after successful OTP verification
        final userResponse = await _apiService.getUserData();
        print('Test 3.1: userResponse: $userResponse');
        print('Test 4: User API response received: ${userResponse['status']}');

        if (userResponse['status'] == 200) {
          print('Test 5: User data retrieved successfully');
          final userData = userResponse['userData'][0];
          print('Test 5.1: userData: $userData');
          print('Test 6: is_first_login: ${userData['is_first_login']}');
          print(
              'Test 6.1: is_email_verified: ${userData['is_email_verified']}');
          print('Test 6.2: email: ${userData['email']}');

          if (userData['is_first_login'] == true) {
            print('Test 7: First login detected, navigating to profile update');
            _navigateToProfileUpdate(userData);
          } else if (userData['is_email_verified'] == false) {
            print(
                'Test 8: Email not verified, navigating to email verification');
            _navigateToEmailVerification(userData['email'] ?? '');
          } else {
            print('Test 9: User verified, navigating to home');
            _navigateToHome();
          }
        } else {
          print('Test 10: Error - User API status not 200');
          throw Exception(userResponse['message'] ?? 'Failed to get user data');
        }
      } else {
        print('Test 11: Error - OTP verification status not 200');
        throw Exception(response['message'] ?? 'Failed to verify OTP');
      }
    } catch (e, stackTrace) {
      print('\n=== Error in _verifyOtp ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('================\n');

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _destroyToken();
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendAttempts >= 3) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum resend attempts reached'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('\n=== Resending OTP ===');
      print('Test 1: Attempt ${_resendAttempts + 1} of 3');

      final response = await _apiService.resendOtp(widget.phoneNumber);
      print('Test 2: Response received: ${response['status']}');
      print('Test 3: Response message: ${response['message']}');

      if (response['status'] == 200) {
        print('Test 4: OTP resent successfully');
        setState(() {
          _resendAttempts++;
          _isResendEnabled = false;
        });
        _startCooldownTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'OTP has been resent successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        print('Test 5: Error - OTP resend failed');
        throw Exception(response['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      print('\n=== Error in _resendOtp ===');
      print('Error: $e');
      print('================\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
