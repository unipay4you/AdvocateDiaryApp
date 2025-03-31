import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'otp_verification_screen.dart';
import 'profile_update_screen.dart';
import 'email_verification_screen.dart';
import 'home_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _acceptTerms = false;
  bool _isLoading = false;
  final _apiService = ApiService();
  final _storage = const FlutterSecureStorage();

  Future<void> _launchTermsAndConditions() async {
    print('\n=== Launching Terms and Conditions ===');
    print('Test 1: Loading terms file');
    final String terms =
        await rootBundle.loadString('assets/terms_and_conditions.txt');
    print('Test 2: Terms loaded successfully');

    if (!mounted) {
      print('Test 3: Widget not mounted, returning');
      return;
    }

    print('Test 4: Showing terms dialog');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Terms and Conditions'),
          content: SingleChildScrollView(
            child: Text(terms),
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('Test 5: Closing terms dialog');
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    print('\n=== Starting Login Process ===');
    print('Test 1: Validating form');
    if (!_formKey.currentState!.validate()) {
      print('Test 1.1: Form validation failed');
      return;
    }

    print('Test 2: Checking terms acceptance');
    if (!_acceptTerms) {
      print('Test 2.1: Terms not accepted');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the Terms and Conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Test 3: Setting loading state');
    setState(() {
      _isLoading = true;
    });

    try {
      print('Test 4: Calling login API');
      print('Phone: ${_mobileController.text}');
      final response = await _apiService.login(
        _mobileController.text,
        _passwordController.text,
      );
      print('Test 5: Login API response: ${response['status']}');

      if (response['status'] == 200) {
        print('Test 6: Login successful, navigating to OTP verification');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: _mobileController.text,
              ),
            ),
          );
        }
      } else {
        print('Test 7: Login failed with status: ${response['status']}');
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e, stackTrace) {
      print('\n=== Error in Login Process ===');
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
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } finally {
      print('Test 8: Resetting loading state');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHome() async {
    print('\n=== Navigating to Home ===');
    print('Test 1: Preparing navigation');

    try {
      print('Test 2: Fetching user data and cases');
      final userResponse = await _apiService.getUserData();
      final casesResponse = await _apiService.getCases();

      if (userResponse['status'] == 200 && casesResponse['status'] == 200) {
        print('Test 3: Data fetched successfully');
        final userData = userResponse['userData'][0];
        final cases = casesResponse['cases'];
        final count = casesResponse['count'];

        // Pre-build the home screen with data
        final homeScreen = HomeScreen(
          userData: userData,
          cases: cases,
          count: count,
        );

        // Use a microtask to ensure smooth transition
        Future.microtask(() {
          if (mounted) {
            print('Test 4: Starting navigation');
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
            print('Test 5: Navigation completed');
          }
        });
      } else {
        throw Exception('Failed to fetch data');
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

  Future<void> _checkLoginStatus() async {
    try {
      print('\n=== Checking Login Status ===');
      print('Test 1: Getting access token');
      final accessToken = await _storage.read(key: 'access_token');
      print(
          'Test 2: Access token: ${accessToken != null ? 'Found' : 'Not found'}');

      if (accessToken != null) {
        print('Test 3: Access token found, calling user API');
        final userResponse = await _apiService.getUserData();
        print('Test 4: User API response received: ${userResponse['status']}');

        if (userResponse['status'] == 200) {
          print('Test 5: User data retrieved successfully');
          final userData = userResponse['userData'][0];
          print('Test 5.1: userData: $userData');
          print('Test 6: is_first_login: ${userData['is_first_login']}');
          print('Test 7: is_email_verified: ${userData['is_email_verified']}');

          if (userData['is_first_login'] == true) {
            print('Test 8: First login detected, navigating to profile update');
            if (mounted) {
              // Pre-build the profile update screen
              final profileScreen = ProfileUpdateScreen(userData: userData);

              // Use a microtask to ensure smooth transition
              Future.microtask(() {
                if (mounted) {
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
                }
              });
            }
          } else if (userData['is_email_verified'] == false) {
            print(
                'Test 9: Email not verified, navigating to email verification');
            if (mounted) {
              // Pre-build the email verification screen
              final emailVerificationScreen = EmailVerificationScreen(
                email: userData['email'] ?? '',
              );

              // Use a microtask to ensure smooth transition
              Future.microtask(() {
                if (mounted) {
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
                }
              });
            }
          } else {
            print('Test 10: User verified, navigating to home');
            if (mounted) {
              _navigateToHome();
            }
          }
        } else {
          print('Test 11: Error - User API status not 200');
          throw Exception(userResponse['message'] ?? 'Failed to get user data');
        }
      } else {
        print('Test 12: No access token found, showing login screen');
      }
    } catch (e, stackTrace) {
      print('\n=== Error in _checkLoginStatus ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('================\n');

      if (mounted) {
        // Only show error dialog for actual errors, not for normal flow
        if (e.toString().contains('Failed to get user data') ||
            e.toString().contains('Error in _checkLoginStatus')) {
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
                      _logout();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    try {
      print('\n=== Starting Logout Process ===');
      print('Test 1: Calling logout method');
      await _apiService.logout();
      print('Test 2: Logout successful, clearing token');

      if (mounted) {
        print('Test 3: Navigating to login screen');
        // Pre-build the login screen
        final loginScreen = const LoginScreen();

        // Use a microtask to ensure smooth transition
        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    loginScreen,
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
          }
        });
      }
    } catch (e, stackTrace) {
      print('\n=== Error in Logout ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('================\n');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _logout,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    print('\n=== Login Screen Initialized ===');
    print('Test 1: Checking login status');
    _checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Terms and Conditions Checkbox
                Row(
                  children: [
                    Checkbox(
                      value: _acceptTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _acceptTerms = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _launchTermsAndConditions,
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              const TextSpan(text: 'I accept the '),
                              TextSpan(
                                text: 'Terms and Conditions',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Login Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
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
                      : const Text('Login'),
                ),
                const SizedBox(height: 20),
                // Register and Forgot Password Links
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black),
                            children: [
                              const TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Register Now',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/forgot-password');
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('\n=== Disposing Login Screen ===');
    print('Test 1: Disposing controllers');
    _mobileController.dispose();
    _passwordController.dispose();
    print('Test 2: Calling super.dispose()');
    super.dispose();
  }
}
