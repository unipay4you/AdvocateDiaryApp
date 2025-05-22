import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import 'user_detail_screen.dart';

class UsersListScreen extends StatefulWidget {
  final List<dynamic> users;

  const UsersListScreen({
    Key? key,
    required this.users,
  }) : super(key: key);

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  late List<dynamic> _users;
  late List<dynamic> _filteredUsers;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _users = widget.users;
    _filteredUsers = _users;
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          final searchLower = query.toLowerCase();

          // Search through all fields in the user object
          return user.entries.any((entry) {
            if (entry.value == null) return false;

            // Convert the value to string and search
            final value = entry.value.toString().toLowerCase();
            return value.contains(searchLower);
          });
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Users List',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(123, 109, 217, 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredUsers.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterUsers('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _filterUsers,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement filter by status
                        },
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Filter'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement sort options
                        },
                        icon: const Icon(Icons.sort),
                        label: const Text('Sort'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final user = _filteredUsers[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: user['user_profile_image'] != null
                        ? CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromRGBO(123, 109, 217, 1)
                                    .withOpacity(0.1),
                            backgroundImage: NetworkImage(
                                'http://192.168.1.2:8000${user['user_profile_image']}'),
                            onBackgroundImageError: (exception, stackTrace) {
                              if (user['phone_number'] == '7611999997') {
                                print(
                                    '\n=== Image Path for User 7611999997 ===');
                                print('User Name: ${user['user_name']}');
                                print(
                                    'Image Path: ${user['user_profile_image']}');
                                print(
                                    'Full URL: http://192.168.1.2:8000${user['user_profile_image']}');
                                print('Error: $exception');
                                print('=== End Image Path Debug ===\n');
                              }
                            },
                          )
                        : CircleAvatar(
                            radius: 30,
                            backgroundColor:
                                const Color.fromRGBO(123, 109, 217, 1)
                                    .withOpacity(0.1),
                            child: const Icon(
                              Icons.person,
                              color: Color.fromRGBO(123, 109, 217, 1),
                            ),
                          ),
                    title: Text(
                      user['user_name'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Email: ${user['email'] ?? 'No Email'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: ${user['phone_number'] ?? 'No Phone'}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${user['user_state']?['state'] ?? 'No State'}, ${user['user_district']?['district'] ?? 'No District'}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_android,
                              size: 16,
                              color: user['is_phone_number_verified'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Phone ${user['is_phone_number_verified'] == true ? 'Verified' : 'Not Verified'}',
                              style: TextStyle(
                                color: user['is_phone_number_verified'] == true
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: 16,
                              color: user['is_email_verified'] == true
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Email ${user['is_email_verified'] == true ? 'Verified' : 'Not Verified'}',
                              style: TextStyle(
                                color: user['is_email_verified'] == true
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 20),
                      color: const Color.fromRGBO(123, 109, 217, 1),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserDetailScreen(
                              user: user,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
