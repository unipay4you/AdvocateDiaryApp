import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/profile_update_screen.dart';
import 'screens/register_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Legal Diary',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(
              userData: {},
              cases: [],
              count: {},
            ),
        '/profile-update': (context) => const ProfileUpdateScreen(userData: {}),
        '/email-verification': (context) =>
            const EmailVerificationScreen(email: ''),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    print('\n=== App Started ===');
    print('Checking authentication...');
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      print('\nChecking access token...');
      final token = await _apiService.getAccessToken();

      if (token == null) {
        print('No access token found. Navigating to login...');
        _navigateToLogin();
        return;
      }

      print('Access token found. Calling user API...');
      // Call user API to verify token
      final response = await _apiService.getUserData();

      if (response['status'] == 200) {
        print('User data retrieved successfully');
        final userData = response['userData'][0];
        print('User data: $userData');

        // Get cases data from the user API response
        final cases = response['cases'] ?? [];
        final count = response['count'] ?? {};

        if (userData['is_first_login'] == true) {
          print('First login detected, navigating to profile update');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileUpdateScreen(userData: userData),
              ),
            );
          }
        } else if (userData['is_email_verified'] == false) {
          print('Email not verified, navigating to email verification');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmailVerificationScreen(
                  email: userData['email'] ?? '',
                ),
              ),
            );
          }
        } else {
          print('User verified, navigating to home');
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userData: userData,
                  cases: cases,
                  count: count,
                ),
              ),
            );
          }
        }
      } else {
        print('Error - User API status not 200');
        _navigateToLogin();
      }
    } catch (e) {
      print('\nError in _checkAuth: $e');
      print('Navigating to login due to error...');
      _navigateToLogin();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    if (_isNavigating) return;
    _isNavigating = true;

    print('Navigating to login screen...');
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(
                      'Please wait...',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
