import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_service.dart';
import '../../../config/app_config.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final List<dynamic> cases;

  const UserDetailScreen({
    Key? key,
    required this.user,
    required this.cases,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final apiService = ApiService();
      final userResponse = await apiService.getUserData();
      if (userResponse['status'] == 200) {
        setState(() {
          _currentUser = userResponse['userData'][0];
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  bool get _isCurrentUser {
    return _currentUser != null && _currentUser!['id'] == widget.user['id'];
  }

  int get _activeCasesCount {
    return widget.cases.where((case_) {
      return case_['is_active'] == true &&
          case_['advocate']?['id']?.toString() == widget.user['id'].toString();
    }).length;
  }

  Future<void> _resetPassword() async {
    if (_isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot reset your own password from this screen'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text(
              'Are you sure you want to reset the password for this user? A reset link will be sent to their email.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Reset Password'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      final url = '${AppConfig.baseUrl}superadmin/reset-password/';
      final body = jsonEncode({
        'user_id': widget.user['id'],
      });

      print('Reset Password - URL: $url');
      print('Reset Password - Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Reset Password - Response Status: ${response.statusCode}');
      print('Reset Password - Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  'Password reset email sent successfully')),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('Reset Password - Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      final url = '${AppConfig.baseUrl}superadmin/verify-otp/';
      final body = jsonEncode({
        'user_id': widget.user['id'],
      });

      print('Verify OTP - URL: $url');
      print('Verify OTP - Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Verify OTP - Response Status: ${response.statusCode}');
      print('Verify OTP - Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 200) {
        setState(() {
          widget.user['is_phone_number_verified'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  'Phone number verified successfully')),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify OTP');
      }
    } catch (e) {
      print('Verify OTP - Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      final url = '${AppConfig.baseUrl}superadmin/verify-email/';
      final body = jsonEncode({
        'user_id': widget.user['id'],
      });

      print('Verify Email - URL: $url');
      print('Verify Email - Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Verify Email - Response Status: ${response.statusCode}');
      print('Verify Email - Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 200) {
        setState(() {
          widget.user['is_email_verified'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  responseData['message'] ?? 'Email verified successfully')),
        );
      } else {
        throw Exception(responseData['message'] ?? 'Failed to verify email');
      }
    } catch (e) {
      print('Verify Email - Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleUserStatus() async {
    if (_isCurrentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot deactivate your own account'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool isActive = widget.user['is_active'] == true;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isActive ? 'Deactivate User' : 'Activate User'),
          content: Text(isActive
              ? 'Are you sure you want to deactivate this user? They will not be able to access the system.'
              : 'Are you sure you want to activate this user? They will be able to access the system.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.red : Colors.green,
              ),
              child: Text(isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      final url = '${AppConfig.baseUrl}superadmin/toggle-status/';
      final body = jsonEncode({
        'user_id': widget.user['id'],
      });

      print('Toggle Status - URL: $url');
      print('Toggle Status - Request Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Toggle Status - Response Status: ${response.statusCode}');
      print('Toggle Status - Response Body: ${response.body}');

      final responseData = jsonDecode(response.body);
      if (responseData['status'] == 200) {
        setState(() {
          widget.user['is_active'] = !widget.user['is_active'];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseData['message'] ??
                  'User status updated successfully')),
        );
      } else {
        throw Exception(
            responseData['message'] ?? 'Failed to toggle user status');
      }
    } catch (e) {
      print('Toggle Status - Error: $e');
      setState(() {
        _errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Text(
          widget.user['user_name'] ?? 'User Details',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Section
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color.fromRGBO(123, 109, 217, 1)
                            .withOpacity(0.1),
                        backgroundImage: widget.user['user_profile_image'] !=
                                null
                            ? NetworkImage(
                                '${AppConfig.mediaUrl}${widget.user['user_profile_image']}')
                            : null,
                        child: widget.user['user_profile_image'] == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Color.fromRGBO(123, 109, 217, 1),
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.user['user_name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Admin Actions Section
                _buildSectionTitle('Admin Actions'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminActionCard(
                        title: 'Reset Password',
                        icon: Icons.lock_reset,
                        color: _isCurrentUser ? Colors.grey : Colors.orange,
                        onTap: _isCurrentUser ? null : _resetPassword,
                        isDisabled: _isCurrentUser,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAdminActionCard(
                        title: widget.user['is_active'] == true
                            ? 'Deactivate User'
                            : 'Activate User',
                        icon: widget.user['is_active'] == true
                            ? Icons.block
                            : Icons.check_circle,
                        color: _isCurrentUser
                            ? Colors.grey
                            : (widget.user['is_active'] == true
                                ? Colors.red
                                : Colors.green),
                        onTap: _isCurrentUser ? null : _toggleUserStatus,
                        isDisabled: _isCurrentUser,
                      ),
                    ),
                  ],
                ),
                if (_isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Center(
                      child: Text(
                        'These actions are not available for your own account',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),

                // Basic Information
                _buildSectionTitle('Basic Information'),
                _buildInfoCard([
                  _buildInfoRow(
                      'User ID', widget.user['id']?.toString() ?? 'N/A'),
                  _buildInfoRow('Name', widget.user['user_name'] ?? 'No Name'),
                  _buildInfoRow('Email', widget.user['email'] ?? 'No Email'),
                  _buildInfoRow(
                      'Phone', widget.user['phone_number'] ?? 'No Phone'),
                  _buildInfoRow(
                      'User Type', widget.user['user_type'] ?? 'Not Specified'),
                ]),
                const SizedBox(height: 24),

                // Professional Information
                _buildSectionTitle('Professional Information'),
                _buildInfoCard([
                  _buildInfoRow(
                      'Adv Reg. No.',
                      widget.user['advocate_registration_number'] ??
                          'Not Available'),
                  _buildInfoRow(
                      'Under Advocate',
                      widget.user['user_under_which_advocate'] ??
                          'Not Available'),
                ]),
                const SizedBox(height: 24),

                // Location Information
                _buildSectionTitle('Location Information'),
                _buildInfoCard([
                  _buildInfoRow('State',
                      widget.user['user_state']?['state'] ?? 'No State'),
                  _buildInfoRow(
                      'District',
                      widget.user['user_district']?['district'] ??
                          'No District'),
                ]),
                const SizedBox(height: 24),

                // Verification Status
                _buildSectionTitle('Verification Status'),
                _buildInfoCard([
                  Row(
                    children: [
                      Expanded(
                        child: _buildVerificationRow(
                          'Phone',
                          widget.user['is_phone_number_verified'] == true,
                          onVerify: _verifyOTP,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVerificationRow(
                          'Email',
                          widget.user['is_email_verified'] == true,
                          onVerify: _verifyEmail,
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 24),

                // Account Information
                _buildSectionTitle('Account Information'),
                _buildInfoCard([
                  _buildInfoRow(
                      'Created At',
                      widget.user['created_at'] != null
                          ? DateTime.parse(widget.user['created_at'])
                              .toString()
                              .split('.')[0]
                          : 'Not Available'),
                  _buildInfoRow(
                      'Last Login',
                      widget.user['last_login'] != null
                          ? DateTime.parse(widget.user['last_login'])
                              .toString()
                              .split('.')[0]
                          : 'Never'),
                  _buildInfoRow('Status',
                      widget.user['is_active'] == true ? 'Active' : 'Inactive'),
                  _buildInfoRow(
                      'Date of Birth',
                      widget.user['user_dob'] != null
                          ? DateTime.parse(widget.user['user_dob'])
                              .toString()
                              .split(' ')[0]
                          : 'Not Available'),
                  _buildInfoRow(
                    'Active Cases',
                    _activeCasesCount.toString(),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color.fromRGBO(123, 109, 217, 1),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationRow(String label, bool isVerified,
      {VoidCallback? onVerify}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVerified ? Icons.check_circle : Icons.cancel,
              color: isVerified ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              isVerified ? 'Verified' : 'Not Verified',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isVerified ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        if (!isVerified && onVerify != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: onVerify,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Verify',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdminActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool isDisabled = false,
  }) {
    return Card(
      elevation: isDisabled ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isDisabled ? 0.05 : 0.1),
                color.withOpacity(isDisabled ? 0.1 : 0.2),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 32,
                color: color.withOpacity(isDisabled ? 0.5 : 1.0),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(isDisabled ? 0.5 : 1.0),
                ),
              ),
              if (isDisabled) ...[
                const SizedBox(height: 4),
                const Text(
                  '(Not available for self)',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
