import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'detailed_comparison_screen.dart';

class ActsComparisonScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final List<dynamic> acts;

  const ActsComparisonScreen({
    Key? key,
    required this.userData,
    required this.acts,
  }) : super(key: key);

  @override
  State<ActsComparisonScreen> createState() => _ActsComparisonScreenState();
}

class _ActsComparisonScreenState extends State<ActsComparisonScreen> {
  String? selectedAct;
  String? selectedSection;
  List<Map<String, String>> sections = [];
  bool isLoadingSections = false;
  String? error;
  Map<String, dynamic>? similarSectionData;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final Map<String, String> actMappings = {
    'IPC': 'BNS',
    'BNS': 'IPC',
    'CrPC': 'BNSS',
    'BNSS': 'CrPC',
    'IEA': 'BSA',
    'BSA': 'IEA',
  };

  List<Map<String, String>> _getFilteredActs() {
    final List<String> allowedActs = [
      'IPC',
      'BNS',
      'BNSS',
      'CrPC',
      'IEA',
      'BSA'
    ];
    return widget.acts
        .where((act) => allowedActs.contains(act['act_short_name']))
        .map((act) => {
              'id': act['id'].toString(),
              'name': (act['act_name'] as String?) ?? 'Unnamed Act',
              'short_name': (act['act_short_name'] as String?) ?? '',
            })
        .where((act) => act['short_name']!.isNotEmpty)
        .toList();
  }

