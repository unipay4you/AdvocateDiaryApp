import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/services.dart';

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
    _fetchDropdownData();
    _initializeYears();
  }

  Future<void> _fetchDropdownData() async {
    try {
      print('TEST 1: Starting to fetch dropdown data...');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print(
          'TEST 1.1: Token retrieved successfully: ${token != null ? token.substring(0, 10) : "null"}...');

      // Fetch court types
      print('TEST 1.2: Fetching court types...');
      final courtTypesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getcourttype/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      print(
          'TEST 1.3: Court types response status: ${courtTypesResponse.statusCode}');
      print('TEST 1.4: Court types response body: ${courtTypesResponse.body}');

      if (courtTypesResponse.statusCode == 200) {
        print(
            'TEST 1.5: Court types API response successful, updating state...');
        setState(() {
          try {
            final courtTypesData = json.decode(courtTypesResponse.body);
            if (courtTypesData is List) {
              _courtTypes = List<Map<String, dynamic>>.from(courtTypesData);
              print(
                  'TEST 1.6: Court types parsed successfully: ${_courtTypes.length} items');
              if (_courtTypes.isNotEmpty) {
                print('TEST 1.7: First court type: ${_courtTypes[0]}');

                // Set District Court as default if available
                final districtCourtIndex = _courtTypes.indexWhere(
                    (type) => type['court_type'] == 'District Court');
                if (districtCourtIndex != -1) {
                  setState(() {
                    _selectedCourtType =
                        _courtTypes[districtCourtIndex]['court_type'];
                    print('TEST 1.8: Default court type set to District Court');
                  });
                } else if (_courtTypes.isNotEmpty) {
                  // If District Court not found, select the first court type
                  setState(() {
                    _selectedCourtType = _courtTypes[0]['court_type'];
                    print(
                        'TEST 1.9: Default court type set to first available: ${_selectedCourtType}');
                  });
                }
              }
            } else {
              print(
                  'TEST 1.8: Court types data is not a list: ${courtTypesData.runtimeType}');
              _courtTypes = [];
            }
          } catch (e) {
            print('TEST 1.9: Error parsing court types: $e');
            _courtTypes = [];
          }
        });
        print('TEST 1.10: State updated successfully');
        print('TEST 1.11: Court types count: ${_courtTypes.length}');
      } else {
        print('TEST 1.12: Error: Court types API response failed');
        print(
            'TEST 1.13: Court types status: ${courtTypesResponse.statusCode}');
      }
    } catch (e) {
      print('TEST 1.14: Error fetching dropdown data: $e');
      print('TEST 1.15: Stack trace: ${StackTrace.current}');
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

        // Create form data
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${AppConfig.baseUrl}case/'),
        );

        // Add headers
        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });
        print('TEST 3.5: Request headers added');

        // Add text fields
        final fields = {
          'crn': _crnController.text,
          'case_no': _caseNoController.text,
          'case_year': _caseYearController.text,
          'state': _stateController.text,
          'district': _districtController.text,
          'court_type': _selectedCourtType!,
          'court': _selectedCourt!,
          'case_type': _selectedCaseType!,
          'under_section': _underSectionController.text,
          'petitioner': _petitionerController.text,
          'respondent': _respondentController.text,
          'client_type': _selectedClientType!,
          'stage_of_case': _selectedStageOfCase!,
          'fir_number': _firNumberController.text,
          'fir_year': _firYearController.text,
          'police_station': _policeStationController.text,
          'next_date': _nextDateController.text,
          'sub_advocate': _subAdvocateController.text,
          'comments': _commentsController.text,
        };
        request.fields.addAll(fields);
        print('TEST 3.6: Form fields added: $fields');

        // Add document if selected
        if (_document != null) {
          print('TEST 3.7: Adding document to request: ${_document!.path}');
          request.files.add(
            await http.MultipartFile.fromPath(
              'document',
              _document!.path,
            ),
          );
          print('TEST 3.8: Document added to request');
        }

        // Send request
        print('TEST 3.9: Sending request to server...');
        final response = await request.send();
        final responseData = await response.stream.bytesToString();
        print('TEST 3.10: Response status code: ${response.statusCode}');
        print('TEST 3.11: Response data: $responseData');

        if (response.statusCode == 201) {
          print('TEST 3.12: Case added successfully');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Case added successfully'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
            print('TEST 3.13: Navigated back to previous screen');
          }
        } else {
          print('TEST 3.14: Failed to add case: ${response.statusCode}');
          throw Exception('Failed to add case: ${response.statusCode}');
        }
      } catch (e) {
        print('TEST 3.15: Error submitting form: $e');
        print('TEST 3.16: Stack trace: ${StackTrace.current}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding case: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          print('TEST 3.17: Loading state set to false');
        }
      }
    } else {
      print('TEST 3.18: Form validation failed');
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
      body: isLoading
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
                    _buildTextField(
                        _caseNoController, 'Case Number', 'Enter case number',
                        isRequired: false),
                    _buildYearDropdown(_caseYearController, 'Case Year'),

                    // Location Information
                    _buildSectionTitle('Location Information'),
                    _buildTextField(_stateController, 'State', 'Enter state'),
                    _buildTextField(
                        _districtController, 'District', 'Enter district'),
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
                          .map((court) => court['court_name'] as String)
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
                    _buildTextField(_underSectionController, 'Under Section',
                        'Enter section',
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
                      (value) => setState(() => _selectedClientType = value),
                    ),

                    // Case Progress
                    _buildSectionTitle('Case Progress'),
                    _buildDropdown(
                      'Stage of Case',
                      _stageOfCases
                          .map((stage) => stage['stage_of_case'] as String)
                          .toList(),
                      _selectedStageOfCase,
                      (value) => setState(() => _selectedStageOfCase = value),
                    ),

                    // FIR Details
                    _buildSectionTitle('FIR Details'),
                    _buildTextField(
                        _firNumberController, 'FIR Number', 'Enter FIR number',
                        isRequired: false),
                    _buildYearDropdown(_firYearController, 'FIR Year',
                        isRequired: false),
                    _buildTextField(_policeStationController, 'Police Station',
                        'Enter police station',
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
                        backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
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
