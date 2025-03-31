import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatelessWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  Future<void> _handleResendVerification(BuildContext context) async {
    print('\n=== Resending Verification Email ===');
    print('Test 1: Calling resend verification API');

    try {
      final apiService = ApiService();
      final response = await apiService.resendVerificationEmail();

      print('Test 2: Response received: ${response['status']}');
      print('Test 3: Response message: ${response['message']}');

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(response['status'] == 200 ? 'Success' : 'Error'),
              content: Text(response['message'] ?? 'An error occurred'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (response['status'] == 200) {
                      _handleBackToLogin(context);
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('\nError in _handleResendVerification: $e');
      if (context.mounted) {
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
    }
  }

  void _handleBackToLogin(BuildContext context) async {
    print('\n=== Handling Back to Login ===');
    print('Test 1: Clearing access token');

    // Clear the access token
    final apiService = ApiService();
    await apiService.clearAccessToken();

    print('Test 2: Token cleared, navigating to login');

    // Pre-build the login screen
    final loginScreen = const LoginScreen();

    // Use a microtask to ensure smooth transition
    Future.microtask(() {
      if (context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                'We have sent a verification link to:\n$email\n\nPlease check your inbox and click on the verification link to complete your registration.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _handleResendVerification(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _handleBackToLogin(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