  Future<void> _fetchSections(String actId) async {
    setState(() {
      isLoadingSections = true;
      error = null;
      sections = [];
      selectedSection = null;
    });

    try {
      print('\n=== Fetching Sections ===');
      print('Act ID: $actId');

      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Access token retrieved successfully');

      final requestBody = {
        'chapter_id': 'all',
        'actbook_id': actId,
      };
      print('Request Body: $requestBody');

      print('Making API request to: ${AppConfig.baseUrl}actbook/section/');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}actbook/section/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final String decodedBody = utf8.decode(response.bodyBytes);
          print('Decoded Response Body: $decodedBody');

          final data = json.decode(decodedBody);
          print('Parsed Response Data: $data');

          if (data['data'] != null) {
            // Process the nested JSON structure
            final List<dynamic> rawSections = data['data'];
            final processedSections = rawSections.map((section) {
              print('Processing section: $section');
              return {
                'id': section['id']?.toString() ?? '',
                'section_number': section['section_number']?.toString() ?? '',
                'section_title':
                    section['section_title']?.toString() ?? 'Unnamed Section',
                'display_text':
                    '${section['section_number'] ?? ''} - ${section['section_title'] ?? 'Unnamed Section'}',
              };
            }).toList();

            // Sort sections numerically
            processedSections.sort((a, b) {
              // Extract numbers from section numbers (e.g., "123" from "Section 123")
              String numA =
                  a['section_number']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
              String numB =
                  b['section_number']?.replaceAll(RegExp(r'[^0-9]'), '') ?? '0';

              // Convert to integers for comparison
              int intA = int.tryParse(numA) ?? 0;
              int intB = int.tryParse(numB) ?? 0;

              return intA.compareTo(intB);
            });

            print('Processed Sections: $processedSections');

            setState(() {
              sections = processedSections;
              isLoadingSections = false;
            });
            print(
                'Sections loaded successfully: ${sections.length} sections found');
          } else {
            print('No sections found in response data');
            setState(() {
              error = 'No sections found';
              isLoadingSections = false;
            });
          }
        } catch (e) {
          print('JSON Decoding Error: $e');
          setState(() {
            error = 'Error decoding response: $e';
            isLoadingSections = false;
          });
        }
      } else {
        print('Error: Failed to load sections. Status: ${response.statusCode}');
        setState(() {
          error = 'Failed to load sections';
          isLoadingSections = false;
        });
      }
    } catch (e) {
      print('Error in _fetchSections: $e');
      setState(() {
        error = 'Error: $e';
        isLoadingSections = false;
      });
    }
  }

  Future<void> _fetchSimilarSections(String sectionId) async {
    try {
      print('\n=== Fetching Similar Sections ===');
      print('Section ID: $sectionId');

      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Access token retrieved successfully');

      final requestBody = {
        'section_id': sectionId,
      };
      print('Request Body: $requestBody');

      print(
          'Making API request to: ${AppConfig.baseUrl}actbook/similar-section/');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}actbook/similar-section/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: json.encode(requestBody),
      );

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        try {
          final String decodedBody = utf8.decode(response.bodyBytes);
          print('Decoded Response Body: $decodedBody');

          final data = json.decode(decodedBody);
          print('Parsed Response Data: $data');

          if (data['data'] != null && data['data'].isNotEmpty) {
            setState(() {
              similarSectionData = data['data'][0];
            });
            print('Similar section data loaded successfully');
          } else {
            print('No similar sections found in response data');
            setState(() {
              similarSectionData = null;
            });
          }
        } catch (e) {
          print('JSON Decoding Error: $e');
          setState(() {
            similarSectionData = null;
          });
        }
      } else if (response.statusCode == 404) {
        print('No similar sections found (404)');
        setState(() {
          similarSectionData = null;
        });
      } else {
        print(
            'Error: Failed to load similar sections. Status: ${response.statusCode}');
        setState(() {
          similarSectionData = null;
        });
      }
    } catch (e) {
      print('Error in _fetchSimilarSections: $e');
      setState(() {
        similarSectionData = null;
      });
    }
  }

  Widget _buildSearchableDropdown() {
    // Convert sections to Map<String, String> once
    final List<Map<String, String>> stringSections = sections
        .map((section) => {
              'id': section['id']?.toString() ?? '',
              'section_number': section['section_number']?.toString() ?? '',
              'section_title': section['section_title']?.toString() ?? '',
              'display_text': section['display_text']?.toString() ?? '',
            })
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(123, 109, 217, 1),
        ),
      ),
      child: DropdownSearch<Map<String, String>>(
        popupProps: const PopupProps.menu(
          showSearchBox: true,
          searchFieldProps: TextFieldProps(
            decoration: InputDecoration(
              hintText: "Search section...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
          constraints: BoxConstraints(maxHeight: 300),
        ),
        items: stringSections,
        itemAsString: (Map<String, String> section) =>
            section['display_text'] ?? '',
        onChanged: (Map<String, String>? value) {
          setState(() {
            selectedSection = value?['id'];
          });
          if (value?['id'] != null) {
            _fetchSimilarSections(value!['id']!);
          }
        },
        selectedItem: selectedSection != null
            ? stringSections.firstWhere(
                (section) => section['id'] == selectedSection,
                orElse: () => {
                  'id': '',
                  'section_number': '',
                  'section_title': '',
                  'display_text': '',
                },
              )
            : null,
        dropdownDecoratorProps: const DropDownDecoratorProps(
          dropdownSearchDecoration: InputDecoration(
            hintText: "Select Section",
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        compareFn: (item1, item2) => item1['id'] == item2['id'],
        filterFn: (item, filter) {
          final searchText = filter.toLowerCase();
          return (item['display_text']?.toLowerCase().contains(searchText) ??
                  false) ||
              (item['section_number']?.toLowerCase().contains(searchText) ??
                  false);
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredActs = _getFilteredActs();

    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'Old Acts V/s New Acts',
          style: TextStyle(
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Act to Compare',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(123, 109, 217, 1),
              ),
            ),
            const SizedBox(height: 20),
            // Act Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromRGBO(123, 109, 217, 1),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Select Act'),
                  value: selectedAct,
                  items: filteredActs
                      .map((act) => DropdownMenuItem<String>(
                            value: act['short_name']!,
                            child: Text(act['name']!),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedAct = value;
                      selectedSection = null;
                    });
                    if (value != null) {
                      final act = filteredActs.firstWhere(
                        (act) => act['short_name'] == value,
                        orElse: () => {'id': '', 'name': '', 'short_name': ''},
                      );
                      if (act['id']!.isNotEmpty) {
                        _fetchSections(act['id']!);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Section Dropdown with Search
            if (selectedAct != null)
              isLoadingSections
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromRGBO(123, 109, 217, 1),
                            ),
                          ),
                        ),
                      ),
                    )
                  : error != null
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : _buildSearchableDropdown(),
            const SizedBox(height: 24),
            // Comparison Display
            if (selectedAct != null) _buildComparisonBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonBox() {
    final selectedActName = _getFilteredActs()
        .firstWhere((act) => act['short_name'] == selectedAct)['name']!;
    final correspondingActName = _getFilteredActs().firstWhere(
        (act) => act['short_name'] == actMappings[selectedAct])['name']!;

    // Check if both sections exist in the response
    bool hasBothSections = similarSectionData != null &&
        similarSectionData!['section'] != null &&
        similarSectionData!['similar_section'] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedActName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(123, 109, 217, 1),
                  ),
                ),
              ),
              const Icon(
                Icons.compare_arrows,
                color: Color.fromRGBO(123, 109, 217, 1),
              ),
              Expanded(
                child: Text(
                  correspondingActName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(123, 109, 217, 1),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(123, 109, 217, 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color.fromRGBO(123, 109, 217, 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Section',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromRGBO(123, 109, 217, 1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedSection != null
                            ? '${sections.firstWhere((s) => s['id'] == selectedSection)['section_number']}'
                            : 'NA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(123, 109, 217, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(123, 109, 217, 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color.fromRGBO(123, 109, 217, 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Section',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color.fromRGBO(123, 109, 217, 1),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        similarSectionData != null
                            ? _getCorrespondingSectionNumber()
                                .replaceAll('Section ', '')
                            : 'NA',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(123, 109, 217, 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasBothSections && selectedSection != null
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailedComparisonScreen(
                            selectedAct: selectedAct!,
                            selectedSection: selectedSection!,
                            similarSectionData: similarSectionData,
                            sections: sections,
                            actMappings: actMappings,
                            filteredActs: _getFilteredActs(),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Compare Acts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCorrespondingSectionNumber() {
    if (similarSectionData == null || selectedSection == null) return 'NA';

    final selectedSectionNumber = sections.firstWhere(
      (s) => s['id'] == selectedSection,
      orElse: () => <String, String>{
        'id': '',
        'section_number': '',
      },
    )['section_number'];

    if (selectedSectionNumber == null) return 'NA';

    final section = similarSectionData!['section'];
    final similarSection = similarSectionData!['similar_section'];

    if (section['section_number'] == selectedSectionNumber) {
      return 'Section ${similarSection['section_number']}';
    } else if (similarSection['section_number'] == selectedSectionNumber) {
      return 'Section ${section['section_number']}';
    }

    return 'NA';
  }
}
