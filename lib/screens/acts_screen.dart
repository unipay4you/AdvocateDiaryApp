import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chapters_screen.dart';
import 'acts_comparison_screen.dart';

class ActsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ActsScreen({
    Key? key,
    required this.userData,
  }) : super(key: key);

  @override
  State<ActsScreen> createState() => _ActsScreenState();
}

class _ActsScreenState extends State<ActsScreen> {
  List<dynamic> _acts = [];
  List<dynamic> _filteredActs = [];
  bool _isLoading = true;
  String _error = '';
  final TextEditingController _searchController = TextEditingController();
  Set<String> _favorites = {};
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _favorites = _prefs.getStringList('favorite_acts')?.toSet() ?? {};
    _fetchActs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(String actId) async {
    setState(() {
      if (_favorites.contains(actId)) {
        _favorites.remove(actId);
      } else {
        _favorites.add(actId);
      }
    });

    // Save to shared preferences
    await _prefs.setStringList('favorite_acts', _favorites.toList());

    // Re-sort the list
    _sortActs();
  }

  void _sortActs() {
    setState(() {
      _filteredActs.sort((a, b) {
        final aIsFavorite = _favorites.contains(a['id'].toString());
        final bIsFavorite = _favorites.contains(b['id'].toString());

        if (aIsFavorite && !bIsFavorite) return -1;
        if (!aIsFavorite && bIsFavorite) return 1;

        // If both are favorites or both are not favorites, maintain original order
        return 0;
      });
    });
  }

  void _filterActs(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredActs = List.from(_acts);
      } else {
        _filteredActs = _acts.where((act) {
          final actName = act['act_name']?.toString().toLowerCase() ?? '';
          final actNameHindi =
              act['act_name_hindi']?.toString().toLowerCase() ?? '';
          final shortName =
              act['act_short_name']?.toString().toLowerCase() ?? '';
          final description =
              act['act_description']?.toString().toLowerCase() ?? '';
          final dateEnacted =
              act['act_date_enacted']?.toString().toLowerCase() ?? '';

          final searchQuery = query.toLowerCase();

          return actName.contains(searchQuery) ||
              actNameHindi.contains(searchQuery) ||
              shortName.contains(searchQuery) ||
              description.contains(searchQuery) ||
              dateEnacted.contains(searchQuery);
        }).toList();
      }
      _sortActs(); // Sort after filtering
    });
  }

  Future<void> _fetchActs() async {
    try {
      print('\n=== Fetching Acts Data ===');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Access token retrieved successfully');

      print('Making API request to: ${AppConfig.baseUrl}actbook/');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}actbook/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
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
            final List<dynamic> processedActs = [];
            for (var act in data['data']) {
              if (act['act_name_hindi'] != null) {
                final String hindiText = act['act_name_hindi'];
                String fixedText = hindiText;
                try {
                  if (hindiText.contains('à')) {
                    final bytes = latin1.encode(hindiText);
                    fixedText = utf8.decode(bytes);
                  }
                } catch (e) {
                  print('Error fixing encoding: $e');
                }

                final Map<String, dynamic> fixedAct =
                    Map<String, dynamic>.from(act);
                fixedAct['act_name_hindi'] = fixedText;
                processedActs.add(fixedAct);
              } else {
                processedActs.add(act);
              }
            }

            setState(() {
              _acts = processedActs;
              _filteredActs = List.from(processedActs);
              _sortActs(); // Sort after setting the acts
              _isLoading = false;
            });
          } else {
            setState(() {
              _acts = [];
              _filteredActs = [];
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
        print('Error: Failed to load acts. Status: ${response.statusCode}');
        setState(() {
          _error = 'Failed to load acts';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchActs: $e');
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
        title: const Text(
          'Acts',
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
        actions: [
          // Add Old Acts V/s New Acts button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ActsComparisonScreen(
                      userData: widget.userData,
                      acts: _acts,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.compare_arrows, size: 18),
              label: const Text('Old Acts V/s New Acts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search acts...',
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
              onChanged: _filterActs,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text(_error))
                    : _filteredActs.isEmpty
                        ? const Center(
                            child: Text(
                              'No acts found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchActs,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredActs.length,
                              itemBuilder: (context, index) {
                                final act = _filteredActs[index];
                                final isFavorite =
                                    _favorites.contains(act['id'].toString());

                                return Card(
                                  elevation: 2,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChaptersScreen(
                                            actbookId: act['id'],
                                            actName: act['act_name'] ??
                                                'Unnamed Act',
                                            actNameHindi:
                                                act['act_name_hindi'] ?? '',
                                            actPdf: act['act_pdf'],
                                            actPdfHindi: act['act_pdf_hindi'],
                                          ),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          // Act titles
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (act['act_name_hindi'] !=
                                                    null)
                                                  Text(
                                                    act['act_name_hindi'],
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'Noto Sans Devanagari',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                      height: 1.3,
                                                    ),
                                                  ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  act['act_name'] ??
                                                      'Unnamed Act',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Favorite button
                                          IconButton(
                                            icon: Icon(
                                              isFavorite
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFavorite
                                                  ? const Color.fromRGBO(
                                                      123, 109, 217, 1)
                                                  : Colors.grey,
                                            ),
                                            onPressed: () => _toggleFavorite(
                                                act['id'].toString()),
                                          ),
                                          const SizedBox(width: 8),
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
