import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'case_detail_screen.dart';

class FilteredCasesScreen extends StatefulWidget {
  final String filter;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> count;

  const FilteredCasesScreen({
    Key? key,
    required this.filter,
    required this.userData,
    required this.count,
  }) : super(key: key);

  @override
  State<FilteredCasesScreen> createState() => _FilteredCasesScreenState();
}

class _FilteredCasesScreenState extends State<FilteredCasesScreen> {
  List<dynamic> cases = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchFilteredCases();
  }

  Future<void> _fetchFilteredCases() async {
    try {
      print('\n=== Starting Filtered Cases Fetch ===');
      final apiService = ApiService();
      final token = await apiService.getAccessToken();
      print('Test 1: Got access token');

      print('Test 2: Sending filter request with filter: ${widget.filter}');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}case/filter/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'filter': widget.filter,
        }),
      );

      print('Test 3: Response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Test 4: Response data: $data');

        if (data['cases'] != null) {
          setState(() {
            cases = data['cases'] as List<dynamic>;
            isLoading = false;
          });
        } else {
          setState(() {
            cases = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load cases: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Test 5: Error in filtered cases fetch: $e');
      setState(() {
        error = 'Error loading cases: $e';
        isLoading = false;
      });
    }
  }

  String _getTitle() {
    switch (widget.filter) {
      case 'today':
        return "Today's Cases";
      case 'tommarow':
        return 'Tomorrow Cases';
      case 'date_awaited':
        return 'Date Awaited Cases';
      default:
        return 'All Cases';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchFilteredCases,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromRGBO(123, 109, 217, 1),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : cases.isEmpty
                  ? const Center(
                      child: Text(
                        'No cases found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(235, 235, 234, 1),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: cases.asMap().entries.map((entry) {
                                final index = entry.key;
                                final caseData = entry.value;
                                final isPetitioner = caseData['client_type']
                                        ?.toString()
                                        .toLowerCase() ==
                                    'petitioner';
                                final petitionerStyle = TextStyle(
                                  fontWeight: isPetitioner
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                );
                                final respondentStyle = TextStyle(
                                  fontWeight: !isPetitioner
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                );

                                return Column(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CaseDetailScreen(
                                                caseData: caseData,
                                                cases: cases,
                                                userData: widget.userData,
                                                count: widget.count,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color.fromRGBO(
                                                      123, 109, 217, 1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.gavel,
                                                    color: Colors.white,
                                                    size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            caseData[
                                                                    'petitioner'] ??
                                                                '',
                                                            style:
                                                                petitionerStyle,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      8),
                                                          child: Text('vs'),
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            caseData[
                                                                    'respondent'] ??
                                                                '',
                                                            style:
                                                                respondentStyle,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      '#${caseData['case_no']}/${caseData['case_year']}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'Court No: ${caseData['court_no']}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 16),
                                                        Text(
                                                          'Ref: ${caseData['sub_advocate'] ?? 'N/A'}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      caseData['stage_of_case'][
                                                              'stage_of_case'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Last: ${caseData['last_date'] ?? 'N/A'}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        Text(
                                                          'Next: ${caseData['next_date'] ?? 'N/A'}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                Colors.black87,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (index < cases.length - 1)
                                      const SizedBox(height: 4),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}
