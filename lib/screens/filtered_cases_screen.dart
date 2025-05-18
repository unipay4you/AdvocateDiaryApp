import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'case_detail_screen.dart';
import '../utils/date_update_dialog.dart';

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
  Map<String, List<dynamic>> groupedCases = {};
  Map<String, bool> expandedGroups = {};
  Map<String, Map<String, List<dynamic>>> _groupedByMonth = {};
  bool _shouldRefresh = false;
  List<Map<String, dynamic>> stages = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    print('\n=== FilteredCasesScreen initState ===');
    print('Filter value: "${widget.filter}"');
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldRefresh) {
      print('\n=== FilteredCasesScreen didChangeDependencies ===');
      print('Test 1: Refreshing data on navigation back');
      _refreshData();
      _shouldRefresh = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchCases(),
      _fetchStages(),
    ]);
  }

  Future<void> _refreshData() async {
    print('Test 2: Starting refresh');
    setState(() {
      isLoading = true;
      cases = []; // Clear existing cases
      groupedCases = {}; // Clear grouped cases
      expandedGroups = {}; // Clear expanded groups
    });
    await _fetchCases(); // Fetch fresh data
    print('Test 3: Refresh completed');
  }

  String _getMonthName(String dateStr) {
    try {
      DateTime date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid Date';
    }
  }

  void _groupCasesByDate(List<dynamic> casesList) {
    Map<String, List<dynamic>> grouped = {};
    List<dynamic> decidedCases = [];
    List<dynamic> dateAwaitedCases = [];
    DateTime currentDate = DateTime.now();
    String currentDateStr = currentDate.toString().split(' ')[0];

    // Initialize special groups
    if (widget.filter != 'date_awaited') {
      grouped['Decided Cases'] = [];
      expandedGroups['Decided Cases'] = false;
    }

    grouped['Date Awaited Cases'] = [];
    expandedGroups['Date Awaited Cases'] = widget.filter == 'date_awaited';

    for (var case_ in casesList) {
      // Skip decided cases when viewing date awaited cases
      if (widget.filter == 'date_awaited' &&
          (case_['is_desided'] == true || case_['is_decided'] == true)) {
        continue;
      }

      if (widget.filter != 'date_awaited' &&
          (case_['is_desided'] == true || case_['is_decided'] == true)) {
        print('Moving case to decided group: ${case_['case_no']}');
        decidedCases.add(case_);
        continue;
      }

      String nextDate = case_['next_date'] ?? '';
      if (nextDate.isNotEmpty) {
        try {
          DateTime caseDate = DateTime.parse(nextDate);
          // Only move to date awaited if the date is before today (not today)
          if (caseDate.isBefore(currentDate) &&
              caseDate.toString().split(' ')[0] != currentDateStr) {
            dateAwaitedCases.add(case_);
            continue;
          }
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      if (!grouped.containsKey(nextDate)) {
        grouped[nextDate] = [];
        expandedGroups[nextDate] = nextDate == currentDateStr;
      }
      grouped[nextDate]!.add(case_);
    }

    // Add decided and date awaited cases to their groups
    if (widget.filter != 'date_awaited') {
      grouped['Decided Cases'] = decidedCases;
    }
    grouped['Date Awaited Cases'] = dateAwaitedCases;

    // Sort the dates (excluding special groups)
    List<String> sortedDates = grouped.keys
        .where((key) => key != 'Decided Cases' && key != 'Date Awaited Cases')
        .toList()
      ..sort((a, b) {
        if (a == 'No Date') return 1;
        if (b == 'No Date') return -1;
        return a.compareTo(b);
      });

    // Create a new ordered map with special groups at top
    Map<String, List<dynamic>> orderedGrouped = {};

    // Add groups in correct order based on filter
    if (widget.filter == 'date_awaited') {
      orderedGrouped['Date Awaited Cases'] = grouped['Date Awaited Cases']!;
    } else {
      orderedGrouped['Decided Cases'] = grouped['Decided Cases']!;
      orderedGrouped['Date Awaited Cases'] = grouped['Date Awaited Cases']!;
    }

    // Add remaining groups in sorted order
    for (String date in sortedDates) {
      orderedGrouped[date] = grouped[date]!;
    }

    setState(() {
      groupedCases = orderedGrouped;
    });
  }

  Future<void> _fetchCases() async {
    try {
      print('\n=== Starting _fetchCases ===');
      print('Current Filter: ${widget.filter}');

      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      final apiUrl = '${AppConfig.baseUrl}case/filter/';
      final requestBody = {
        'filter': widget.filter,
      };

      print('Test 2: Making API request');
      print('API Endpoint: $apiUrl');
      print('Request Body: ${json.encode(requestBody)}');
      print('Filter Type: ${_getFilterType(widget.filter)}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Test 3: API Response received');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Test 4: Data decoded successfully');
        print('Cases count: ${data['cases'].length}');
        print('Filtered for: ${_getFilterType(widget.filter)}');

        // Sort cases by next date
        List<dynamic> sortedCases = data['cases'] as List<dynamic>;
        sortedCases.sort((a, b) {
          String dateA = a['next_date'] ?? '';
          String dateB = b['next_date'] ?? '';

          // Handle empty dates by putting them at the end
          if (dateA.isEmpty) return 1;
          if (dateB.isEmpty) return -1;

          return dateA.compareTo(dateB);
        });

        print('Test 5: Setting state with sorted data');
        if (mounted) {
          setState(() {
            cases = sortedCases;
            isLoading = false;
            error = null;
          });
          _groupCasesByDate(sortedCases);
        }
        print('Test 6: State updated and cases grouped');
      } else {
        print('Test 8: API Error - ${response.statusCode}');
        if (mounted) {
          setState(() {
            error = 'Error: ${response.body}';
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      print('=== End _fetchCases ===\n');
    } catch (e) {
      print('Test 9: Exception caught - $e');
      if (mounted) {
        setState(() {
          error = 'Error: $e';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchStages() async {
    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}case/stage/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          stages = data
              .map((stage) => {
                    'id': stage['id'],
                    'stage_of_case': stage['stage_of_case'],
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load stages');
      }
    } catch (e) {
      print('Error fetching stages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to get human-readable filter type
  String _getFilterType(String filter) {
    switch (filter) {
      case 'date_awaited':
        return 'Date Awaited Cases';
      case 'today':
        return "Today's Cases";
      case 'tommarow':
        return 'Tomorrow Cases';
      case 'All':
        return 'All Cases';
      default:
        return 'Unknown Filter';
    }
  }

  Future<void> _showNextDateUpdateDialog(
      BuildContext context, Map<String, dynamic> caseData) async {
    print('\n=== Starting Next Date Update Dialog ===');
    print(
        'Test 1: Opening date update dialog for case: ${caseData['case_no']}');

    final bool? success = await showDateUpdateDialog(
      context,
      caseData,
      cases,
      widget.userData,
      widget.count,
      widget.filter,
    );

    print('Test 2: Date update dialog closed with success: $success');
    // Reload entire screen after dialog closes
    print('Test 3: Reloading screen after dialog close');

    if (mounted) {
      // Reload the entire screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FilteredCasesScreen(
            filter: widget.filter,
            userData: widget.userData,
            count: widget.count,
          ),
        ),
      );
    }
    print('=== End Next Date Update Dialog ===\n');
  }

  String _getTitle() {
    print('Getting title for filter: "${widget.filter}"');
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

  List<dynamic> _filterCases(List<dynamic> casesList) {
    if (_searchQuery.isEmpty) return casesList;

    return casesList.where((case_) {
      final searchLower = _searchQuery.toLowerCase();
      return case_['petitioner']
                  ?.toString()
                  .toLowerCase()
                  .contains(searchLower) ==
              true ||
          case_['respondent']
                  ?.toString()
                  .toLowerCase()
                  .contains(searchLower) ==
              true ||
          case_['case_no']?.toString().toLowerCase().contains(searchLower) ==
              true ||
          case_['court_no']?.toString().toLowerCase().contains(searchLower) ==
              true ||
          case_['court_name']?.toString().toLowerCase().contains(searchLower) ==
              true ||
          case_['sub_advocate']
                  ?.toString()
                  .toLowerCase()
                  .contains(searchLower) ==
              true;
    }).toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      if (cases.isNotEmpty) {
        final filteredCases = _filterCases(cases);
        if (_searchQuery.isEmpty) {
          _groupCasesByDate(filteredCases);
        } else {
          // When searching, show all results without grouping
          groupedCases = {'Search Results': filteredCases};
          expandedGroups = {'Search Results': true};
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building screen with filter: "${widget.filter}"');
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Text(
          _searchQuery.isNotEmpty ? 'Search Results' : _getTitle(),
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
                        onPressed: _fetchCases,
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
                  : RefreshIndicator(
                      onRefresh: _fetchCases,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Search Box - Show for All Cases (empty string)
                            if (widget.filter == '' ||
                                widget.filter == 'All') ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Search cases...',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear),
                                            onPressed: () {
                                              _searchController.clear();
                                              _onSearchChanged('');
                                            },
                                          )
                                        : null,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Grouped Cases List
                            ...groupedCases.entries.map((entry) {
                              if (entry.value.isEmpty)
                                return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Collapsible Date Header
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        expandedGroups[entry.key] =
                                            !(expandedGroups[entry.key] ??
                                                true);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: entry.key == 'Decided Cases'
                                            ? Colors.red
                                            : entry.key == 'Date Awaited Cases'
                                                ? Colors.orange
                                                : const Color.fromRGBO(
                                                    123, 109, 217, 1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '${entry.value.length}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(
                                                expandedGroups[entry.key] ??
                                                        true
                                                    ? Icons.expand_less
                                                    : Icons.expand_more,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Cases for this group (only if expanded)
                                  if (expandedGroups[entry.key] ?? true)
                                    ...entry.value.map((caseData) {
                                      return _buildCaseCard(caseData);
                                    }).toList(),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> caseData) {
    final isPetitioner =
        caseData['client_type']?.toString().toLowerCase() == 'petitioner';
    final petitionerStyle = TextStyle(
      fontWeight: isPetitioner ? FontWeight.bold : FontWeight.normal,
      fontSize: 16,
    );
    final respondentStyle = TextStyle(
      fontWeight: !isPetitioner ? FontWeight.bold : FontWeight.normal,
      fontSize: 16,
    );
    final isDecided =
        caseData['is_desided'] == true || caseData['is_decided'] == true;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color:
            isDecided ? const Color.fromRGBO(255, 240, 240, 1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(123, 109, 217, 1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gavel, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              caseData['petitioner'] ?? '',
                              style: petitionerStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('vs'),
                          ),
                          Expanded(
                            child: Text(
                              caseData['respondent'] ?? '',
                              style: respondentStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${caseData['case_no']}/${caseData['case_year']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Court No: ${caseData['court_no']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color.fromRGBO(123, 109, 217, 1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Ref: ${caseData['sub_advocate'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last: ${caseData['last_date'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: isDecided
                                ? null
                                : () async {
                                    final DateTime? picked =
                                        await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.parse(
                                          caseData['next_date'] ??
                                              DateTime.now().toIso8601String()),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      // Check if picked date is same as last date
                                      if (caseData['last_date'] != null &&
                                          picked
                                                  .toIso8601String()
                                                  .split('T')[0] ==
                                              caseData['last_date']) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Next date cannot be same as last date'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      // Show confirmation dialog
                                      final bool? confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                                'Confirm Date Update'),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Are you sure you want to update the next date to:',
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  picked
                                                      .toIso8601String()
                                                      .split('T')[0],
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromRGBO(
                                                        123, 109, 217, 1),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          123, 109, 217, 1),
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Update'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        try {
                                          final apiService = ApiService();
                                          final token =
                                              await apiService.getAccessToken();

                                          final response = await http.post(
                                            Uri.parse(
                                                '${AppConfig.baseUrl}case/dateupdate/'),
                                            headers: {
                                              'Authorization': 'Bearer $token',
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: json.encode({
                                              'id': caseData['id'],
                                              'next_date': picked
                                                  .toIso8601String()
                                                  .split('T')[0],
                                              'stage': caseData['stage_of_case']
                                                  ['id'],
                                              'comments': '',
                                            }),
                                          );

                                          if (response.statusCode == 200) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Next date updated successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              // Refresh the cases list
                                              _fetchCases();
                                            }
                                          } else {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to update next date: ${response.body}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error updating next date: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                            child: Text(
                              'Next: ${caseData['next_date'] ?? 'Not Available'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDecided ? Colors.grey : Colors.blue,
                                fontWeight: FontWeight.bold,
                                decoration: isDecided
                                    ? TextDecoration.none
                                    : TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Action Section
            Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 100, // Fixed width for close/reopen button
                      height: 40,
                      decoration: BoxDecoration(
                        color: caseData['is_desided'] == true ||
                                caseData['is_decided'] == true
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            final apiService = ApiService();
                            final token = await apiService.getAccessToken();

                            // Show confirmation dialog
                            final bool? confirm = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(caseData['is_desided'] == true ||
                                          caseData['is_decided'] == true
                                      ? 'Reopen Case'
                                      : 'Close Case'),
                                  content: Text(caseData['is_desided'] ==
                                              true ||
                                          caseData['is_decided'] == true
                                      ? 'Are you sure you want to reopen this case?'
                                      : 'Are you sure you want to close this case?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(
                                            123, 109, 217, 1),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              final response = await http.post(
                                Uri.parse('${AppConfig.baseUrl}case/close/'),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: json.encode({
                                  'id': caseData['id'],
                                  'is_desided':
                                      !(caseData['is_desided'] == true ||
                                          caseData['is_decided'] == true),
                                  'comments': '',
                                }),
                              );

                              if (response.statusCode == 200) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          caseData['is_desided'] == true ||
                                                  caseData['is_decided'] == true
                                              ? 'Case reopened successfully'
                                              : 'Case closed successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  // Refresh the cases list
                                  _fetchCases();
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to update case status: ${response.body}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Error updating case status: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          caseData['is_desided'] == true ||
                                  caseData['is_decided'] == true
                              ? Icons.refresh
                              : Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        label: Text(
                          caseData['is_desided'] == true ||
                                  caseData['is_decided'] == true
                              ? 'Reopen'
                              : 'Close',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color.fromRGBO(123, 109, 217, 1),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: caseData['stage_of_case']['id'].toString(),
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color.fromRGBO(123, 109, 217, 1),
                            ),
                            items: stages.map((stage) {
                              return DropdownMenuItem(
                                value: stage['id'].toString(),
                                child: Text(
                                  stage['stage_of_case'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: isDecided
                                ? null
                                : (String? value) async {
                                    if (value != null) {
                                      final selectedStage = stages.firstWhere(
                                        (stage) =>
                                            stage['id'].toString() == value,
                                        orElse: () => {'stage_of_case': ''},
                                      );

                                      // Show confirmation dialog
                                      final bool? confirm =
                                          await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                                'Confirm Stage Update'),
                                            content: Text(
                                                'Are you sure you want to update the stage to ${selectedStage['stage_of_case']}?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                    context, false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(
                                                    context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color.fromRGBO(
                                                          123, 109, 217, 1),
                                                  foregroundColor: Colors.white,
                                                ),
                                                child: const Text('Update'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirm == true) {
                                        try {
                                          final apiService = ApiService();
                                          final token =
                                              await apiService.getAccessToken();

                                          final response = await http.post(
                                            Uri.parse(
                                                '${AppConfig.baseUrl}case/dateupdate/'),
                                            headers: {
                                              'Authorization': 'Bearer $token',
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: json.encode({
                                              'id': caseData['id'],
                                              'next_date':
                                                  caseData['next_date'],
                                              'stage': value,
                                              'comments': '',
                                            }),
                                          );

                                          if (response.statusCode == 200) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Stage updated successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                              // Refresh the cases list
                                              _fetchCases();
                                            }
                                          } else {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to update stage: ${response.body}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error updating stage: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    }
                                  },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(
                              135, 206, 235, 1), // Light blue color
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaseDetailScreen(
                                  caseData: caseData,
                                  cases: cases,
                                  userData: widget.userData,
                                  count: widget.count,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(
                              135, 206, 235, 1), // Light blue color
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          onPressed: isDecided
                              ? null
                              : () async {
                                  try {
                                    final apiService = ApiService();
                                    final token =
                                        await apiService.getAccessToken();

                                    // Get district_id with fallback to '329'
                                    final districtId = caseData['court_id']
                                            ?['district'] ??
                                        '329';

                                    final requestBody = {
                                      'district_id': districtId,
                                    };
                                    print('\n=== GetCourt API Request ===');
                                    print(
                                        'Request Body: ${json.encode(requestBody)}');

                                    final response = await http.post(
                                      Uri.parse(
                                          '${AppConfig.baseUrl}getcourt/'),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Content-Type': 'application/json',
                                      },
                                      body: json.encode(requestBody),
                                    );

                                    print('\n=== GetCourt API Response ===');
                                    print(
                                        'Status Code: ${response.statusCode}');
                                    print('Response Body: ${response.body}');

                                    if (response.statusCode == 200) {
                                      final responseData =
                                          json.decode(response.body);
                                      List<dynamic> courts = [];

                                      if (responseData['status'] == 200 &&
                                          responseData['payload'] is List) {
                                        // Filter out current court from the list by comparing court_name and court_no
                                        courts = (responseData['payload']
                                                as List)
                                            .where((court) =>
                                                court['court_name'] !=
                                                    caseData['court_name'] ||
                                                court['court_no'] !=
                                                    caseData['court_no'])
                                            .toList();
                                        print(
                                            'Parsed Courts: ${courts.length} courts found (excluding current court)');
                                      } else {
                                        print(
                                            'Invalid response format or no courts found');
                                        courts = [];
                                      }

                                      if (!mounted) return;

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          String? selectedCourt;
                                          return StatefulBuilder(
                                            builder: (BuildContext context,
                                                StateSetter setDialogState) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Update New Court'),
                                                content: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Current Court:',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      caseData['court_name'] !=
                                                                  null &&
                                                              caseData[
                                                                      'court_no'] !=
                                                                  null
                                                          ? '${caseData['court_name']} (${caseData['court_no']})'
                                                          : 'No Court Assigned',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Color.fromRGBO(
                                                            123, 109, 217, 1),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 16),
                                                    const Text(
                                                      'Select New Court:',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12),
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                          color: const Color
                                                              .fromRGBO(
                                                              123, 109, 217, 1),
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child:
                                                          DropdownButtonHideUnderline(
                                                        child: DropdownButton<
                                                            String>(
                                                          value: selectedCourt,
                                                          isExpanded: true,
                                                          hint: const Text(
                                                              'Select Court'),
                                                          icon: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            color:
                                                                Color.fromRGBO(
                                                                    123,
                                                                    109,
                                                                    217,
                                                                    1),
                                                          ),
                                                          items: courts
                                                              .map((court) {
                                                            return DropdownMenuItem<
                                                                String>(
                                                              value: court['id']
                                                                  .toString(),
                                                              child: Text(
                                                                  '${court['court_name']} (${court['court_no']})'),
                                                            );
                                                          }).toList(),
                                                          onChanged: (String?
                                                              newValue) {
                                                            setDialogState(() {
                                                              selectedCourt =
                                                                  newValue;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      if (selectedCourt !=
                                                          null) {
                                                        // Show confirmation dialog
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Confirm Court Transfer'),
                                                              content: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  const Text(
                                                                    'Are you sure you want to transfer this case to:',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            14),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          8),
                                                                  Text(
                                                                    courts.firstWhere(
                                                                          (court) =>
                                                                              court['id'].toString() ==
                                                                              selectedCourt,
                                                                          orElse:
                                                                              () => {
                                                                            'court_name':
                                                                                'N/A',
                                                                            'court_no':
                                                                                'N/A'
                                                                          },
                                                                        )['court_name'] +
                                                                        ' (' +
                                                                        courts.firstWhere(
                                                                          (court) =>
                                                                              court['id'].toString() ==
                                                                              selectedCourt,
                                                                          orElse:
                                                                              () => {
                                                                            'court_name':
                                                                                'N/A',
                                                                            'court_no':
                                                                                'N/A'
                                                                          },
                                                                        )['court_no'] +
                                                                        ')',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          18,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Color.fromRGBO(
                                                                          123,
                                                                          109,
                                                                          217,
                                                                          1),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                          context),
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                      () async {
                                                                    try {
                                                                      final apiService =
                                                                          ApiService();
                                                                      final token =
                                                                          await apiService
                                                                              .getAccessToken();

                                                                      final response =
                                                                          await http
                                                                              .post(
                                                                        Uri.parse(
                                                                            '${AppConfig.baseUrl}getcourt/update/'),
                                                                        headers: {
                                                                          'Authorization':
                                                                              'Bearer $token',
                                                                          'Content-Type':
                                                                              'application/json',
                                                                        },
                                                                        body: json
                                                                            .encode({
                                                                          'case_id':
                                                                              caseData['id'],
                                                                          'court_id':
                                                                              selectedCourt,
                                                                        }),
                                                                      );

                                                                      print(
                                                                          '\n=== Court Transfer API Request ===');
                                                                      print(
                                                                          'Request URL: ${AppConfig.baseUrl}getcourt/update/');
                                                                      print(
                                                                          'Request Headers: ${json.encode({
                                                                            'Authorization':
                                                                                'Bearer $token',
                                                                            'Content-Type':
                                                                                'application/json',
                                                                          })}');
                                                                      print(
                                                                          'Request Body: ${json.encode({
                                                                            'case_id':
                                                                                caseData['id'],
                                                                            'court_id':
                                                                                selectedCourt,
                                                                          })}');

                                                                      print(
                                                                          '\n=== Court Transfer API Response ===');
                                                                      print(
                                                                          'Status Code: ${response.statusCode}');
                                                                      print(
                                                                          'Response Body: ${response.body}');

                                                                      final responseData =
                                                                          json.decode(
                                                                              response.body);
                                                                      if (responseData[
                                                                              'status'] ==
                                                                          200) {
                                                                        if (mounted) {
                                                                          Navigator.pop(
                                                                              context); // Close confirmation dialog
                                                                          Navigator.pop(
                                                                              context); // Close court selection dialog
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            const SnackBar(
                                                                              content: Text('Court transferred successfully'),
                                                                              backgroundColor: Colors.green,
                                                                            ),
                                                                          );
                                                                          // Refresh the cases list
                                                                          _fetchCases();
                                                                        }
                                                                      } else {
                                                                        if (mounted) {
                                                                          Navigator.pop(
                                                                              context); // Close confirmation dialog
                                                                          ScaffoldMessenger.of(context)
                                                                              .showSnackBar(
                                                                            SnackBar(
                                                                              content: Text('Error: ${responseData['message'] ?? 'Failed to transfer court'}'),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );
                                                                        }
                                                                      }
                                                                    } catch (e) {
                                                                      if (mounted) {
                                                                        Navigator.pop(
                                                                            context); // Close confirmation dialog
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(
                                                                          SnackBar(
                                                                            content:
                                                                                Text('Error transferring court: $e'),
                                                                            backgroundColor:
                                                                                Colors.red,
                                                                          ),
                                                                        );
                                                                      }
                                                                    }
                                                                  },
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        const Color
                                                                            .fromRGBO(
                                                                            123,
                                                                            109,
                                                                            217,
                                                                            1),
                                                                    foregroundColor:
                                                                        Colors
                                                                            .white,
                                                                  ),
                                                                  child: const Text(
                                                                      'Transfer'),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      } else {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                                'Please select a court'),
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                        );
                                                      }
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color.fromRGBO(
                                                              123, 109, 217, 1),
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                    child: const Text('Update'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    } else {
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Failed to load courts: ${response.body}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error loading courts: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Court',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
