import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late String _currentEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentEmail = widget.email;
  }

  Future<void> _handleResendVerification(BuildContext context) async {
    print('\n=== Resending Verification Email ===');
    print('Test 1: Calling resend verification API');

    setState(() {
      _isLoading = true;
    });

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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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

  void _handleChangeEmail(BuildContext context) async {
    print('\n=== Opening Change Email Dialog ===');

    final newEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Change Email'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: newEmailController,
                    decoration: const InputDecoration(
                      labelText: 'New Email',
                      hintText: 'Enter your new email address',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop();
                    await _submitChangeEmail(newEmailController.text, context);
                  }
                },
                child: const Text('Change'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _submitChangeEmail(String newEmail, BuildContext context) async {
    print('\n=== Submitting Change Email Request ===');
    print('Test 1: New email: $newEmail');

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.changeEmail(newEmail);

      print('Test 2: Response received: ${response['status']}');
      print('Test 3: Response message: ${response['message']}');

      if (context.mounted) {
        if (response['status'] == 200) {
          setState(() {
            _currentEmail = newEmail;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(response['message'] ?? 'Email changed successfully'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear token and navigate to login
          await apiService.clearAccessToken();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to change email'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('\nError in _submitChangeEmail: $e');
      if (context.mounted) {
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
                'We have sent a verification link to:\n$_currentEmail\n\nPlease check your inbox and click on the verification link to complete your registration.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isLoading ? null : () => _handleChangeEmail(context),
                child: Text(
                  'Want to use a different email?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: _isLoading ? Colors.grey : Colors.blue[700],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _handleResendVerification(context),
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
                    : const Text('Resend Verification Email'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed:
                    _isLoading ? null : () => _handleBackToLogin(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
