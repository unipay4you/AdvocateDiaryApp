import 'package:flutter/material.dart';
import '../../../config/app_config.dart';
import 'case_detail_screen.dart';

class CasesListScreen extends StatefulWidget {
  final List<dynamic> cases;

  const CasesListScreen({
    Key? key,
    required this.cases,
  }) : super(key: key);

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredCases = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredCases = widget.cases;
    // Debug print to check data structure
    if (_filteredCases.isNotEmpty) {
      print('\n=== Case Data Structure ===');
      print('First case data: ${_filteredCases[0]}');
      print('District data: ${_filteredCases[0]['district']}');
      print('State data: ${_filteredCases[0]['state']}');
      print('=== End Case Data Structure ===\n');
    }
  }

  void _filterCases(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredCases = widget.cases;
      } else {
        _filteredCases = widget.cases.where((case_) {
          final searchLower = query.toLowerCase();

          // Search in all available fields
          final fields = [
            case_['case_no']?.toString() ?? '',
            case_['case_year']?.toString() ?? '',
            case_['petitioner']?.toString() ?? '',
            case_['respondent']?.toString() ?? '',
            case_['court_no']?.toString() ?? '',
            case_['district'] is Map
                ? case_['district']['district']?.toString() ?? ''
                : case_['district']?.toString() ?? '',
            case_['state'] is Map
                ? case_['state']['state']?.toString() ?? ''
                : case_['state']?.toString() ?? '',
            case_['advocate'] is Map
                ? case_['advocate']['user_name']?.toString() ?? ''
                : '',
            case_['last_date']?.toString() ?? '',
            case_['next_date']?.toString() ?? '',
            case_['case_title']?.toString() ?? '',
            case_['client_name']?.toString() ?? '',
          ];

          // Check if any field contains the search query
          return fields
              .any((field) => field.toLowerCase().contains(searchLower));
        }).toList();
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String selectedStatus = 'All';
        String selectedDate = 'All';

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Cases'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status Filter
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: ['All', 'Active', 'Closed', 'Undated']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedStatus = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Date Filter
                  DropdownButtonFormField<String>(
                    value: selectedDate,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    items: ['All', 'Today', 'This Week', 'This Month']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedDate = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply filters
                    setState(() {
                      _filteredCases = widget.cases.where((case_) {
                        bool statusMatch = true;
                        bool dateMatch = true;

                        // Status filter
                        if (selectedStatus != 'All') {
                          if (selectedStatus == 'Active') {
                            statusMatch = case_['is_active'] == true;
                          } else if (selectedStatus == 'Closed') {
                            statusMatch = case_['is_decided'] == true;
                          } else if (selectedStatus == 'Undated') {
                            if (case_['next_date'] == null) {
                              statusMatch = true;
                            } else {
                              final nextDate =
                                  DateTime.parse(case_['next_date']);
                              final today = DateTime.now();
                              final todayStart =
                                  DateTime(today.year, today.month, today.day);
                              final nextDateStart = DateTime(
                                  nextDate.year, nextDate.month, nextDate.day);
                              statusMatch = nextDateStart.isBefore(todayStart);
                            }
                          }
                        }

                        // Date filter
                        if (selectedDate != 'All' &&
                            case_['next_date'] != null) {
                          final nextDate = DateTime.parse(case_['next_date']);
                          final today = DateTime.now();
                          final todayStart =
                              DateTime(today.year, today.month, today.day);
                          final nextDateStart = DateTime(
                              nextDate.year, nextDate.month, nextDate.day);

                          if (selectedDate == 'Today') {
                            dateMatch =
                                nextDateStart.isAtSameMomentAs(todayStart);
                          } else if (selectedDate == 'This Week') {
                            final weekStart = todayStart
                                .subtract(Duration(days: today.weekday - 1));
                            final weekEnd =
                                weekStart.add(const Duration(days: 7));
                            dateMatch = nextDateStart.isAfter(weekStart) &&
                                nextDateStart.isBefore(weekEnd);
                          } else if (selectedDate == 'This Month') {
                            final monthStart =
                                DateTime(today.year, today.month, 1);
                            final monthEnd =
                                DateTime(today.year, today.month + 1, 0);
                            dateMatch = nextDateStart.isAfter(monthStart) &&
                                nextDateStart.isBefore(monthEnd);
                          }
                        }

                        return statusMatch && dateMatch;
                      }).toList();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'Cases List',
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
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search cases...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterCases('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: _filterCases,
                        onSubmitted: (value) {
                          if (_filteredCases.isNotEmpty) {
                            // Navigate to the first filtered case's details
                            _navigateToCaseDetails(_filteredCases[0]);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filter'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCases.isEmpty
                    ? const Center(
                        child: Text(
                          'No cases found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredCases.length,
                        itemBuilder: (context, index) {
                          final case_ = _filteredCases[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                '${case_['petitioner'] ?? 'No Petitioner'} vs ${case_['respondent'] ?? 'No Respondent'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    'Case No: ${case_['case_no'] ?? 'N/A'} / ${case_['case_year'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Court No: ${case_['court_no'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'District: ${case_['district'] != null ? (case_['district'] is Map ? case_['district']['district'] ?? 'N/A' : case_['district'].toString()) : 'N/A'}, ${case_['state'] != null ? (case_['state'] is Map ? case_['state']['state'] ?? 'N/A' : case_['state'].toString()) : 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Advocate: ${case_['advocate'] is Map ? case_['advocate']['user_name'] ?? 'N/A' : 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Last: ${case_['last_date'] != null ? DateTime.parse(case_['last_date'].toString()).toString().split(' ')[0] : 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Next: ${case_['next_date'] != null ? DateTime.parse(case_['next_date'].toString()).toString().split(' ')[0] : 'N/A'}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: case_['is_active'] == true
                                          ? const Color.fromRGBO(76, 175, 80, 1)
                                              .withOpacity(0.1)
                                          : const Color.fromRGBO(244, 67, 54, 1)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: case_['is_active'] == true
                                              ? const Color.fromRGBO(
                                                  76, 175, 80, 1)
                                              : const Color.fromRGBO(
                                                  244, 67, 54, 1),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          case_['is_active'] == true
                                              ? 'Active'
                                              : 'Closed',
                                          style: TextStyle(
                                            color: case_['is_active'] == true
                                                ? const Color.fromRGBO(
                                                    76, 175, 80, 1)
                                                : const Color.fromRGBO(
                                                    244, 67, 54, 1),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 20),
                                color: const Color.fromRGBO(255, 152, 0, 1),
                                onPressed: () {
                                  _navigateToCaseDetails(case_);
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _navigateToCaseDetails(Map<String, dynamic> case_) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaseDetailScreen(caseData: case_),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
