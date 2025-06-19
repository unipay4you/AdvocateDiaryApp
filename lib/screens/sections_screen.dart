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
  final int actbookId;

  const SectionsScreen({
    Key? key,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterTitleHindi,
    required this.chapterNumber,
    required this.actName,
    required this.actbookId,
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
  Map<String, bool> _expandedGroups = {};

  // Add function to get main section number
  String _getMainSectionNumber(String sectionNumber) {
    // Extract the main number before the parenthesis
    return sectionNumber.split('(')[0];
  }

  // Add function to check if section has subsections
  bool _hasSubsections(String mainSection) {
    return _filteredSections.any((section) =>
        section['section_number'].toString().startsWith('$mainSection('));
  }

  // Add function to get subsections for a main section
  List<dynamic> _getSubsections(String mainSection) {
    return _filteredSections
        .where((section) =>
            section['section_number'].toString().startsWith('$mainSection('))
        .toList()
      ..sort((a, b) {
        // Extract numbers from format like "2(1)" and "2(2)"
        final aMatch = RegExp(r'(\d+)\((\d+)\)')
            .firstMatch(a['section_number'].toString());
        final bMatch = RegExp(r'(\d+)\((\d+)\)')
            .firstMatch(b['section_number'].toString());

        if (aMatch != null && bMatch != null) {
          final aMain = int.parse(aMatch.group(1)!);
          final aSub = int.parse(aMatch.group(2)!);
          final bMain = int.parse(bMatch.group(1)!);
          final bSub = int.parse(bMatch.group(2)!);

          if (aMain == bMain) {
            return aSub.compareTo(bSub);
          }
          return aMain.compareTo(bMain);
        }
        return 0;
      });
  }

  // Add function to get main sections
  List<String> _getMainSections() {
    final mainSections = _filteredSections
        .map((section) =>
            _getMainSectionNumber(section['section_number'].toString()))
        .toSet()
        .toList();
    mainSections.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return mainSections;
  }

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

        // Sort filtered sections
        _sortSections(_filteredSections);
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

      // Prepare request body based on whether we're fetching all sections or chapter-specific sections
      final Map<String, dynamic> requestBody = widget.chapterId == 0
          ? {
              'chapter_id': 'all',
              'actbook_id': widget.actbookId,
            }
          : {
              'chapter_id': widget.chapterId,
            };

      print('Request Body: $requestBody');

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

            // Sort the sections by section number
            _sortSections(processedSections);

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
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final mainSection =
                                            _getMainSections()[index];
                                        final hasSubsections =
                                            _hasSubsections(mainSection);
                                        final isExpanded =
                                            _expandedGroups[mainSection] ??
                                                false;
                                        final subsections =
                                            _getSubsections(mainSection);

                                        return Column(
                                          children: [
                                            Card(
                                              elevation: 2,
                                              margin: EdgeInsets.zero,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: InkWell(
                                                onTap: hasSubsections
                                                    ? () {
                                                        setState(() {
                                                          _expandedGroups[
                                                                  mainSection] =
                                                              !isExpanded;
                                                        });
                                                      }
                                                    : () {
                                                        final section = _filteredSections
                                                            .firstWhere((s) =>
                                                                s['section_number']
                                                                    .toString() ==
                                                                mainSection);
                                                        _navigateToSection(
                                                            section);
                                                      },
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 12),
                                                  child: Row(
                                                    children: [
                                                      // Section Number
                                                      Container(
                                                        width: 60,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Section',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[600],
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                            Text(
                                                              mainSection,
                                                              style:
                                                                  const TextStyle(
                                                                color: Color
                                                                    .fromRGBO(
                                                                        123,
                                                                        109,
                                                                        217,
                                                                        1),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      // Section Title
                                                      Expanded(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12),
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              if (hasSubsections &&
                                                                  subsections
                                                                      .isNotEmpty) ...[
                                                                if (subsections[
                                                                            0][
                                                                        'section_title_hindi'] !=
                                                                    null)
                                                                  Text(
                                                                    subsections[
                                                                            0][
                                                                        'section_title_hindi'],
                                                                    style:
                                                                        const TextStyle(
                                                                      fontFamily:
                                                                          'Noto Sans Devanagari',
                                                                      fontSize:
                                                                          12,
                                                                      color: Colors
                                                                          .black87,
                                                                    ),
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                Text(
                                                                  subsections[0]
                                                                          [
                                                                          'section_title'] ??
                                                                      'Untitled Section',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ] else if (_filteredSections.any((s) =>
                                                                  s['section_number']
                                                                      .toString() ==
                                                                  mainSection)) ...[
                                                                Builder(
                                                                  builder:
                                                                      (context) {
                                                                    final section = _filteredSections.firstWhere((s) =>
                                                                        s['section_number']
                                                                            .toString() ==
                                                                        mainSection);
                                                                    return Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        if (section['section_title_hindi'] !=
                                                                            null)
                                                                          Text(
                                                                            section['section_title_hindi'],
                                                                            style:
                                                                                const TextStyle(
                                                                              fontFamily: 'Noto Sans Devanagari',
                                                                              fontSize: 12,
                                                                              color: Colors.black87,
                                                                            ),
                                                                            maxLines:
                                                                                1,
                                                                            overflow:
                                                                                TextOverflow.ellipsis,
                                                                          ),
                                                                        Text(
                                                                          section['section_title'] ??
                                                                              'Untitled Section',
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.black87,
                                                                          ),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ],
                                                                    );
                                                                  },
                                                                ),
                                                              ],
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      // Icon
                                                      if (hasSubsections)
                                                        Container(
                                                          width: 36,
                                                          height: 36,
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Color.fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    1),
                                                                Color.fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    0.8),
                                                              ],
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color
                                                                    .fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    0.3),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Icon(
                                                            isExpanded
                                                                ? Icons
                                                                    .expand_less
                                                                : Icons
                                                                    .expand_more,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        )
                                                      else
                                                        Container(
                                                          width: 36,
                                                          height: 36,
                                                          decoration:
                                                              BoxDecoration(
                                                            gradient:
                                                                const LinearGradient(
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                              colors: [
                                                                Color.fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    1),
                                                                Color.fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    0.8),
                                                              ],
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color
                                                                    .fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    0.3),
                                                                blurRadius: 4,
                                                                offset:
                                                                    const Offset(
                                                                        0, 2),
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
                                            ),
                                            if (hasSubsections && isExpanded)
                                              ...subsections
                                                  .map((subsection) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 16,
                                                                bottom: 12),
                                                    child: Card(
                                                      elevation: 1,
                                                          margin:
                                                              EdgeInsets.zero,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                      ),
                                                      child: InkWell(
                                                            onTap: () =>
                                                                _navigateToSection(
                                                                    subsection),
                                                        child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          16,
                                                                      vertical:
                                                                          12),
                                                          child: Row(
                                                            children: [
                                                              Expanded(
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                  children: [
                                                                        if (subsection['section_title_hindi'] !=
                                                                            null)
                                                                      Row(
                                                                        children: [
                                                                          Text(
                                                                            'Section ${subsection['section_number']} - ',
                                                                            style: const TextStyle(
                                                                              color: Color.fromRGBO(123, 109, 217, 1),
                                                                              fontWeight: FontWeight.w500,
                                                                              fontSize: 14,
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child: Text(
                                                                              subsection['section_title_hindi'],
                                                                              style: const TextStyle(
                                                                                fontFamily: 'Noto Sans Devanagari',
                                                                                fontWeight: FontWeight.w500,
                                                                                fontSize: 14,
                                                                                height: 1.3,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                        const SizedBox(
                                                                            height:
                                                                                2),
                                                                    Text(
                                                                          subsection['section_title'] ??
                                                                              'Untitled Section',
                                                                          style:
                                                                              const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize:
                                                                                14,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                width: 36,
                                                                height: 36,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      gradient:
                                                                          const LinearGradient(
                                                                        begin: Alignment
                                                                            .topLeft,
                                                                        end: Alignment
                                                                            .bottomRight,
                                                                    colors: [
                                                                          Color.fromRGBO(
                                                                              123,
                                                                              109,
                                                                              217,
                                                                              1),
                                                                          Color.fromRGBO(
                                                                              123,
                                                                              109,
                                                                              217,
                                                                              0.8),
                                                                        ],
                                                                      ),
                                                                      shape: BoxShape
                                                                          .circle,
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                          color: const Color
                                                                              .fromRGBO(
                                                                              123,
                                                                              109,
                                                                              217,
                                                                              0.3),
                                                                          blurRadius:
                                                                              4,
                                                                          offset: const Offset(
                                                                              0,
                                                                              2),
                                                                    ),
                                                                  ],
                                                                ),
                                                                    child:
                                                                        const Icon(
                                                                      Icons
                                                                          .arrow_forward,
                                                                      color: Colors
                                                                          .white,
                                                                  size: 18,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                      ))
                                                  .toList(),
                                          ],
                                        );
                                      },
                                      childCount: _getMainSections().length,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  void _navigateToSection(dynamic section) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionTextScreen(
          sectionTitle: section['section_title'],
          sectionTitleHindi: section['section_title_hindi'] ?? '',
          sectionText: section['section_text'],
          sectionTextHindi: section['section_text_hindi'] ?? '',
          sectionNumber: section['section_number'].toString(),
          sectionId: section['id'].toString(),
          actName: widget.actName,
        ),
      ),
    );
  }

  // Add function to get numerical value of section number
  double _getSectionNumberValue(String sectionNumber) {
    final match = RegExp(r'(\d+)\((\d+)\)').firstMatch(sectionNumber);
    if (match != null) {
      final main = int.parse(match.group(1)!);
      final sub = int.parse(match.group(2)!);
      return main +
          (sub / 100); // This will create values like 2.01, 2.02, etc.
    }
    return double.parse(sectionNumber);
  }

  // Add function to sort sections by number
  void _sortSections(List<dynamic> sections) {
    sections.sort((a, b) {
      final aValue = _getSectionNumberValue(a['section_number'].toString());
      final bValue = _getSectionNumberValue(b['section_number'].toString());
      return aValue.compareTo(bValue);
    });
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final bool hasSubsections;

  _SliverHeaderDelegate({
    required this.child,
    required this.hasSubsections,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: hasSubsections ? 85.0 : 65.0,
      color: const Color.fromRGBO(253, 255, 247, 1),
      child: child,
    );
  }

  @override
  double get maxExtent => hasSubsections ? 85.0 : 65.0;

  @override
  double get minExtent => hasSubsections ? 85.0 : 65.0;

  @override
  bool shouldRebuild(covariant _SliverHeaderDelegate oldDelegate) {
    return child != oldDelegate.child ||
        hasSubsections != oldDelegate.hasSubsections;
  }
}
