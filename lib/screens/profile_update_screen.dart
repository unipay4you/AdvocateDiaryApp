import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../config/app_config.dart';
import '../screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ProfileUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileUpdateScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  _ProfileUpdateScreenState createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  String? _selectedState;
  String? _selectedDistrict;
  List<Map<String, dynamic>> _districtsData = [];
  List<String> _uniqueStates = [];
  List<String> _filteredDistricts = [];

  // Controllers for all fields
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _address3Controller = TextEditingController();
  final _pincodeController = TextEditingController();
  final _advocateRegController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Show loading indicator while data is being set
    setState(() {
      _isLoading = true;
    });

    // First load districts data
    _loadDistricts().then((_) {
      // After districts are loaded, set user data
      _setUserData();
      // Hide loading indicator after all data is set
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  void _setUserData() {
    print('\n=== Setting User Data from OTP Verification ===');
    final userData = widget.userData;

    // Set profile image
    if (userData['user_profile_image'] != null) {
      print('Setting profile image');
      _apiService.userProfileImage =
          '${AppConfig.mediaUrl}${userData['user_profile_image']}';
    }

    // Set values to controllers with null/empty handling
    print('Setting controller values');
    _phoneController.text = userData['phone_number']?.toString() ?? '';
    _emailController.text = userData['email']?.toString() ?? '';
    _nameController.text = userData['user_name']?.toString() ?? '';
    _dobController.text = userData['user_dob']?.toString() ?? '';
    _address1Controller.text = userData['user_address1']?.toString() ?? '';
    _address2Controller.text = userData['user_address2']?.toString() ?? '';
    _address3Controller.text = userData['user_address3']?.toString() ?? '';
    _pincodeController.text =
        userData['user_district_pincode']?.toString() ?? '';
    _advocateRegController.text =
        userData['advocate_registration_number']?.toString() ?? '';

    print('All data set successfully');
    print('Loaded user data:');
    print('Phone: ${_phoneController.text}');
    print('Email: ${_emailController.text}');
    print('Name: ${_nameController.text}');
    print('DOB: ${_dobController.text}');
    print('Address1: ${_address1Controller.text}');
    print('Address2: ${_address2Controller.text}');
    print('Address3: ${_address3Controller.text}');
    print('Pincode: ${_pincodeController.text}');
    print('Registration: ${_advocateRegController.text}');
  }

  Future<void> _loadDistricts() async {
    try {
      print('\n=== Loading Districts Data ===');
      print('Test 1: Getting districts from API');
      final response = await _apiService.getDistricts();

      if (response['status'] == 200) {
        print('Test 2: Districts data received successfully');
        setState(() {
          _districtsData = List<Map<String, dynamic>>.from(response['payload']);
          _uniqueStates = _districtsData
              .map((item) => item['state']['state'] as String)
              .toSet()
              .toList()
            ..sort();
          print('Available states: $_uniqueStates');

          // Get user data state and district
          final userData = widget.userData;
          print('Test 3: User data state and district');
          if (userData['user_state'] != null) {
            final stateData = userData['user_state'] as Map<String, dynamic>;
            final userState = stateData['state'] as String;
            print('User state from data: $userState');

            // Check if user state exists in available states
            if (_uniqueStates.contains(userState)) {
              print('User state found in available states');
              _selectedState = userState;
              _updateDistricts(_selectedState!);

              // Set district if available
              if (userData['user_district'] != null) {
                final districtData =
                    userData['user_district'] as Map<String, dynamic>;
                final userDistrict = districtData['district'] as String;
                print('User district from data: $userDistrict');

                // Check if user district exists in filtered districts
                if (_filteredDistricts.contains(userDistrict)) {
                  print('User district found in filtered districts');
                  _selectedDistrict = userDistrict;
                } else {
                  print('User district not found in filtered districts');
                }
              }
            } else {
              print('User state not found in available states');
              // Fallback to first state if user state not found
              if (_uniqueStates.isNotEmpty) {
                _selectedState = _uniqueStates.first;
                _updateDistricts(_selectedState!);
                if (_filteredDistricts.isNotEmpty) {
                  _selectedDistrict = _filteredDistricts.first;
                }
              }
            }
          } else {
            print('No user state data available');
            // Fallback to first state if no user data
            if (_uniqueStates.isNotEmpty) {
              _selectedState = _uniqueStates.first;
              _updateDistricts(_selectedState!);
              if (_filteredDistricts.isNotEmpty) {
                _selectedDistrict = _filteredDistricts.first;
              }
            }
          }

          print('Final selected state: $_selectedState');
          print('Final selected district: $_selectedDistrict');
        });
      } else {
        print('Failed to load districts data');
      }
    } catch (e) {
      print('Error loading districts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading districts: $e')),
        );
      }
    }
  }

  void _updateDistricts(String state) {
    print('Updating districts for state: $state');
    setState(() {
      _filteredDistricts = _districtsData
          .where((item) => item['state']['state'] == state)
          .map((item) => item['district'] as String)
          .toList()
        ..sort();
      print('Filtered districts: $_filteredDistricts');

      // Reset selected district when state changes
      _selectedDistrict = null;
    });
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Convert date format from DD-MM-YYYY to YYYY-MM-DD
      String formattedDob = '';
      if (_dobController.text.isNotEmpty) {
        final parts = _dobController.text.split('-');
        if (parts.length == 3) {
          formattedDob = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      final Map<String, dynamic> userData = {
        'phone_number': _phoneController.text,
        'email': _emailController.text,
        'user_name': _nameController.text,
        'user_dob': formattedDob,
        'user_address1': _address1Controller.text,
        'user_address2': _address2Controller.text,
        'user_address3': _address3Controller.text,
        'user_district_pincode': _pincodeController.text,
        'advocate_registration_number': _advocateRegController.text,
        'user_state': _selectedState,
        'user_district': _selectedDistrict,
      };

      // Handle profile image
      if (_selectedImage != null) {
        // If a new image is selected, send the File object
        userData['user_profile_image'] = _selectedImage;
      } else if (widget.userData['user_profile_image'] != null) {
        // If no new image is selected but there's an existing image, keep the existing image path
        userData['user_profile_image'] = widget.userData['user_profile_image'];
      }

      print('Sending profile update request with data:');
      print('Date of Birth (YYYY-MM-DD): $formattedDob');
      print('Other user data: $userData');

      final response = await _apiService.updateProfile(userData);

      if (mounted) {
        if (response['status'] == 200) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Success'),
                content:
                    Text(response['message'] ?? 'Profile updated successfully'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Pre-build the login screen
                      final loginScreen = const LoginScreen();

                      // Use a microtask to ensure smooth transition
                      Future.microtask(() {
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      loginScreen,
                              transitionsBuilder: (context, animation,
                                  secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                            ),
                          );
                        }
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Show the specific error message from the API response
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text(response['error'] ??
                    response['message'] ??
                    'Failed to update profile'),
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
    } catch (e) {
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      // Show options dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality:
            source == ImageSource.camera ? 30 : 50, // Lower quality for camera
        maxWidth:
            source == ImageSource.camera ? 800 : null, // Limit width for camera
        maxHeight: source == ImageSource.camera
            ? 800
            : null, // Limit height for camera
      );

      if (pickedFile != null) {
        // Check file extension
        final extension = pickedFile.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select a JPG, JPEG or PNG image'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Check file size with different limits for camera and gallery
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        final maxSize = source == ImageSource.camera
            ? 200 * 1024
            : 50 * 1024; // 200KB for camera, 50KB for gallery

        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Image size should be less than ${source == ImageSource.camera ? "200KB" : "50KB"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = file;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this method to format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  // Add this method to parse date
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
      return null;
    } catch (e) {
      print('Error parsing date: $e');
      return null;
    }
  }

  // Add this method to validate date format
  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date of Birth is required';
    }

    // Check format DD-MM-YYYY
    final RegExp dateRegExp = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!dateRegExp.hasMatch(value)) {
      return 'Please enter date in DD-MM-YYYY format';
    }

    // Try to parse the date
    final date = _parseDate(value);
    if (date == null) {
      return 'Please enter a valid date';
    }

    // Check if date is in the past
    if (date.isAfter(DateTime.now())) {
      return 'Date of Birth cannot be in the future';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Loading Profile Data...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (_apiService.userProfileImage != null
                                    ? NetworkImage(
                                        _apiService.userProfileImage!)
                                    : null) as ImageProvider?,
                            child: _selectedImage == null &&
                                    _apiService.userProfileImage == null
                                ? const Icon(Icons.person, size: 50)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Advocate Profile Section
                    const Text(
                      'Advocate Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 2. Phone Number (Read-only)
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      readOnly: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Phone number is required';
                        }
                        if (value.length != 10) {
                          return 'Phone number must be 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 3. Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // 4. Date of Birth
                    TextFormField(
                      controller: _dobController,
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (DD-MM-YYYY)',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _parseDate(_dobController.text) ??
                                  DateTime.now(),
                              firstDate: DateTime(1900),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              _dobController.text = _formatDate(date);
                            }
                          },
                        ),
                      ),
                      readOnly: false,
                      validator: _validateDate,
                      onChanged: (value) {
                        // Format the input as user types
                        if (value.length == 2 || value.length == 5) {
                          if (value.length == 2 && !value.contains('-')) {
                            _dobController.text = '$value-';
                            _dobController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: _dobController.text.length),
                            );
                          } else if (value.length == 5 &&
                              value[2] == '-' &&
                              !value.substring(3).contains('-')) {
                            _dobController.text = '$value-';
                            _dobController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: _dobController.text.length),
                            );
                          }
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 5. Advocate Registration Number
                    TextFormField(
                      controller: _advocateRegController,
                      decoration: const InputDecoration(
                        labelText: 'Advocate Registration Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Office Address Section
                    const Text(
                      'Office Address',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Address Line 1
                    TextFormField(
                      controller: _address1Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 1',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // 2. Address Line 2
                    TextFormField(
                      controller: _address2Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 2',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // 3. Address Line 3
                    TextFormField(
                      controller: _address3Controller,
                      decoration: const InputDecoration(
                        labelText: 'Address Line 3',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // State Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: _uniqueStates.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedState = newValue;
                            _updateDistricts(newValue);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // District Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: _filteredDistricts.map((String district) {
                        return DropdownMenuItem<String>(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDistrict = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // 6. Pincode
                    TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'District Pincode',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.pin_drop),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    const SizedBox(height: 30),

                    // Update Profile Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Update Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _address3Controller.dispose();
    _pincodeController.dispose();
    _advocateRegController.dispose();
    super.dispose();
  }
}
