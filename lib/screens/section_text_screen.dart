import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../screens/detailed_comparison_screen.dart';

class SectionTextScreen extends StatefulWidget {
  final String sectionTitle;
  final String sectionTitleHindi;
  final String sectionText;
  final String sectionTextHindi;
  final String sectionNumber;
  final String sectionId;
  final String actName;

  const SectionTextScreen({
    Key? key,
    required this.sectionTitle,
    required this.sectionTitleHindi,
    required this.sectionText,
    required this.sectionTextHindi,
    required this.sectionNumber,
    required this.sectionId,
    required this.actName,
  }) : super(key: key);

  @override
  State<SectionTextScreen> createState() => _SectionTextScreenState();
}

class _SectionTextScreenState extends State<SectionTextScreen> {
  bool _isLoadingSimilar = false;
  Map<String, dynamic>? _similarSectionData;
  String _selectedLanguage = 'Hindi'; // Default language is Hindi

  // Add this function to properly sort section numbers
  double _getSectionNumberValue(String sectionNumber) {
    // Split the section number into parts (e.g., "2.10" -> ["2", "10"])
    final parts = sectionNumber.split('.');

    // Convert to a double for proper numerical comparison
    if (parts.length > 1) {
      return double.parse('${parts[0]}.${parts[1]}');
    }
    return double.parse(parts[0]);
  }

  // Add this function to compare section numbers for sorting
  int _compareSectionNumbers(String a, String b) {
    final aValue = _getSectionNumberValue(a);
    final bValue = _getSectionNumberValue(b);
    return aValue.compareTo(bValue);
  }

  // Add this function to display the section number
  String _displaySectionNumber(String sectionNumber) {
    // Split the section number into parts
    final parts = sectionNumber.split('.');

    // If there's a decimal part, ensure it's displayed correctly
    if (parts.length > 1) {
      return '${parts[0]}.${parts[1]}';
    }
    return sectionNumber;
  }

  @override
  void initState() {
    super.initState();
    _checkSimilarSections();
  }

  Widget _buildLanguageToggle() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color.fromRGBO(123, 109, 217, 1),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton('हिंदी', _selectedLanguage == 'Hindi'),
          _buildToggleButton('English', _selectedLanguage == 'English'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = text == 'हिंदी' ? 'Hindi' : 'English';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromRGBO(123, 109, 217, 1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : const Color.fromRGBO(123, 109, 217, 1),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _checkSimilarSections() async {
    try {
      setState(() {
        _isLoadingSimilar = true;
      });

      print('\n=== Checking Similar Sections ===');
      print('Section ID: ${widget.sectionId}');

      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Access token retrieved successfully');

      final requestBody = {
        'section_id': widget.sectionId,
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
              _similarSectionData = data['data'][0];
              _isLoadingSimilar = false;
            });
            print('Similar section data loaded successfully');
          } else {
            print('No similar sections found in response data');
            setState(() {
              _similarSectionData = null;
              _isLoadingSimilar = false;
            });
          }
        } catch (e) {
          print('JSON Decoding Error: $e');
          setState(() {
            _similarSectionData = null;
            _isLoadingSimilar = false;
          });
        }
      } else if (response.statusCode == 404) {
        print('No similar sections found (404)');
        setState(() {
          _similarSectionData = null;
          _isLoadingSimilar = false;
        });
      } else {
        print(
            'Error: Failed to load similar sections. Status: ${response.statusCode}');
        setState(() {
          _similarSectionData = null;
          _isLoadingSimilar = false;
        });
      }
    } catch (e) {
      print('Error in _checkSimilarSections: $e');
      setState(() {
        _similarSectionData = null;
        _isLoadingSimilar = false;
      });
    }
  }

  void _shareSection() {
    final String shareText = '''
Section ${widget.sectionNumber}

${widget.sectionTitleHindi.isNotEmpty ? '${widget.sectionTitleHindi}\n' : ''}${widget.sectionTitle}

${widget.sectionTextHindi.isNotEmpty ? 'हिंदी में:\n${widget.sectionTextHindi}\n\n' : ''}In English:
${widget.sectionText}
''';
    Share.share(shareText);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Section ${widget.sectionNumber}',
                    style: const TextStyle(
                      color: Color.fromRGBO(123, 109, 217, 1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    widget.actName,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildLanguageToggle(),
          ],
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoadingSimilar)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromRGBO(123, 109, 217, 1),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_similarSectionData != null) _buildSimilarSectionCard(),
            const SizedBox(height: 16),
            // Title
            if (_selectedLanguage == 'Hindi' &&
                widget.sectionTitleHindi.isNotEmpty)
              Text(
                widget.sectionTitleHindi,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 1.5,
                ),
              )
            else
              Text(
                widget.sectionTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 16),
            // Section Text
            if (_selectedLanguage == 'Hindi' &&
                widget.sectionTextHindi.isNotEmpty)
              Text(
                widget.sectionTextHindi,
                style: const TextStyle(
                  fontFamily: 'Noto Sans Devanagari',
                  fontSize: 14,
                  height: 1.5,
                ),
              )
            else
              Text(
                widget.sectionText,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarSectionCard() {
    if (_similarSectionData == null) return const SizedBox.shrink();

    final section = _similarSectionData!['section'];
    final similarSection = _similarSectionData!['similar_section'];
    final isCurrentSection = section['section_number'] == widget.sectionNumber;

    final displaySection = isCurrentSection ? similarSection : section;
    final actName = displaySection['chapter']?['act']?['act_name'] ?? '';
    final formattedSectionNumber =
        _displaySectionNumber(displaySection['section_number']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Similar Section',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(123, 109, 217, 1),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.compare_arrows,
                  color: Color.fromRGBO(123, 109, 217, 1),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section $formattedSectionNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(123, 109, 217, 1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Get act names from the correct path in response
                  final sectionActName =
                      section['chapter']?['act']?['act_name'] ?? '';
                  final similarSectionActName =
                      similarSection['chapter']?['act']?['act_name'] ?? '';

                  // Determine which section is current and which is similar
                  final currentSection =
                      section['section_number'] == widget.sectionNumber
                          ? section
                          : similarSection;
                  final otherSection =
                      section['section_number'] == widget.sectionNumber
                          ? similarSection
                          : section;

                  // Get the corresponding act names
                  final currentActName =
                      currentSection['chapter']?['act']?['act_name'] ?? '';
                  final otherActName =
                      otherSection['chapter']?['act']?['act_name'] ?? '';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailedComparisonScreen(
                        selectedAct: currentActName,
                        selectedSection: currentSection['id'].toString(),
                        similarSectionData: _similarSectionData,
                        sections: [
                          {
                            'id': currentSection['id'].toString(),
                            'number': _displaySectionNumber(
                                currentSection['section_number']),
                            'title': currentSection['section_title'] ?? '',
                          },
                          {
                            'id': otherSection['id'].toString(),
                            'number': _displaySectionNumber(
                                otherSection['section_number']),
                            'title': otherSection['section_title'] ?? '',
                          }
                        ],
                        actMappings: {
                          currentActName: otherActName,
                          otherActName: currentActName,
                        },
                        filteredActs: [
                          {
                            'id': currentSection['chapter']?['act']?['id']
                                    .toString() ??
                                '1',
                            'name': currentActName,
                            'short_name': currentActName,
                          },
                          {
                            'id': otherSection['chapter']?['act']?['id']
                                    .toString() ??
                                '2',
                            'name': otherActName,
                            'short_name': otherActName,
                          }
                        ],
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View Detailed Comparison',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
