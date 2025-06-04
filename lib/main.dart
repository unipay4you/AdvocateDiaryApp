import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/profile_update_screen.dart';
import 'screens/register_screen.dart';
import 'screens/otp_verification_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/admin/master_admin/master_admin_panel.dart';
import 'screens/admin/admin_panel.dart';
import 'services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'My Legal Diary',
      debugShowCheckedModeBanner: false,
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
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/change-password': (context) =>
            const ChangePasswordScreen(phoneNumber: ''),
        '/home': (context) => const HomeScreen(
              userData: {},
              cases: [],
              count: {},
            ),
        '/profile-update': (context) => const ProfileUpdateScreen(userData: {}),
        '/email-verification': (context) =>
            const EmailVerificationScreen(email: ''),
        '/otp-verification': (context) => const OtpVerificationScreen(
              phoneNumber: '',
              accessToken: '',
            ),
        '/master-admin': (context) => const MasterAdminPanel(),
        '/admin': (context) => const AdminPanel(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class DownloadPage extends StatelessWidget {
  final String apkUrl;
  final String currentVersion;
  final String newVersion;

  DownloadPage({
    required this.apkUrl,
    required this.currentVersion,
    required this.newVersion,
  });

  Future<void> _launchDownload() async {
    try {
      // Try to open in browser using a simple intent
      final Uri browserUri =
          Uri.parse('market://details?id=com.android.chrome');
      if (await canLaunchUrl(browserUri)) {
        // If Chrome is installed, open the URL in Chrome
        final Uri downloadUri = Uri.parse(apkUrl);
        await launchUrl(
          downloadUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // If Chrome is not installed, try to open in any browser
        final Uri downloadUri = Uri.parse(apkUrl);
        await launchUrl(
          downloadUri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      debugPrint('Error launching download: $e');
      if (navigatorKey.currentContext != null) {
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(
            content: Text('Error downloading update: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Available'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'New Version Available',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Version:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          currentVersion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'New Version:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          newVersion,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _launchDownload,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  'Download Update',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _apiService = ApiService();
  bool _isLoading = true;
  bool _isNavigating = false;
  late BuildContext _context;

  @override
  void initState() {
    super.initState();
    print('\n=== App Started ===');
    print('Checking authentication...');
    _checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
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

  void _navigateToLogin() {
    if (_isNavigating) return;
    _isNavigating = true;

    print('Navigating to login screen...');
    if (mounted) {
      Navigator.of(_context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  Future<void> _checkAuth() async {
    try {
      print('\nChecking app version first...');
      bool shouldProceedWithAuth = true;

      // Check app version first
      try {
        final versionResponse = await http.get(
          Uri.parse('${AppConfig.baseUrl}version/'),
          headers: {
            'Content-Type': 'application/json',
          },
        );

        print('\n=== Version Check API Response ===');
        print('Status Code: ${versionResponse.statusCode}');
        print('Response Body: ${versionResponse.body}');
        print('=== End Version Check API Response ===\n');

        if (versionResponse.statusCode == 200) {
          final versionData = json.decode(versionResponse.body);
          print('Raw Version Data: $versionData');

          final serverVersion =
              versionData['version']['version']?.toString() ?? '';
          final appFile = versionData['version']['app_file']?.toString() ?? '';

          print('Server Version: $serverVersion');
          print('Current App Version: ${AppConfig.appVersion}');
          print('App File Path: $appFile');

          if (serverVersion.isNotEmpty &&
              serverVersion != AppConfig.appVersion) {
            if (mounted) {
              Navigator.pushReplacement(
                _context,
                MaterialPageRoute(
                  builder: (context) => DownloadPage(
                    apkUrl: '${AppConfig.baseAPI}$appFile',
                    currentVersion: AppConfig.appVersion,
                    newVersion: serverVersion,
                  ),
                ),
              );
              return;
            }
          } else {
            // Versions match, proceed with auth
            shouldProceedWithAuth = true;
          }
        }
      } catch (e) {
        print('Error checking version: $e');
        shouldProceedWithAuth = true; // Proceed with auth on error
      }

      // Only proceed with authentication if we should
      if (shouldProceedWithAuth) {
        print('\nChecking access token...');
        final token = await _apiService.getAccessToken();

        if (token == null) {
          print('No access token found. Navigating to login...');
          _navigateToLogin();
          return;
        }

        print('Calling user API...');
        final response = await _apiService.getUserData();

        if (response['status'] == 200) {
          print('User data retrieved successfully');
          final userData = response['userData'][0];
          print('User data: $userData');

          // Get cases data from the user API response
          final cases = response['cases'] ?? [];
          final count = response['count'] ?? {};

          // Check conditions in priority order
          if (userData['is_phone_number_verified'] == false) {
            print('Phone not verified, navigating to OTP verification');
            if (mounted) {
              Navigator.pushReplacement(
                _context,
                MaterialPageRoute(
                  builder: (context) => OtpVerificationScreen(
                    phoneNumber: userData['phone_number'] ?? '',
                    accessToken: token,
                  ),
                ),
              );
            }
          } else if (userData['is_email_verified'] == false) {
            print('Email not verified, navigating to email verification');
            if (mounted) {
              Navigator.pushReplacement(
                _context,
                MaterialPageRoute(
                  builder: (context) => EmailVerificationScreen(
                    email: userData['email'] ?? '',
                  ),
                ),
              );
            }
          } else if (userData['is_first_login'] == true) {
            print('First login detected, navigating to profile update');
            if (mounted) {
              Navigator.pushReplacement(
                _context,
                MaterialPageRoute(
                  builder: (context) => ProfileUpdateScreen(userData: userData),
                ),
              );
            }
          } else {
            print('All verifications complete, navigating to home');
            if (mounted) {
              Navigator.pushReplacement(
                _context,
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
}
