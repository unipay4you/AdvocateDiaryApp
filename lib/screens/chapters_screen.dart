import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'sections_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ChaptersScreen extends StatefulWidget {
  final int actbookId;
  final String actName;
  final String actNameHindi;
  final String? actPdf;
  final String? actPdfHindi;

  const ChaptersScreen({
    Key? key,
    required this.actbookId,
    required this.actName,
    required this.actNameHindi,
    this.actPdf,
    this.actPdfHindi,
  }) : super(key: key);

  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  List<dynamic> _chapters = [];
  List<dynamic> _filteredChapters = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChapters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterChapters(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChapters = List.from(_chapters);
      } else {
        _filteredChapters = _chapters.where((chapter) {
          final chapterTitle =
              chapter['chapter_title']?.toString().toLowerCase() ?? '';
          final chapterTitleHindi =
              chapter['chapter_title_hindi']?.toString().toLowerCase() ?? '';
          final chapterNumber =
              chapter['chapter_number']?.toString().toLowerCase() ?? '';
          final chapterDescription =
              chapter['chapter_description']?.toString().toLowerCase() ?? '';

          final searchQuery = query.toLowerCase();

          return chapterTitle.contains(searchQuery) ||
              chapterTitleHindi.contains(searchQuery) ||
              chapterNumber.contains(searchQuery) ||
              chapterDescription.contains(searchQuery);
        }).toList();
      }
    });
  }

  Future<void> _fetchChapters() async {
    try {
      print('\n=== Fetching Chapters Data ===');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Access token retrieved successfully');

      print('Making API request to: ${AppConfig.baseUrl}actbook/chapter/');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}actbook/chapter/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: json.encode({
          'actbook_id': widget.actbookId,
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
            final List<dynamic> processedChapters = [];
            for (var chapter in data['data']) {
              if (chapter['chapter_title_hindi'] != null) {
                final String hindiText = chapter['chapter_title_hindi'];
                String fixedText = hindiText;
                try {
                  if (hindiText.contains('à')) {
                    final bytes = latin1.encode(hindiText);
                    fixedText = utf8.decode(bytes);
                  }
                } catch (e) {
                  print('Error fixing encoding: $e');
                }

                final Map<String, dynamic> fixedChapter =
                    Map<String, dynamic>.from(chapter);
                fixedChapter['chapter_title_hindi'] = fixedText;
                processedChapters.add(fixedChapter);
              } else {
                processedChapters.add(chapter);
              }
            }

            setState(() {
              _chapters = processedChapters;
              _filteredChapters = List.from(processedChapters);
              _isLoading = false;
            });
          } else {
            setState(() {
              _chapters = [];
              _filteredChapters = [];
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
        print('Error: Failed to load chapters. Status: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load chapters';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchChapters: $e');
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPdf(String pdfPath) async {
    try {
      // Remove 'api' from the path if it exists
      String cleanPath = pdfPath.replaceAll('/api/', '/');
      // Remove any double slashes that might occur after removing 'api'
      cleanPath = cleanPath.replaceAll('//', '/');

      // Construct the URL without 'api'
      final baseUrl = AppConfig.baseUrl.replaceAll('/api/', '/');
      final url =
          '$baseUrl${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';

      print('\n=== PDF URL Debug ===');
      print('Original PDF Path: $pdfPath');
      print('Cleaned PDF Path: $cleanPath');
      print('Base URL: $baseUrl');
      print('Final PDF URL: $url');

      // Try to open in browser using Chrome first
      final Uri browserUri =
          Uri.parse('market://details?id=com.android.chrome');
      if (await canLaunchUrl(browserUri)) {
        // If Chrome is installed, open the URL in Chrome
        final Uri pdfUri = Uri.parse(url);
        await launchUrl(
          pdfUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // If Chrome is not installed, try to open in any browser
        final Uri pdfUri = Uri.parse(url);
        await launchUrl(
          pdfUri,
          mode: LaunchMode.platformDefault,
        );
      }
    } catch (e) {
      print('Error launching PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
              widget.actNameHindi,
              style: const TextStyle(
                fontFamily: 'Noto Sans Devanagari',
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            Text(
              widget.actName,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.download,
                color: Color.fromRGBO(123, 109, 217, 1)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Download PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(123, 109, 217, 1),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(123, 109, 217, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Color.fromRGBO(123, 109, 217, 1),
                            size: 18,
                          ),
                        ),
                        title: const Text(
                          'English PDF',
                          style: TextStyle(fontSize: 14),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.actPdf != null) {
                            _launchPdf(widget.actPdf!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('English PDF not available'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(123, 109, 217, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Color.fromRGBO(123, 109, 217, 1),
                            size: 18,
                          ),
                        ),
                        title: const Text(
                          'हिंदी PDF',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Noto Sans Devanagari',
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.actPdfHindi != null) {
                            _launchPdf(widget.actPdfHindi!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hindi PDF not available'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chapters...',
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
              onChanged: _filterChapters,
            ),
          ),
          // All Sections Tile
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  print('\n=== Navigating to All Sections ===');
                  print('Request Parameters:');
                  print('chapterId: 0');
                  print('chapterTitle: All Sections');
                  print('chapterTitleHindi: सभी धाराएं');
                  print('chapterNumber: 0');
                  print('actName: ${widget.actName}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectionsScreen(
                        chapterId: 0, // Special ID to indicate all sections
                        chapterTitle: 'All Sections',
                        chapterTitleHindi: 'सभी धाराएं',
                        chapterNumber: 0,
                        actName: widget.actName,
                        actbookId: widget.actbookId,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(123, 109, 217, 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.list_alt,
                          color: Color.fromRGBO(123, 109, 217, 1),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'सभी धाराएं',
                              style: TextStyle(
                                fontFamily: 'Noto Sans Devanagari',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'All Sections',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromRGBO(123, 109, 217, 1),
                              Color.fromRGBO(123, 109, 217, 0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(123, 109, 217, 0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
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
          ),
          // Chapter List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _filteredChapters.isEmpty
                        ? const Center(
                            child: Text(
                              'No chapters found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchChapters,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredChapters.length,
                              itemBuilder: (context, index) {
                                final chapter = _filteredChapters[index];
                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      print(
                                          '\n=== Navigating to Chapter Sections ===');
                                      print('Request Parameters:');
                                      print('chapterId: ${chapter['id']}');
                                      print(
                                          'chapterTitle: ${chapter['chapter_title'] ?? 'Untitled Chapter'}');
                                      print(
                                          'chapterTitleHindi: ${chapter['chapter_title_hindi'] ?? ''}');
                                      print(
                                          'chapterNumber: ${chapter['chapter_number']}');
                                      print('actName: ${widget.actName}');
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SectionsScreen(
                                            chapterId: chapter['id'],
                                            chapterTitle:
                                                chapter['chapter_title'] ??
                                                    'Untitled Chapter',
                                            chapterTitleHindi: chapter[
                                                    'chapter_title_hindi'] ??
                                                '',
                                            chapterNumber:
                                                chapter['chapter_number'],
                                            actName: widget.actName,
                                            actbookId: widget.actbookId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Chapter titles
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (chapter[
                                                        'chapter_title_hindi'] !=
                                                    null)
                                                  Row(
                                                    children: [
                                                      Text(
                                                        'Chapter ${chapter['chapter_number']} - ',
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
                                                          chapter[
                                                              'chapter_title_hindi'],
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
                                                  chapter['chapter_title'] ??
                                                      'Untitled Chapter',
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
