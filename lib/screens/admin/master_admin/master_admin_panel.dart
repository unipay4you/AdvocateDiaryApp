import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_service.dart';
import '../../../config/app_config.dart';
import 'users_list_screen.dart';
import 'cases_list_screen.dart';
import 'courts_list_screen.dart';
import '../../acts_comparison_screen.dart';
import 'link_similar_sections_screen.dart';

class MasterAdminPanel extends StatefulWidget {
  const MasterAdminPanel({Key? key}) : super(key: key);

  @override
  State<MasterAdminPanel> createState() => _MasterAdminPanelState();
}

class _MasterAdminPanelState extends State<MasterAdminPanel> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {
    'total_users': 0,
    'total_admins': 0,
    'total_cases': 0,
    'total_courts': 0,
  };
  List<dynamic> _usersList = [];
  List<dynamic> _casesList = [];

  String _formatNumber(dynamic number) {
    if (number is String) {
      // Handle cases where number is in format "active/total"
      if (number.contains('/')) {
        final parts = number.split('/');
        final active = int.tryParse(parts[0]) ?? 0;
        final total = int.tryParse(parts[1]) ?? 0;
        return '${_formatSingleNumber(active)}/${_formatSingleNumber(total)}';
      }
      return number;
    }

    final num = int.tryParse(number.toString()) ?? 0;
    return _formatSingleNumber(num);
  }

  String _formatSingleNumber(int num) {
    if (num >= 1000) {
      final double formatted = num / 1000;
      return '${formatted.toStringAsFixed(1)}K';
    }
    return num.toString();
  }

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      print('\n=== Fetching Master Admin Dashboard Data ===');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      print('Making API call to: ${AppConfig.baseUrl}superadmin/dashboard/');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}superadmin/dashboard/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('\nParsed Response Data:');

        // Get the length of advUser list for total users count
        final advUserList = data['advUser'] as List<dynamic>? ?? [];
        _usersList = advUserList; // Store the users list
        final totalUsers = advUserList.length;

        // Count today's active users
        final today = DateTime.now();
        final activeUsers = advUserList.where((user) {
          if (user['last_login'] == null) return false;
          final lastLogin = DateTime.parse(user['last_login']);
          return lastLogin.year == today.year &&
              lastLogin.month == today.month &&
              lastLogin.day == today.day;
        }).length;

        // Count new users created today
        final newUsers = advUserList.where((user) {
          if (user['created_at'] == null) return false;
          final createdAt = DateTime.parse(user['created_at']);
          return createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day;
        }).length;

        // Get cases from nested object
        final casesList = data['cases'] as List<dynamic>? ?? [];
        _casesList = casesList; // Add this line to store cases list
        final totalCases = casesList.length;

        // Count today's cases
        final todayCases = casesList.where((case_) {
          if (case_['next_date'] == null) return false;
          final nextDate = DateTime.parse(case_['next_date']);
          return nextDate.year == today.year &&
              nextDate.month == today.month &&
              nextDate.day == today.day;
        }).length;

        // Count new cases (created today)
        final newCases = casesList.where((case_) {
          if (case_['created_at'] == null) return false;
          final createdAt = DateTime.parse(case_['created_at']);
          return createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day;
        }).length;

        // Count undated cases (cases with next_date less than today)
        int undatedCount = 0;
        for (var case_ in casesList) {
          // Skip if case is not active
          if (case_['is_active'] != true) {
            continue;
          }

          if (case_['next_date'] == null) {
            continue;
          }

          final nextDate = DateTime.parse(case_['next_date']);
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final nextDateStart =
              DateTime(nextDate.year, nextDate.month, nextDate.day);

          if (nextDateStart.isBefore(todayStart)) {
            undatedCount++;
          }
        }

        final undatedCases = undatedCount;

        // Count running cases (is_active true)
        final runningCases = casesList.where((case_) {
          return case_['is_active'] == true;
        }).length;

        // Debug section for decided and null cases
        print('\n=== Debugging Decided and Null Cases ===');
        casesList.forEach((case_) {
          if (case_['is_decided'] == true || case_['is_decided'] == null) {
            print('\nCase Details:');
            print('Petitioner: ${case_['petitioner']}');
            print('Respondent: ${case_['respondent']}');
            print('Case No: ${case_['case_no']}');
            print('Case Year: ${case_['case_year']}');
            print('Is Decided: ${case_['is_decided']}');
            print('Is Active: ${case_['is_active']}');
            print('Next Date: ${case_['next_date']}');
            print('Last Date: ${case_['last_date']}');
            print('Advocate: ${case_['advocate']?['user_name']}');
            print('Full Case Data: $case_');
          }
        });
        print('=== End Debugging Decided and Null Cases ===\n');

        // Count closed cases today (is_active false and next_date is today)
        final closedTodayCases = casesList.where((case_) {
          if (case_['is_active'] != false || case_['next_date'] == null)
            return false;
          final nextDate = DateTime.parse(case_['next_date']);
          final today = DateTime.now();
          final todayStart = DateTime(today.year, today.month, today.day);
          final nextDateStart =
              DateTime(nextDate.year, nextDate.month, nextDate.day);

          // Debug for matching cases
          if (nextDateStart.isAtSameMomentAs(todayStart)) {
            print('\n=== Debugging Closed Today Case ===');
            print('Case ID: ${case_['id']}');
            print('Petitioner: ${case_['petitioner']}');
            print('Respondent: ${case_['respondent']}');
            print('Case No: ${case_['case_no']}');
            print('Case Year: ${case_['case_year']}');
            print('Is Active: ${case_['is_active']}');
            print('Is Decided: ${case_['is_decided']}');
            print('Next Date: ${case_['next_date']}');
            print('Last Date: ${case_['last_date']}');
            print('Advocate: ${case_['advocate']?['user_name']}');
          }

          return nextDateStart.isAtSameMomentAs(todayStart);
        }).length;

        print('Total Users: $totalUsers');
        print('Active Users Today: $activeUsers');
        print('New Users Today: $newUsers');
        print('Total Cases: $totalCases');
        print('Today Cases: $todayCases');
        print('New Cases Today: $newCases');
        print('Undated Cases: $undatedCases');
        print('Running Cases: $runningCases');
        print('Closed Cases Today: $closedTodayCases');
        print('Total Admins: ${data['total_admins']}');
        print('Total Courts: ${data['total_courts']}');

        setState(() {
          _stats = {
            'total_users': '$activeUsers/$totalUsers', // Format: Active/Total
            'total_admins': data['total_admins'] ?? 0,
            'total_cases': '$todayCases/$totalCases', // Format: Today/Total
            'total_courts': data['total_courts'] ?? 0,
            'new_cases': newCases,
            'running_cases': runningCases,
            'closed_today_cases': closedTodayCases,
            'undated_cases': undatedCases,
            'new_users': newUsers,
            'active_users': activeUsers,
          };
          _isLoading = false;
        });
        print('=== Dashboard Data Updated Successfully ===\n');
      } else {
        print('Error: API returned status code ${response.statusCode}');
        throw Exception('Failed to load stats');
      }
    } catch (e) {
      print('\n=== Error in _fetchStats ===');
      print('Error details: $e');
      print('=== End Error Log ===\n');
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
        title: const Text(
          'Master Admin Panel',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Overview
                    const Text(
                      'Legal Diary Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _buildStatCard(
                          'Active / Total Users',
                          _stats['total_users'].toString(),
                          Icons.people,
                          const Color.fromRGBO(123, 109, 217, 1),
                        ),
                        const SizedBox(height: 16),
                        _buildStatCard(
                          'Today / Total Cases',
                          _stats['total_cases'].toString(),
                          Icons.gavel,
                          const Color.fromRGBO(255, 152, 0, 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildActionCard(
                          'Manage Courts',
                          Icons.account_balance,
                          const Color.fromRGBO(255, 152, 0, 1),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CourtsListScreen(),
                              ),
                            );
                          },
                        ),
                        _buildActionCard(
                          'System Settings',
                          Icons.settings,
                          const Color.fromRGBO(233, 30, 99, 1),
                          () {
                            // TODO: Navigate to system settings
                          },
                        ),
                        _buildActionCard(
                          'Link Similar Sections',
                          Icons.link,
                          const Color.fromRGBO(123, 109, 217, 1),
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const LinkSimilarSectionsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Recent Activity
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 5, // TODO: Replace with actual activity data
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color.fromRGBO(123, 109, 217, 1),
                              child: Icon(
                                _getActivityIcon(index),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              _getActivityTitle(index),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(_getActivitySubtitle(index)),
                            trailing: Text(
                              _getActivityTime(index),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    if (title == 'Today / Total Cases') {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatNumber(value),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    color: color,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CasesListScreen(
                            cases: _casesList,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCaseDetail(
                      'New Cases', _formatNumber(_stats['new_cases']), color),
                  _buildCaseDetail(
                      'Undated', _formatNumber(_stats['undated_cases']), color),
                  _buildCaseDetail(
                      'Running', _formatNumber(_stats['running_cases']), color),
                  _buildCaseDetail('Closed Today',
                      _formatNumber(_stats['closed_today_cases']), color),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (title == 'Active / Total Users') {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.1),
                    child: Icon(icon, color: color),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatNumber(value),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    color: color,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UsersListScreen(
                            users: _usersList,
                            cases: _casesList,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCaseDetail('New Users Today',
                      _formatNumber(_stats['new_users']), color),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatNumber(value),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 20),
              color: color,
              onPressed: () {
                // TODO: Add navigation logic based on card type
                switch (title) {
                  case 'Total Admins':
                    // Navigate to admins screen
                    break;
                  case 'Total Courts':
                    // Navigate to courts screen
                    break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(int index) {
    final icons = [
      Icons.person_add,
      Icons.admin_panel_settings,
      Icons.gavel,
      Icons.settings,
      Icons.security,
    ];
    return icons[index % icons.length];
  }

  String _getActivityTitle(int index) {
    final titles = [
      'New User Registered',
      'Admin Access Granted',
      'New Case Added',
      'System Settings Updated',
      'Security Alert',
    ];
    return titles[index % titles.length];
  }

  String _getActivitySubtitle(int index) {
    final subtitles = [
      'John Doe joined the platform',
      'Sarah Smith was granted admin access',
      'Case #1234 was added to the system',
      'System maintenance completed',
      'Unusual login attempt detected',
    ];
    return subtitles[index % subtitles.length];
  }

  String _getActivityTime(int index) {
    final times = [
      '2 mins ago',
      '15 mins ago',
      '1 hour ago',
      '2 hours ago',
      '1 day ago',
    ];
    return times[index % times.length];
  }
}
