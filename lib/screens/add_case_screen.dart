import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class AddCaseScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic> count;

  const AddCaseScreen({
    Key? key,
    required this.userData,
    required this.count,
  }) : super(key: key);

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isInitialLoading = true;
  File? _document;
  final ImagePicker _picker = ImagePicker();

  // Form fields
  final TextEditingController _crnController = TextEditingController();
  final TextEditingController _caseNoController = TextEditingController();
  final TextEditingController _caseYearController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _courtTypeController = TextEditingController();
  final TextEditingController _courtController = TextEditingController();
  final TextEditingController _underSectionController = TextEditingController();
  final TextEditingController _petitionerController = TextEditingController();
  final TextEditingController _respondentController = TextEditingController();
  final TextEditingController _firNumberController = TextEditingController();
  final TextEditingController _firYearController = TextEditingController();
  final TextEditingController _policeStationController =
      TextEditingController();
  final TextEditingController _nextDateController = TextEditingController();
  final TextEditingController _subAdvocateController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();

  String? _selectedCaseType;
  String? _selectedStageOfCase;
  String? _selectedClientType;
  String? _selectedCourt;
  String? _selectedCourtType;
  String? _selectedState;
  String? _selectedDistrict;
  List<Map<String, dynamic>> _districtsData = [];
  List<String> _uniqueStates = [];
  List<String> _filteredDistricts = [];

  List<Map<String, dynamic>> _caseTypes = [];
  List<Map<String, dynamic>> _stageOfCases = [];
  List<Map<String, dynamic>> _courts = [];
  List<Map<String, dynamic>> _courtTypes = [];

  List<int> _years = [];
  void _initializeYears() {
    final currentYear = DateTime.now().year;
    _years =
        List.generate(currentYear - 1970 + 1, (index) => currentYear - index);
  }

  @override
  void initState() {
    super.initState();
    _initializeYears();
    _loadDistricts().then((_) {
      return _fetchDropdownData();
    }).then((_) {
      if (mounted) {
        setState(() {
          isInitialLoading = false;
        });
      }
    });
  }

  Future<void> _fetchDropdownData() async {
    try {
      print('TEST 1: Starting to fetch dropdown data...');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print(
          'TEST 1.1: Token retrieved successfully: ${token != null ? token.substring(0, 10) : "null"}...');

      // Fetch case types
      print('TEST 1.2: Fetching case types...');
      final caseTypesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getcasetype/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
          'TEST 1.3: Case types response status: ${caseTypesResponse.statusCode}');
      print('TEST 1.4: Case types response body: ${caseTypesResponse.body}');

      if (caseTypesResponse.statusCode == 200) {
        print('TEST 1.5: Case types API response successful');
        setState(() {
          try {
            final responseData = json.decode(caseTypesResponse.body);
            if (responseData is List) {
              _caseTypes = List<Map<String, dynamic>>.from(responseData);
              print(
                  'TEST 1.6: Case types parsed successfully: ${_caseTypes.length} items');
              if (_caseTypes.isNotEmpty) {
                print('TEST 1.7: First case type: ${_caseTypes[0]}');
              }
            } else {
              print('TEST 1.8: Case types data is not a list');
              _caseTypes = [];
            }
          } catch (e) {
            print('TEST 1.9: Error parsing case types: $e');
            _caseTypes = [];
          }
        });
      } else {
        print('TEST 1.10: Error: Case types API response failed');
        print('TEST 1.11: Case types status: ${caseTypesResponse.statusCode}');
      }

      // Fetch case stages
      print('TEST 1.12: Fetching case stages...');
      final stagesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}case/stage/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
          'TEST 1.13: Case stages response status: ${stagesResponse.statusCode}');
      print('TEST 1.14: Case stages response body: ${stagesResponse.body}');

      if (stagesResponse.statusCode == 200) {
        print('TEST 1.15: Case stages API response successful');
        setState(() {
          try {
            final responseData = json.decode(stagesResponse.body);
            if (responseData is List) {
              _stageOfCases = List<Map<String, dynamic>>.from(responseData);
              print(
                  'TEST 1.16: Case stages parsed successfully: ${_stageOfCases.length} items');
              if (_stageOfCases.isNotEmpty) {
                print('TEST 1.17: First case stage: ${_stageOfCases[0]}');
              }
            } else {
              print('TEST 1.18: Case stages data is not a list');
              _stageOfCases = [];
            }
          } catch (e) {
            print('TEST 1.19: Error parsing case stages: $e');
            _stageOfCases = [];
          }
        });
      } else {
        print('TEST 1.20: Error: Case stages API response failed');
        print('TEST 1.21: Case stages status: ${stagesResponse.statusCode}');
      }

      // Fetch court types
      print('TEST 1.22: Fetching court types...');
      final courtTypesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getcourttype/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
          'TEST 1.23: Court types response status: ${courtTypesResponse.statusCode}');
      print('TEST 1.24: Court types response body: ${courtTypesResponse.body}');

      if (courtTypesResponse.statusCode == 200) {
        print('TEST 1.25: Court types API response successful');
        setState(() {
          try {
            final responseData = json.decode(courtTypesResponse.body);
            if (responseData is List) {
              _courtTypes = List<Map<String, dynamic>>.from(responseData);
              print(
                  'TEST 1.26: Court types parsed successfully: ${_courtTypes.length} items');
              if (_courtTypes.isNotEmpty) {
                print('TEST 1.27: First court type: ${_courtTypes[0]}');

                // Set District Court as default if available
                final districtCourtIndex = _courtTypes.indexWhere(
                    (type) => type['court_type'] == 'District Court');
                if (districtCourtIndex != -1) {
                  setState(() {
                    _selectedCourtType =
                        _courtTypes[districtCourtIndex]['court_type'];
                    print(
                        'TEST 1.28: Default court type set to District Court');
                  });
                } else if (_courtTypes.isNotEmpty) {
                  // If District Court not found, select the first court type
                  setState(() {
                    _selectedCourtType = _courtTypes[0]['court_type'];
                    print(
                        'TEST 1.29: Default court type set to first available: ${_selectedCourtType}');
                  });
                }
              }
            } else {
              print('TEST 1.30: Invalid court types data format');
              _courtTypes = [];
            }
          } catch (e) {
            print('TEST 1.31: Error parsing court types: $e');
            print('TEST 1.32: Response body: ${courtTypesResponse.body}');
            _courtTypes = [];
          }
        });
      } else {
        print('TEST 1.33: Error: Court types API response failed');
        print(
            'TEST 1.34: Court types status: ${courtTypesResponse.statusCode}');
      }
    } catch (e) {
      print('TEST 1.35: Error fetching dropdown data: $e');
      print('TEST 1.36: Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _pickDocument() async {
    try {
      print('TEST 2.1: Starting document picker...');
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (pickedFile != null) {
        print('TEST 2.2: Document selected: ${pickedFile.path}');
        setState(() {
          _document = File(pickedFile.path);
        });
        print('TEST 2.3: Document state updated');
      } else {
        print('TEST 2.4: No document selected');
      }
    } catch (e) {
      print('TEST 2.5: Error picking document: $e');
      print('TEST 2.6: Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    try {
      print('TEST 2.7: Opening date picker...');
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        // Format date as DD-MM-YYYY
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        final year = picked.year;
        final formattedDate = '$day-$month-$year';
        print('TEST 2.8: Date selected: $formattedDate');
        controller.text = formattedDate;
        print('TEST 2.9: Date controller updated');
      } else {
        print('TEST 2.10: No date selected');
      }
    } catch (e) {
      print('TEST 2.11: Error selecting date: $e');
      print('TEST 2.12: Stack trace: ${StackTrace.current}');
    }
  }

  String? _validateNextDate(String? value) {
    print('TEST 2.13: Validating next date: $value');
    if (value == null || value.isEmpty) {
      print('TEST 2.14: Next date is empty');
      return 'Please select next date';
    }

    // Validate date format (DD-MM-YYYY)
    final dateRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      print('TEST 2.15: Next date format is invalid');
      return 'Please enter date in DD-MM-YYYY format';
    }

    try {
      // Parse the date parts
      final parts = value.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      print('TEST 2.16: Parsed date parts: day=$day, month=$month, year=$year');

      // Create DateTime object
      final selectedDate = DateTime(year, month, day);
      var today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);
      print('TEST 2.17: Selected date: $selectedDate, Today: $today');

      if (selectedDate.isBefore(today)) {
        print('TEST 2.18: Selected date is before today');
        return 'Next date cannot be before today';
      }
      print('TEST 2.19: Next date validation passed');
    } catch (e) {
      print('TEST 2.20: Error validating next date: $e');
      print('TEST 2.21: Stack trace: ${StackTrace.current}');
      return 'Please enter a valid date';
    }
    return null;
  }

  Future<void> _submitForm() async {
    print('TEST 3.1: Starting form submission...');
    if (_formKey.currentState!.validate()) {
      print('TEST 3.2: Form validation passed');
      setState(() {
        isLoading = true;
      });
      print('TEST 3.3: Loading state set to true');

      try {
        final apiService = ApiService();
        final token = await apiService.getAccessToken();
        print(
            'TEST 3.4: Token retrieved for form submission: ${token != null ? token.substring(0, 10) : "null"}...');

        // Create request body
        final requestBody = {
          "cnr": _crnController.text,
          "case_no": _caseNoController.text,
          "year":
              _caseYearController.text.isEmpty ? "" : _caseYearController.text,
          "state_id": _districtsData
              .firstWhere(
                (item) => item['state']['state'] == _selectedState,
                orElse: () => {
                  'state': {'id': null}
                },
              )['state']['id']
              ?.toString(),
          "district_id": _districtsData
              .firstWhere(
                (item) => item['district'] == _selectedDistrict,
                orElse: () => {'id': null},
              )['id']
              ?.toString(),
          "court_type_id": _courtTypes
              .firstWhere(
                (type) => type['court_type'] == _selectedCourtType,
                orElse: () => {'id': null},
              )['id']
              ?.toString(),
          "court_id": _courts
              .firstWhere(
                (court) =>
                    '${court['court_no']} - ${court['court_name']}' ==
                    _selectedCourt,
                orElse: () => {'id': null},
              )['id']
              ?.toString(),
          "case_type_id": _caseTypes
              .firstWhere(
                (type) => type['case_type'] == _selectedCaseType,
                orElse: () => {'id': null},
              )['id']
              ?.toString(),
          "under_section": _underSectionController.text,
          "petitioner": _petitionerController.text,
          "respondent": _respondentController.text,
          "client_type": _selectedClientType,
          "case_stage_id": _stageOfCases
              .firstWhere(
                (stage) => stage['stage_of_case'] == _selectedStageOfCase,
                orElse: () => {'id': null},
              )['id']
              ?.toString(),
          "first_date":
              DateTime.now().toString().split(' ')[0], // YYYY-MM-DD format
          "next_date": _nextDateController.text
              .split('-')
              .reversed
              .join('-'), // Convert DD-MM-YYYY to YYYY-MM-DD
          "fir_no": _firNumberController.text,
          "fir_year":
              _firYearController.text.isEmpty ? "" : _firYearController.text,
          "police_station": _policeStationController.text,
          "sub_advocate": _subAdvocateController.text,
          "comments": _commentsController.text,
          "document": "", // Always include document field with empty string
        };

        print('TEST 3.5: Request body prepared: $requestBody');

        // Create multipart request
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.baseUrl}case/add/'),
        );

        // Add headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        print('TEST 3.6: Request headers added');

        // Add fields
        requestBody.forEach((key, value) {
          if (value != null) {
            request.fields[key] = value.toString();
          }
        });
        print('TEST 3.7: Form fields added');

        // Add document if selected
        if (_document != null) {
          print('TEST 3.8: Adding document to request: ${_document!.path}');
          request.files.add(
            await http.MultipartFile.fromPath(
              'document',
              _document!.path,
            ),
          );
          print('TEST 3.9: Document added to request');
        }

        // Send request
        print('TEST 3.10: Sending request to server...');
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        print('TEST 3.11: Response status code: ${response.statusCode}');
        print('TEST 3.12: Response data: $responseData');

        // Parse response data
        final Map<String, dynamic> responseJson = json.decode(responseData);
        final int status = responseJson['status'] ?? 0;
        final String message =
            responseJson['message'] ?? 'Unknown error occurred';

        if (status == 200) {
          print('TEST 3.13: Case added successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Case added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  userData: widget.userData,
                  cases: const [],
                  count: widget.count,
                ),
              ),
            );
            print('TEST 3.14: Navigated to home screen');
          }
        } else {
          print('TEST 3.15: Failed to add case: $status - $message');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to add case: $message'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        print('TEST 3.16: Error submitting form: $e');
        print('TEST 3.17: Stack trace: ${StackTrace.current}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding case: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          print('TEST 3.18: Loading state set to false');
        }
      }
    } else {
      print('TEST 3.19: Form validation failed');
    }
  }

  Future<void> _loadDistricts() async {
    try {
      print('\n=== Loading Districts Data ===');
      print('Test 1: Getting districts from API');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}getdistrict/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        print('Test 2: Districts data received successfully');
        setState(() {
          _districtsData =
              List<Map<String, dynamic>>.from(json.decode(response.body));
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
                  // Fetch courts for the selected district
                  _fetchCourts(userDistrict);
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
                  // Fetch courts for the selected district
                  _fetchCourts(_filteredDistricts.first);
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
                // Fetch courts for the selected district
                _fetchCourts(_filteredDistricts.first);
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
      // Reset courts when district changes
      _courts = [];
      _selectedCourt = null;
    });
  }

  Future<void> _fetchCourts(String district) async {
    try {
      print('TEST 1: Starting to fetch courts for district: $district');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('TEST 1.1: Token retrieved successfully');

      // Find district ID
      final districtData = _districtsData.firstWhere(
        (item) => item['district'] == district,
        orElse: () => {'id': null},
      );

      if (districtData['id'] == null) {
        print('TEST 1.2: District ID not found');
        return;
      }

      print('TEST 1.3: District ID found: ${districtData['id']}');

      // Call getcourt/ API
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}getcourt/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'district_id': districtData['id'],
        }),
      );

      print('TEST 1.4: Courts response status: ${response.statusCode}');
      print('TEST 1.5: Courts response body: ${response.body}');

      if (response.statusCode == 200) {
        print('TEST 1.6: Courts API response successful');
        setState(() {
          try {
            final responseData = json.decode(response.body);
            if (responseData['status'] == 200 &&
                responseData['payload'] is List) {
              _courts =
                  List<Map<String, dynamic>>.from(responseData['payload']);
              print(
                  'TEST 1.7: Courts parsed successfully: ${_courts.length} items');
              if (_courts.isNotEmpty) {
                print('TEST 1.8: First court: ${_courts[0]}');
              }
            } else {
              print('TEST 1.9: Invalid courts data format');
              _courts = [];
            }
          } catch (e) {
            print('TEST 1.10: Error parsing courts: $e');
            _courts = [];
          }
        });
      } else {
        print('TEST 1.11: Error: Courts API response failed');
        print('TEST 1.12: Courts status: ${response.statusCode}');
      }
    } catch (e) {
      print('TEST 1.13: Error fetching courts: $e');
      print('TEST 1.14: Stack trace: ${StackTrace.current}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'Add New Case',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
      ),
      body: isInitialLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.fromRGBO(123, 109, 217, 1),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            )
          : isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Basic Information
                        _buildSectionTitle('Basic Information'),
                        _buildTextField(
                            _crnController, 'CRN Number', 'Enter CRN number',
                            isRequired: false),
                        _buildTextField(_caseNoController, 'Case Number',
                            'Enter case number',
                            isRequired: false),
                        _buildYearDropdown(_caseYearController, 'Case Year',
                            isRequired: false),

                        // Location Information
                        _buildSectionTitle('Location Information'),
                        _buildDropdown(
                          'State',
                          _uniqueStates,
                          _selectedState,
                          (value) {
                            if (value != null) {
                              setState(() {
                                _selectedState = value;
                                _updateDistricts(value);
                              });
                            }
                          },
                        ),
                        _buildDropdown(
                          'District',
                          _filteredDistricts,
                          _selectedDistrict,
                          (value) {
                            setState(() {
                              _selectedDistrict = value;
                              if (value != null) {
                                _fetchCourts(value);
                              }
                            });
                          },
                        ),
                        _buildDropdown(
                          'Court Type',
                          _courtTypes
                              .map((type) => type['court_type'] as String)
                              .toList(),
                          _selectedCourtType,
                          (value) => setState(() => _selectedCourtType = value),
                        ),
                        _buildDropdown(
                          'Court',
                          _courts
                              .map((court) =>
                                  '${court['court_no']} - ${court['court_name']}')
                              .toList(),
                          _selectedCourt,
                          (value) => setState(() => _selectedCourt = value),
                        ),

                        // Case Details
                        _buildSectionTitle('Case Details'),
                        _buildDropdown(
                          'Case Type',
                          _caseTypes
                              .map((type) => type['case_type'] as String)
                              .toList(),
                          _selectedCaseType,
                          (value) => setState(() => _selectedCaseType = value),
                        ),
                        _buildTextField(_underSectionController,
                            'Under Section', 'Enter section',
                            isRequired: false),

                        // Parties
                        _buildSectionTitle('Parties'),
                        _buildTextField(_petitionerController, 'Petitioner',
                            'Enter petitioner name'),
                        _buildTextField(_respondentController, 'Respondent',
                            'Enter respondent name'),
                        _buildDropdown(
                          'Client Type',
                          ['Petitioner', 'Respondent'],
                          _selectedClientType,
                          (value) =>
                              setState(() => _selectedClientType = value),
                        ),

                        // Case Progress
                        _buildSectionTitle('Case Progress'),
                        _buildDropdown(
                          'Stage of Case',
                          _stageOfCases
                              .map((stage) => stage['stage_of_case'] as String)
                              .toList(),
                          _selectedStageOfCase,
                          (value) =>
                              setState(() => _selectedStageOfCase = value),
                        ),

                        // FIR Details
                        _buildSectionTitle('FIR Details'),
                        _buildTextField(_firNumberController, 'FIR Number',
                            'Enter FIR number',
                            isRequired: false),
                        _buildYearDropdown(_firYearController, 'FIR Year',
                            isRequired: false),
                        _buildTextField(_policeStationController,
                            'Police Station', 'Enter police station',
                            isRequired: false),

                        // Dates
                        _buildSectionTitle('Important Dates'),
                        _buildDateField(_nextDateController, 'Next Date',
                            validator: _validateNextDate),

                        // Additional Information
                        _buildSectionTitle('Additional Information'),
                        _buildTextField(_subAdvocateController, 'Sub Advocate',
                            'Enter sub advocate name',
                            isRequired: false),
                        _buildTextField(
                            _commentsController, 'Comments', 'Enter comments',
                            maxLines: 3, isRequired: false),

                        // Document Upload
                        _buildSectionTitle('Document'),
                        _buildDocumentUpload(),

                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(123, 109, 217, 1),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Add Case',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildYearDropdown(
    TextEditingController controller,
    String label, {
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: controller.text.isEmpty ? null : int.tryParse(controller.text),
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: _years.map((year) {
          return DropdownMenuItem<int>(
            value: year,
            child: Text(year.toString()),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            controller.text = value.toString();
          }
        },
        validator: isRequired
            ? (value) {
                if (value == null) {
                  return 'Please select $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        maxLines: maxLines,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      Function(String?) onChanged,
      {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: isRequired
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    String label, {
    bool isRequired = true,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: 'DD-MM-YYYY',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context, controller),
          ),
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          _DateInputFormatter(),
        ],
        validator: validator ??
            (isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select $label';
                    }
                    return null;
                  }
                : null),
      ),
    );
  }

  Widget _buildDocumentUpload() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                if (_document != null)
                  Column(
                    children: [
                      const Icon(Icons.document_scanner, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _document!.path.split('/').last,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _document = null;
                          });
                        },
                        child: const Text('Remove'),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Icon(Icons.upload_file, size: 48),
                      const SizedBox(height: 8),
                      const Text('No document selected'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _pickDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(123, 109, 217, 1),
                        ),
                        child: const Text('Select Document'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _crnController.dispose();
    _caseNoController.dispose();
    _caseYearController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _courtTypeController.dispose();
    _courtController.dispose();
    _underSectionController.dispose();
    _petitionerController.dispose();
    _respondentController.dispose();
    _firNumberController.dispose();
    _firYearController.dispose();
    _policeStationController.dispose();
    _nextDateController.dispose();
    _subAdvocateController.dispose();
    _commentsController.dispose();
    super.dispose();
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any non-digit characters
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Add separators
    if (text.length > 0) {
      if (text.length <= 2) {
        // Only DD
        return TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } else if (text.length <= 4) {
        // DD-MM
        return TextEditingValue(
          text: '${text.substring(0, 2)}-${text.substring(2)}',
          selection: TextSelection.collapsed(offset: text.length + 1),
        );
      } else {
        // DD-MM-YYYY
        return TextEditingValue(
          text:
              '${text.substring(0, 2)}-${text.substring(2, 4)}-${text.substring(4, min(8, text.length))}',
          selection: TextSelection.collapsed(offset: text.length + 2),
        );
      }
    }

    return newValue;
  }

  int min(int a, int b) => a < b ? a : b;
}
