import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';

class DetailedComparisonScreen extends StatefulWidget {
  final String selectedAct;
  final String selectedSection;
  final Map<String, dynamic>? similarSectionData;
  final List<Map<String, String>> sections;
  final Map<String, String> actMappings;
  final List<Map<String, String>> filteredActs;

  const DetailedComparisonScreen({
    Key? key,
    required this.selectedAct,
    required this.selectedSection,
    required this.similarSectionData,
    required this.sections,
    required this.actMappings,
    required this.filteredActs,
  }) : super(key: key);

  @override
  State<DetailedComparisonScreen> createState() =>
      _DetailedComparisonScreenState();
}

class _DetailedComparisonScreenState extends State<DetailedComparisonScreen> {
  bool isLoading = false;
  Map<String, dynamic>? sectionDetails;
  Map<String, dynamic>? similarSectionDetails;
  String selectedLanguage = 'Hindi'; // Changed default language to Hindi
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: selectedLanguage == 'Hindi' ? 0 : 1);
    print('\n=== Initial Section Data ===');
    print('Selected Section ID: ${widget.selectedSection}');
    print('Similar Section Data: ${widget.similarSectionData}');
    _processSectionData();
  }

  void _processSectionData() {
    print('\n=== Processing Section Data ===');
    if (widget.similarSectionData != null) {
      // Get section details from the response
      final section = widget.similarSectionData!['section'];
      final similarSection = widget.similarSectionData!['similar_section'];

      print('Section Data:');
      print('Section Number: ${section['section_number']}');
      print('Section Title: ${section['section_title']}');
      print('Section Text: ${section['section_text']}');
      print('Section Text Hindi: ${section['section_text_hindi']}');

      print('\nSimilar Section Data:');
      print('Section Number: ${similarSection['section_number']}');
      print('Section Title: ${similarSection['section_title']}');
      print('Section Text: ${similarSection['section_text']}');
      print('Section Text Hindi: ${similarSection['section_text_hindi']}');

      // Determine which section belongs to which act by section id
      final selectedSectionId = widget.selectedSection;
      if (section['id'].toString() == selectedSectionId) {
        setState(() {
          sectionDetails = section;
          similarSectionDetails = similarSection;
        });
      } else {
        setState(() {
          sectionDetails = similarSection;
          similarSectionDetails = section;
        });
      }
    }
  }

  void _onLanguageToggle(String lang) {
    setState(() {
      selectedLanguage = lang;
      _currentPage = lang == 'Hindi' ? 0 : 1;
      _pageController.animateToPage(_currentPage,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
    });
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
          _buildToggleButton('English', selectedLanguage == 'English'),
          _buildToggleButton('हिंदी', selectedLanguage == 'Hindi'),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => _onLanguageToggle(text == 'English' ? 'English' : 'Hindi'),
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

  Widget _buildSectionCard(String title, Map<String, dynamic>? details) {
    print('\n=== Building Section Card ===');
    print('Title: $title');
    print('Details: $details');

    if (details == null) {
      print('Details is null for $title');
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'NA',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(123, 109, 217, 1),
              ),
            ),
            const SizedBox(height: 16),
            if (details['section_number'] != null)
              Text(
                'Section ${details['section_number']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (details['section_title'] != null) ...[
              const SizedBox(height: 8),
              Text(
                details['section_title'],
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    selectedLanguage = index == 0 ? 'Hindi' : 'English';
                    _currentPage = index;
                  });
                },
                children: [
                  // Hindi page
                  details['section_text_hindi'] != null
                      ? SingleChildScrollView(
                          child: Text(details['section_text_hindi'],
                              style: const TextStyle(fontSize: 14)))
                      : const Text('No text available in Hindi',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                  // English page
                  details['section_text'] != null
                      ? SingleChildScrollView(
                          child: Text(details['section_text'],
                              style: const TextStyle(fontSize: 14)))
                      : const Text('No text available in English',
                          style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedActName = widget.filteredActs
        .firstWhere((act) => act['short_name'] == widget.selectedAct)['name']!;
    final correspondingActName = widget.filteredActs.firstWhere((act) =>
        act['short_name'] == widget.actMappings[widget.selectedAct])['name']!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Detailed Comparison',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(width: 12),
            _buildLanguageToggle(),
          ],
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedActName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(123, 109, 217, 1),
                    ),
                    overflow: TextOverflow.ellipsis,
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
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(123, 109, 217, 1),
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionCard(selectedActName, sectionDetails),
            const SizedBox(height: 16),
            _buildSectionCard(correspondingActName, similarSectionDetails),
          ],
        ),
      ),
    );
  }
}
