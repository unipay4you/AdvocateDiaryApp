import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'section_text_screen.dart';
import 'detailed_comparison_screen.dart';

class SectionsScreen extends StatefulWidget {
  final int chapterId;
  final String chapterTitle;
  final String chapterTitleHindi;
  final int chapterNumber;
  final String actName;

  const SectionsScreen({
    Key? key,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterTitleHindi,
    required this.chapterNumber,
    required this.actName,
  }) : super(key: key);

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  List<dynamic> _sections = [];
  List<dynamic> _filteredSections = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _similarSectionData;

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSections(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSections = List.from(_sections);
      } else {
        _filteredSections = _sections.where((section) {
          final sectionTitle =
              section['section_title']?.toString().toLowerCase() ?? '';
          final sectionTitleHindi =
              section['section_title_hindi']?.toString().toLowerCase() ?? '';
          final sectionNumber =
              section['section_number']?.toString().toLowerCase() ?? '';
          final sectionText =
              section['section_text']?.toString().toLowerCase() ?? '';
          final sectionTextHindi =
              section['section_text_hindi']?.toString().toLowerCase() ?? '';

          final searchQuery = query.toLowerCase();

          return sectionTitle.contains(searchQuery) ||
              sectionTitleHindi.contains(searchQuery) ||
              sectionNumber.contains(searchQuery) ||
              sectionText.contains(searchQuery) ||
              sectionTextHindi.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _fetchSections() async {
    try {
      print('\n=== Fetching Sections Data ===');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Access token retrieved successfully');

      print('Making API request to: ${AppConfig.baseUrl}actbook/section/');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}actbook/section/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'chapter_id': widget.chapterId,
        }),
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
            final List<dynamic> processedSections = [];
            for (var section in data['data']) {
              if (section['section_title_hindi'] != null) {
                final String hindiText = section['section_title_hindi'];
                String fixedText = hindiText;
                try {
                  if (hindiText.contains('à')) {
                    final bytes = latin1.encode(hindiText);
                    fixedText = utf8.decode(bytes);
                  }
                } catch (e) {
                  print('Error fixing encoding: $e');
                }

                final Map<String, dynamic> fixedSection =
                    Map<String, dynamic>.from(section);
                fixedSection['section_title_hindi'] = fixedText;
                processedSections.add(fixedSection);
              } else {
                processedSections.add(section);
              }
            }

            setState(() {
              _sections = processedSections;
              _filteredSections = List.from(processedSections);
              _isLoading = false;
            });
          } else {
            setState(() {
              _sections = [];
              _filteredSections = [];
              _isLoading = false;
            });
          }
        } catch (e) {
          print('JSON Decoding Error: $e');
          setState(() {
            _error = 'Error decoding response: $e';
            _isLoading = false;
          });
        }
      } else {
        print('Error: Failed to load sections. Status: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load sections';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchSections: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<bool> _fetchSimilarSections(String sectionId) async {
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
              _similarSectionData = data['data'][0];
            });
            print('Similar section data loaded successfully');
            return true;
          } else {
            print('No similar sections found in response data');
            setState(() {
              _similarSectionData = null;
            });
            return false;
          }
        } catch (e) {
          print('JSON Decoding Error: $e');
          setState(() {
            _similarSectionData = null;
          });
          return false;
        }
      } else if (response.statusCode == 404) {
        print('No similar sections found (404)');
        setState(() {
          _similarSectionData = null;
        });
        return false;
      } else {
        print(
            'Error: Failed to load similar sections. Status: ${response.statusCode}');
        setState(() {
          _similarSectionData = null;
        });
        return false;
      }
    } catch (e) {
      print('Error in _fetchSimilarSections: $e');
      setState(() {
        _similarSectionData = null;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.actName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              'Chapter ${widget.chapterNumber} - ${widget.chapterTitle}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sections...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(123, 109, 217, 1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(123, 109, 217, 1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(123, 109, 217, 1),
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: _filterSections,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _filteredSections.isEmpty
                        ? const Center(
                            child: Text(
                              'No sections found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchSections,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredSections.length,
                              itemBuilder: (context, index) {
                                final section = _filteredSections[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SectionTextScreen(
                                            sectionTitle:
                                                section['section_title'],
                                            sectionTitleHindi: section[
                                                    'section_title_hindi'] ??
                                                '',
                                            sectionText:
                                                section['section_text'],
                                            sectionTextHindi:
                                                section['section_text_hindi'] ??
                                                    '',
                                            sectionNumber:
                                                section['section_number']
                                                    .toString(),
                                            sectionId: section['id'].toString(),
                                            actName: widget.actName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Section titles
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (section[
                                                        'section_title_hindi'] !=
                                                    null)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Section ${section['section_number']} - ',
                                                        style: const TextStyle(
                                                          color: Color.fromRGBO(
                                                              123, 109, 217, 1),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          section[
                                                              'section_title_hindi'],
                                                          style:
                                                              const TextStyle(
                                                            fontFamily:
                                                                'Noto Sans Devanagari',
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 14,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  section['section_title'] ??
                                                      'Untitled Section',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Enter icon
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color.fromRGBO(
                                                      123, 109, 217, 1),
                                                  Color.fromRGBO(
                                                      123, 109, 217, 0.8),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color.fromRGBO(
                                                      123, 109, 217, 0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
