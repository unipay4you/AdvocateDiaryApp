import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import '../config/app_config.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final List<dynamic> cases;
  final Map<String, dynamic> count;

  const HomeScreen({
    Key? key,
    required this.userData,
    required this.cases,
    required this.count,
  }) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    print('\n=== Starting Logout Process ===');
    print('Test 1: Calling logout method');

    try {
      final apiService = ApiService();
      await apiService.logout();
      print('Test 2: Logout successful, clearing token');

      if (context.mounted) {
        print('Test 3: Navigating to login screen');
        final loginScreen = const LoginScreen();
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
    } catch (e, stackTrace) {
      print('\n=== Error in Logout ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('================\n');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _handleLogout(context),
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  String _getProfileImageUrl(String? profileImage) {
    print('\n=== Profile Image URL Debug ===');
    print('Test 1: Input profileImage: $profileImage');

    if (profileImage == null || profileImage.isEmpty) {
      print('Test 2: Profile image is null or empty, returning empty string');
      return '';
    }

    // Construct URL using mediaUrl
    final fullUrl = '${AppConfig.mediaUrl}$profileImage';
    print('Test 3: Media URL: ${AppConfig.mediaUrl}');
    print('Test 4: Final constructed URL: $fullUrl');
    print('=== End Profile Image URL Debug ===\n');

    return fullUrl;
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    print('\n=== Home Screen Build Started ===');
    print('Test 1: User Data:');
    print('  - User Type: ${userData['user_type']}');
    print('  - User Name: ${userData['user_name']}');
    print(
        '  - Registration Number: ${userData['advocate_registration_number']}');
    print('  - Profile Image: ${userData['user_profile_image']}');

    print('\nTest 2: Cases Count:');
    print('  - Total Cases: ${count['total_case']}');
    print('  - Today Cases: ${count['today_cases']}');
    print('  - Tomorrow Cases: ${count['tommarow_cases']}');
    print('  - Date Awaited Cases: ${count['date_awaited_case']}');

    print('\nTest 3: Cases Data:');
    print('  - Number of Cases: ${cases.length}');
    for (var i = 0; i < cases.length; i++) {
      print('  Case ${i + 1}:');
      print('    - Type: ${cases[i]['case_type']['case_type']}');
      print('    - Number: ${cases[i]['case_no']}/${cases[i]['case_year']}');
      print('    - Petitioner: ${cases[i]['petitioner']}');
      print('    - Respondent: ${cases[i]['respondent']}');
      print('    - Next Date: ${cases[i]['next_date']}');
      print('    - Stage: ${cases[i]['stage_of_case']['stage_of_case']}');
    }

    print('\nTest 4: Initializing carousel images');
    final List<String> carouselImages = [
      'assets/images/legal1.jpg',
      'assets/images/legal2.jpg',
      'assets/images/legal3.jpg',
    ];
    print('  Carousel Images: $carouselImages');

    print('\nTest 5: Initializing round buttons');
    final List<Map<String, dynamic>> roundButtons = [
      {
        'icon': Icons.search,
        'label': 'Search',
        'color': const Color(0xFF7C4DFF)
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Calendar',
        'color': const Color(0xFF00BCD4)
      },
      {
        'icon': Icons.people,
        'label': 'Clients',
        'color': const Color(0xFF4CAF50)
      },
      {
        'icon': Icons.person,
        'label': 'Users',
        'color': const Color(0xFFFF9800)
      },
      {
        'icon': Icons.assessment,
        'label': 'Reports',
        'color': const Color(0xFFE91E63)
      },
    ];
    print('  Round Buttons: ${roundButtons.map((b) => b['label']).join(', ')}');

    print('\nTest 6: Initializing case containers');
    final List<Map<String, dynamic>> caseContainers = [
      {
        'title': "Today's Cases",
        'count': count['today_cases'].toString(),
        'color': const Color(0xFF7C4DFF),
        'icon': Icons.gavel,
        'subtitle': 'Active Cases',
        'gradient': [
          const Color.fromRGBO(235, 235, 234, 1),
          const Color.fromRGBO(235, 235, 234, 1)
        ]
      },
      {
        'title': 'Tomorrow Cases',
        'count': count['tommarow_cases'].toString(),
        'color': const Color(0xFF00BCD4),
        'icon': Icons.calendar_today,
        'subtitle': 'Scheduled',
        'gradient': [
          const Color.fromRGBO(235, 235, 234, 1),
          const Color.fromRGBO(235, 235, 234, 1)
        ]
      },
      {
        'title': 'All Cases',
        'count': count['total_case'].toString(),
        'color': const Color(0xFF4CAF50),
        'icon': Icons.folder,
        'subtitle': 'Total Cases',
        'gradient': [
          const Color.fromRGBO(235, 235, 234, 1),
          const Color.fromRGBO(235, 235, 234, 1)
        ]
      },
      {
        'title': 'Date Awaited Case',
        'count': count['date_awaited_case'].toString(),
        'color': const Color(0xFFFF9800),
        'icon': Icons.event_note,
        'subtitle': 'Pending Dates',
        'gradient': [
          const Color.fromRGBO(235, 235, 234, 1),
          const Color.fromRGBO(235, 235, 234, 1)
        ]
      },
    ];
    print(
        '  Case Containers: ${caseContainers.map((c) => c['title']).join(', ')}');

    print('\nTest 7: Building main scaffold');
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'My Legal Diary',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              print('Test 8: Drawer button pressed');
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              print('Test 8: Notifications button pressed');
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromRGBO(235, 235, 234, 1),
                    const Color.fromRGBO(235, 235, 234, 1)
                  ],
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/legal_bg.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                      backgroundImage: userData['user_profile_image'] != null
                          ? NetworkImage(_getProfileImageUrl(
                              userData['user_profile_image']))
                          : null,
                      child: userData['user_profile_image'] == null
                          ? const Icon(Icons.person,
                              size: 35, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      _capitalizeFirstLetter(userData['user_type']),
                      style: const TextStyle(color: Colors.black, fontSize: 18),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      _capitalizeFirstLetter(userData['user_name']),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      _capitalizeFirstLetter(
                          userData['advocate_registration_number'] ?? ''),
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black),
              title: const Text('Home', style: TextStyle(color: Colors.black)),
              onTap: () {
                print('Test 9: Home menu item tapped');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title:
                  const Text('Profile', style: TextStyle(color: Colors.black)),
              onTap: () {
                print('Test 10: Profile menu item tapped');
                // TODO: Navigate to profile
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.black),
              title:
                  const Text('Settings', style: TextStyle(color: Colors.black)),
              onTap: () {
                print('Test 11: Settings menu item tapped');
                // TODO: Navigate to settings
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.black),
              title:
                  const Text('Logout', style: TextStyle(color: Colors.black)),
              onTap: () {
                print('Test 12: Logout menu item tapped');
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color.fromRGBO(235, 235, 234, 1),
                    const Color.fromRGBO(235, 235, 234, 1)
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C4DFF).withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color.fromRGBO(235, 235, 234, 1),
                          const Color.fromRGBO(235, 235, 234, 1)
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                      backgroundImage: userData['user_profile_image'] != null
                          ? NetworkImage(_getProfileImageUrl(
                              userData['user_profile_image']))
                          : null,
                      child: userData['user_profile_image'] == null
                          ? const Icon(Icons.person,
                              size: 35, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi ${userData['user_type']}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          userData['user_name'],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (userData['advocate_registration_number'] != null)
                          Text(
                            userData['advocate_registration_number'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Carousel Slider
            FlutterCarousel(
              items: carouselImages.map((image) {
                print('Test 13: Building carousel item for $image');
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(235, 235, 234, 1),
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: AssetImage(image),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
              options: CarouselOptions(
                height: 170,
                autoPlay: true,
                enlargeCenterPage: true,
                viewportFraction: 0.8,
                autoPlayInterval: const Duration(seconds: 3),
                autoPlayAnimationDuration: const Duration(milliseconds: 800),
                autoPlayCurve: Curves.fastOutSlowIn,
              ),
            ),
            const SizedBox(height: 20),

            // Round Shape Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: roundButtons.map((button) {
                  print(
                      'Test 14: Building round button for ${button['label']}');
                  return Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color.fromRGBO(123, 109, 217, 1),
                              const Color.fromRGBO(123, 109, 217, 1),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(button['icon'], color: Colors.white),
                          onPressed: () {
                            print('Test 15: ${button['label']} button pressed');
                            // TODO: Implement button action
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        button['label'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Case Containers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: caseContainers.map((item) {
                  print(
                      'Test 16: Building case container for ${item['title']}');
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: item['gradient'],
                      ),
                      borderRadius: BorderRadius.circular(15),
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(123, 109, 217, 1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'],
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item['title'],
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['subtitle'],
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${item['count']} cases',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Active Cases List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Cases',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(235, 235, 234, 1),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: cases.asMap().entries.map((entry) {
                        final index = entry.key;
                        final caseData = entry.value;
                        // Determine which party should be bold based on client_type
                        final isPetitioner =
                            caseData['client_type']?.toString().toLowerCase() ==
                                'petitioner';
                        final petitionerStyle = TextStyle(
                          fontWeight: isPetitioner
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        );
                        final respondentStyle = TextStyle(
                          fontWeight: !isPetitioner
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        );

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(235, 235, 234, 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Leading icon
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color.fromRGBO(
                                            123, 109, 217, 1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.gavel,
                                          color: Colors.white, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Line 1: Petitioner vs Respondent with conditional bold
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  caseData['petitioner'] ?? '',
                                                  style: petitionerStyle,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Text(' vs '),
                                              Expanded(
                                                child: Text(
                                                  caseData['respondent'] ?? '',
                                                  style: respondentStyle,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Line 2: Case number and year
                                          Text(
                                            '#${caseData['case_no']}/${caseData['case_year']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          // Line 3: Court number and Reference (darker text)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Court No: ${caseData['court_no']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Ref: ${caseData['sub_advocate'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          // Line 4: Stage of case
                                          Text(
                                            caseData['stage_of_case']
                                                    ['stage_of_case'] ??
                                                '',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 8),
                                          // Line 5: Last date and Next date (darker text for Last date)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Last: ${caseData['last_date'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Next: ${caseData['next_date'] ?? 'N/A'}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black87,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < cases.length - 1)
                              const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
        onPressed: () {
          print('Test 17: Floating action button pressed');
          showDialog(
            context: context,
            builder: (BuildContext context) {
              print('Test 18: Building Add New dialog');
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(235, 235, 234, 1),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Add New',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildActionButton(
                            context,
                            Icons.gavel,
                            'New Case',
                            const Color.fromRGBO(123, 109, 217, 1),
                            () {
                              print('Test 19: New Case button pressed');
                              Navigator.pop(context);
                              // TODO: Navigate to add case screen
                            },
                          ),
                          _buildActionButton(
                            context,
                            Icons.person_add,
                            'New Client',
                            const Color.fromRGBO(123, 109, 217, 1),
                            () {
                              print('Test 20: New Client button pressed');
                              Navigator.pop(context);
                              // TODO: Navigate to add client screen
                            },
                          ),
                          _buildActionButton(
                            context,
                            Icons.note_add,
                            'New Document',
                            const Color.fromRGBO(123, 109, 217, 1),
                            () {
                              print('Test 21: New Document button pressed');
                              Navigator.pop(context);
                              // TODO: Navigate to add document screen
                            },
                          ),
                          _buildActionButton(
                            context,
                            Icons.event,
                            'New Event',
                            const Color.fromRGBO(123, 109, 217, 1),
                            () {
                              print('Test 22: New Event button pressed');
                              Navigator.pop(context);
                              // TODO: Navigate to add event screen
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          print('Test 23: Cancel button pressed');
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    print('Test 24: Building action button for $label');
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromRGBO(235, 235, 234, 1),
              const Color.fromRGBO(235, 235, 234, 1),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(123, 109, 217, 1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cases.length,
      itemBuilder: (context, index) {
        final caseData = cases[index];
        print('\n=== Building Case List Item ===');
        print('Test 1: Case Data:');
        print('  - ID: ${caseData['id']}');
        print('  - Petitioner: ${caseData['petitioner']}');
        print('  - Respondent: ${caseData['respondent']}');
        print('  - Client Type: ${caseData['client_type']}');
        print(
            '  - Case Number: ${caseData['case_no']}/${caseData['case_year']}');
        print('  - Court Number: ${caseData['court_no']}');
        print('  - Stage: ${caseData['stage_of_case']['stage_of_case']}');
        print('  - Sub Advocate: ${caseData['sub_advocate']}');
        print('  - Last Date: ${caseData['last_date']}');
        print('  - Next Date: ${caseData['next_date']}');

        // Determine which party should be bold based on client_type
        final isPetitioner =
            caseData['client_type']?.toString().toLowerCase() == 'petitioner';
        final petitionerStyle = TextStyle(
          fontWeight: isPetitioner ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        );
        final respondentStyle = TextStyle(
          fontWeight: !isPetitioner ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        );

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            onTap: () {
              print('Test 2: Case tapped - ID: ${caseData['id']}');
              // TODO: Navigate to case detail screen with case ID
            },
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Line 1: Petitioner vs Respondent with conditional bold
                Row(
                  children: [
                    Text(
                      caseData['petitioner'] ?? '',
                      style: petitionerStyle,
                    ),
                    const Text(' vs '),
                    Text(
                      caseData['respondent'] ?? '',
                      style: respondentStyle,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Line 2: Case number and year
                Text(
                  '#${caseData['case_no']}/${caseData['case_year']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                // Line 3: Court number and Reference
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Court No: ${caseData['court_no']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Ref: ${caseData['sub_advocate'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Line 4: Stage of case
                Text(
                  caseData['stage_of_case']['stage_of_case'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                // Line 5: Last date and Next date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last: ${caseData['last_date'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Next: ${caseData['next_date'] ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
