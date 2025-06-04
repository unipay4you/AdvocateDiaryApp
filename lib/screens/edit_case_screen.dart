import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'case_detail_screen.dart';

class EditCaseScreen extends StatefulWidget {
  final String caseId;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> count;

  const EditCaseScreen({
    Key? key,
    required this.caseId,
    required this.userData,
    required this.count,
  }) : super(key: key);

  @override
  State<EditCaseScreen> createState() => _EditCaseScreenState();
}

class _EditCaseScreenState extends State<EditCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isInitialLoading = true;
  File? _document;
  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _caseData;

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
  final TextEditingController _caseDecidedCommentsController =
      TextEditingController();

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
  bool _isCaseDecided = false;

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    _years =
        List.generate(currentYear - 1970 + 1, (index) => currentYear - index);
  }

  @override
  void initState() {
    super.initState();
    print('\n=== Starting EditCaseScreen Initialization ===');
    print('Test 1: EditCaseScreen initState called');
    _initializeYears();
    _loadDistricts().then((_) {
      print('Test 2: Districts loaded successfully');
      return _fetchDropdownData();
    }).then((_) {
      print('Test 3: Dropdown data loaded successfully');
      return _fetchCaseData();
    }).then((_) {
      if (mounted) {
        setState(() {
          isInitialLoading = false;
          print('Test 4: All data loaded, setting isInitialLoading to false');
        });
      }
    });
    print('=== End EditCaseScreen Initialization ===\n');
  }

  Future<void> _fetchCaseData() async {
    try {
      print('\n=== Starting Case Data Fetch ===');
      print('Test 1: Getting case data for ID: ${widget.caseId}');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Test 2: Token retrieved successfully');

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}case/detail/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id': widget.caseId,
        }),
      );

      print('Test 3: Response status: ${response.statusCode}');
      print('Test 4: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 200) {
          setState(() {
            _caseData = responseData['cases'];
            print('Test 5: Case data fetched successfully');
            print('Test 6: Setting form fields with response data');

            // Set form fields with response data
            _crnController.text = _caseData!['crn'] ?? '';
            _caseNoController.text = _caseData!['case_no'] ?? '';
            _caseYearController.text =
                _caseData!['case_year']?.toString() ?? '';
            _selectedState = _caseData!['state'] ?? '';
            _selectedDistrict = _caseData!['district'] ?? '';
            _selectedCourtType = _caseData!['court_type'] ?? '';
            _selectedCourt =
                '${_caseData!['court_no']} - ${_caseData!['court_name']}';
            _underSectionController.text = _caseData!['under_section'] ?? '';
            _selectedCaseType = _caseData!['case_type']['case_type'] ?? '';
            _petitionerController.text = _caseData!['petitioner'] ?? '';
            _respondentController.text = _caseData!['respondent'] ?? '';
            _selectedClientType = _caseData!['client_type'] ?? '';
            _selectedStageOfCase =
                _caseData!['stage_of_case']['stage_of_case'] ?? '';
            _firNumberController.text = _caseData!['fir_number'] ?? '';
            _firYearController.text = _caseData!['fir_year']?.toString() ?? '';
            _policeStationController.text = _caseData!['police_station'] ?? '';

            // Convert YYYY-MM-DD to DD-MM-YYYY for display
            final nextDate = _caseData!['next_date'] ?? '';
            if (nextDate.isNotEmpty) {
              final parts = nextDate.split('-');
              if (parts.length == 3) {
                _nextDateController.text =
                    '${parts[2]}-${parts[1]}-${parts[0]}';
              } else {
                _nextDateController.text = nextDate;
              }
            } else {
              _nextDateController.text = '';
            }

            _subAdvocateController.text = _caseData!['sub_advocate'] ?? '';

            // Update case decided status and comments
            _isCaseDecided = _caseData!['is_desided'] ?? false;
            print('Test 6.1: Case decided status: $_isCaseDecided');
            _caseDecidedCommentsController.text = _caseData!['comments'] ?? '';

            print('Test 7: All form fields initialized with response data');
          });
        } else {
          print(
              'Test 8: Failed to fetch case data: ${responseData['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Failed to fetch case data: ${responseData['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        print('Test 9: Error fetching case data: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error fetching case data: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Test 10: Exception while fetching case data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching case data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    print('=== End Case Data Fetch ===\n');
  }

  void _initializeFormData() {
    if (_caseData == null) return;

    print('\n=== Starting Form Data Initialization ===');
    print('Test 1: Initializing form fields with case data');
    // Initialize form fields with case data
    _crnController.text = _caseData!['crn'] ?? '';
    _caseNoController.text = _caseData!['case_no'] ?? '';
    _caseYearController.text = _caseData!['case_year']?.toString() ?? '';
    _selectedState = _caseData!['state']?['state'] ?? '';
    _selectedDistrict = _caseData!['district']?['district'] ?? '';
    _selectedCourtType = _caseData!['court_type']?['court_type'] ?? '';
    _selectedCourt = '${_caseData!['court_no']} - ${_caseData!['court_name']}';
    _underSectionController.text = _caseData!['under_section'] ?? '';
    _selectedCaseType = _caseData!['case_type']?['case_type'] ?? '';
    _petitionerController.text = _caseData!['petitioner'] ?? '';
    _respondentController.text = _caseData!['respondent'] ?? '';
    _selectedClientType = _caseData!['client_type'] ?? '';
    _selectedStageOfCase = _caseData!['stage_of_case']?['stage_of_case'] ?? '';
    _firNumberController.text = _caseData!['fir_number'] ?? '';
    _firYearController.text = _caseData!['fir_year']?.toString() ?? '';
    _policeStationController.text = _caseData!['police_station'] ?? '';
    _nextDateController.text = _caseData!['next_date'] ?? '';
    _subAdvocateController.text = _caseData!['sub_advocate'] ?? '';
    _isCaseDecided = _caseData!['is_desided'] ?? false;
    print('Test 2: All form fields initialized');
    print('=== End Form Data Initialization ===\n');
  }

  Future<void> _submitForm() async {
    print('\n=== Starting Form Submission Process ===');
    print('Test 1.1: Form submission started');
    if (_formKey.currentState!.validate()) {
      print('Test 1.2: Form validation passed');
      setState(() {
        isLoading = true;
      });
      print('Test 1.3: Loading state set to true');

      try {
        final apiService = ApiService();
        final token = await apiService.getAccessToken();
        print('Test 1.4: Token retrieved successfully');

        // Convert DD-MM-YYYY to YYYY-MM-DD for API
        String nextDate = _nextDateController.text;
        if (nextDate.isNotEmpty) {
          final parts = nextDate.split('-');
          if (parts.length == 3) {
            nextDate = '${parts[2]}-${parts[1]}-${parts[0]}';
          }
        }

        // Create request body
        final requestBody = {
          "id": widget.caseId,
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
          "next_date": nextDate,
          "fir_no": _firNumberController.text,
          "fir_year":
              _firYearController.text.isEmpty ? "" : _firYearController.text,
          "police_station": _policeStationController.text,
          "sub_advocate": _subAdvocateController.text,
          "comments": _caseDecidedCommentsController.text.isEmpty
              ? ""
              : _caseDecidedCommentsController.text,
          "is_desided": _isCaseDecided,
        };
        print('Test 1.5: Request body prepared: $requestBody');

        // Send request to case/edit/ API
        final response = await http.post(
          Uri.parse('${AppConfig.baseUrl}case/edit/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );

        print('Test 1.6: Response received - Status: ${response.statusCode}');
        print('Test 1.7: Response data: ${response.body}');

        // Parse response data
        print('Test 1.8: Starting response parsing');
        try {
          final Map<String, dynamic> responseJson = json.decode(response.body);
          print('Test 1.9: Response JSON decoded successfully');

          // Safely extract status and message
          final dynamic statusValue = responseJson['status'];
          final int status = statusValue is int ? statusValue : 0;
          final String message =
              responseJson['message']?.toString() ?? 'Unknown error occurred';

          print(
              'Test 1.10: Response parsed - Status: $status, Message: $message');

          if (status == 200) {
            print('Test 1.11: Case updated successfully');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Case updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
              print('Test 1.12: Success snackbar shown');

              // Navigate back to case detail screen
              Navigator.pop(context);
            }
          } else {
            print('Test 1.14: Failed to update case: $status - $message');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update case: $message'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
              print('Test 1.15: Error snackbar shown');
            }
          }
        } catch (e) {
          print('Test 1.16: Error parsing response: $e');
          print('Test 1.17: Stack trace: ${StackTrace.current}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error updating case: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
            print('Test 1.18: Error snackbar shown');
          }
        }
      } catch (e) {
        print('Test 1.19: Error in form submission: $e');
        print('Test 1.20: Stack trace: ${StackTrace.current}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating case: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
          print('Test 1.21: Error snackbar shown');
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          print('Test 1.22: Loading state set to false');
        }
      }
    } else {
      print('Test 1.23: Form validation failed');
    }
    print('=== End Form Submission Process ===\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'Edit Case',
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

                        // Case Status
                        _buildSectionTitle('Case Status'),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Is Case Decided?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              Switch(
                                value: _isCaseDecided,
                                onChanged: (value) {
                                  if (value) {
                                    _showCaseDecidedDialog();
                                  } else {
                                    setState(() {
                                      _isCaseDecided = false;
                                    });
                                  }
                                },
                                activeColor:
                                    const Color.fromRGBO(123, 109, 217, 1),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Submit Button
                        ElevatedButton(
                          onPressed: isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(123, 109, 217, 1),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Update Case',
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

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? value,
    Function(String?) onChanged, {
    bool isRequired = true,
  }) {
    // Ensure unique values in the items list
    final uniqueItems = items.toSet().toList();
    
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
        items: uniqueItems.map((item) {
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
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  controller.text =
                      '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
                });
              }
            },
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
                        onPressed: () async {
                          final XFile? pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              _document = File(pickedFile.path);
                            });
                          }
                        },
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

  String? _validateNextDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select next date';
    }

    // Validate date format (DD-MM-YYYY)
    final dateRegex = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter date in DD-MM-YYYY format';
    }

    try {
      // Parse the date parts
      final parts = value.split('-');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      // Create DateTime object
      final selectedDate = DateTime(year, month, day);
      var today = DateTime.now();
      today = DateTime(today.year, today.month, today.day);

      if (selectedDate.isBefore(today)) {
        return 'Next date cannot be before today';
      }
    } catch (e) {
      return 'Please enter a valid date';
    }
    return null;
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
    _caseDecidedCommentsController.dispose();
    super.dispose();
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

  Future<void> _showCaseDecidedDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Case Decided'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide comments for the case decision:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _caseDecidedCommentsController,
                decoration: const InputDecoration(
                  labelText: 'Comments',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter comments';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_caseDecidedCommentsController.text.isNotEmpty) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      setState(() {
        _isCaseDecided = true;
      });
    } else {
      setState(() {
        _isCaseDecided = false;
        _caseDecidedCommentsController.clear();
      });
    }
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
 