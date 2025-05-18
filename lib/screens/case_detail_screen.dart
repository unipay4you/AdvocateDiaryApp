import 'package:flutter/material.dart';
import '../utils/date_update_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'home_screen.dart';
import 'edit_case_screen.dart';

class CaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;
  final List<dynamic> cases;
  final Map<String, dynamic> userData;
  final Map<String, dynamic> count;

  const CaseDetailScreen({
    Key? key,
    required this.caseData,
    required this.cases,
    required this.userData,
    required this.count,
  }) : super(key: key);

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredCases = [];
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _filteredCases = List<Map<String, dynamic>>.from(
      widget.cases.map((case_) => case_ as Map<String, dynamic>).toList(),
    );
  }

  void _filterCases(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (query.isEmpty) {
        _filteredCases = List<Map<String, dynamic>>.from(
          widget.cases.map((case_) => case_ as Map<String, dynamic>).toList(),
        );
        _isSearchActive = false;
      } else {
        _filteredCases = widget.cases
            .where((case_) {
              final caseData = case_ as Map<String, dynamic>;
              final caseNo = '${caseData['case_no']}/${caseData['case_year']}'
                  .toLowerCase();
              final petitioner =
                  (caseData['petitioner'] ?? '').toString().toLowerCase();
              final respondent =
                  (caseData['respondent'] ?? '').toString().toLowerCase();
              final courtName =
                  (caseData['court_name'] ?? '').toString().toLowerCase();
              final caseType = (caseData['case_type']?['case_type'] ?? '')
                  .toString()
                  .toLowerCase();
              final crn = (caseData['crn'] ?? '').toString().toLowerCase();
              final firNumber =
                  (caseData['fir_number'] ?? '').toString().toLowerCase();

              return caseNo.contains(_searchQuery) ||
                  petitioner.contains(_searchQuery) ||
                  respondent.contains(_searchQuery) ||
                  courtName.contains(_searchQuery) ||
                  caseType.contains(_searchQuery) ||
                  crn.contains(_searchQuery) ||
                  firNumber.contains(_searchQuery);
            })
            .map((case_) => case_ as Map<String, dynamic>)
            .toList();
        _isSearchActive = true;
      }
    });
  }

  void _showAllCases() {
    // Reset search state
    _searchController.clear();
    _searchQuery = '';
    _isSearchActive = false;
    _filteredCases = List<Map<String, dynamic>>.from(
      widget.cases.map((case_) => case_ as Map<String, dynamic>).toList(),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.8,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(253, 255, 247, 1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'All Cases',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Test Label
                    const Text(
                      'TEST LABEL - Search Bar Should Be Here',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search Box
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
                        decoration: InputDecoration(
                          hintText: 'Search cases...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterCases('');
                                    setState(() {}); // Update dialog state
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (value) {
                          _filterCases(value);
                          setState(() {}); // Update dialog state
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cases List
                    Expanded(
                      child: _isSearchActive
                          ? _filteredCases.isEmpty
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
                                  itemCount: _filteredCases.length,
                                  itemBuilder: (context, index) {
                                    final case_ = _filteredCases[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        title: Text(
                                          '${case_['petitioner'] ?? 'N/A'} vs ${case_['respondent'] ?? 'N/A'}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Case No: #${case_['case_no']}/${case_['case_year']}',
                                            ),
                                            Text(
                                              'Court: ${case_['court_name'] ?? 'N/A'}',
                                            ),
                                          ],
                                        ),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16),
                                        onTap: () {
                                          Navigator.pop(context);
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  CaseDetailScreen(
                                                caseData: case_,
                                                cases: widget.cases,
                                                userData: widget.userData,
                                                count: widget.count,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                )
                          : ListView.builder(
                              itemCount: widget.cases.length,
                              itemBuilder: (context, index) {
                                final case_ =
                                    widget.cases[index] as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      '${case_['petitioner'] ?? 'N/A'} vs ${case_['respondent'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Case No: #${case_['case_no']}/${case_['case_year']}',
                                        ),
                                        Text(
                                          'Court: ${case_['court_name'] ?? 'N/A'}',
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16),
                                    onTap: () {
                                      Navigator.pop(context);
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CaseDetailScreen(
                                            caseData: case_,
                                            cases: widget.cases,
                                            userData: widget.userData,
                                            count: widget.count,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Text(
          'Case #${widget.caseData['case_no']}/${widget.caseData['case_year']}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(123, 109, 217, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(123, 109, 217, 1),
          tabs: const [
            Tab(text: 'Case Details'),
            Tab(text: 'Documents'),
            Tab(text: 'Fee Details'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Case Details Tab
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Original case details
                      _buildDetailCard(
                        'Case Information',
                        [
                          _buildDetailRow(
                              'CRN', widget.caseData['crn'] ?? 'N/A'),
                          _buildDetailRow('Case Number',
                              '#${widget.caseData['case_no']}/${widget.caseData['case_year']}'),
                          _buildDetailRow(
                              'FIR',
                              widget.caseData['fir_number'] != null &&
                                      widget.caseData['fir_number']
                                          .toString()
                                          .isNotEmpty
                                  ? '${widget.caseData['fir_number']}/${widget.caseData['fir_year'] ?? ''} ${widget.caseData['police_station'] != null ? 'ps ${widget.caseData['police_station']}' : ''}'
                                  : 'N/A'),
                          _buildDetailRow('Court Type',
                              widget.caseData['court_type'] ?? 'N/A'),
                          _buildDetailRow('Court',
                              '${widget.caseData['court_name'] ?? 'N/A'} (${widget.caseData['court_no'] ?? 'N/A'})'),
                          _buildDetailRow('Under Section',
                              widget.caseData['under_section'] ?? 'N/A'),
                          _buildDetailRow(
                              'Case Type',
                              widget.caseData['case_type']['case_type'] ??
                                  'N/A'),
                          _buildDetailRow(
                              'Stage',
                              widget.caseData['stage_of_case']
                                      ['stage_of_case'] ??
                                  'N/A'),
                          _buildDetailRow('Reference',
                              widget.caseData['sub_advocate'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildDetailCard(
                        'Parties',
                        [
                          _buildDetailRow('Petitioner',
                              widget.caseData['petitioner'] ?? 'N/A'),
                          _buildDetailRow('Respondent',
                              widget.caseData['respondent'] ?? 'N/A'),
                          _buildDetailRow('Client Type',
                              widget.caseData['client_type'] ?? 'N/A'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildDetailCard(
                        'Dates',
                        [
                          _buildDetailRow('Last Date',
                              widget.caseData['last_date'] ?? 'N/A'),
                          _buildDetailRow('Next Date',
                              widget.caseData['next_date'] ?? 'N/A'),
                        ],
                      ),
                      if (widget.caseData['comments']?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 4),
                        _buildDetailCard(
                          'Comments',
                          [
                            Text(
                              widget.caseData['comments'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  Icons.edit,
                                  'Edit Case',
                                  widget.caseData['is_desided'] == true ||
                                          widget.caseData['is_decided'] == true
                                      ? null
                                      : () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditCaseScreen(
                                                caseId: widget.caseData['id']
                                                    .toString(),
                                                userData: widget.userData,
                                                count: widget.count,
                                              ),
                                            ),
                                          );
                                        },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButton(
                                context,
                                Icons.history,
                                'Case History',
                                () async {
                                  try {
                                    final apiService = ApiService();
                                    final token =
                                        await apiService.getAccessToken();

                                    final response = await http.post(
                                      Uri.parse(
                                          '${AppConfig.baseUrl}case/history/'),
                                      headers: {
                                        'Authorization': 'Bearer $token',
                                        'Content-Type': 'application/json',
                                      },
                                      body: json.encode({
                                        'id': widget.caseData['id'],
                                      }),
                                    );

                                    if (response.statusCode == 200) {
                                      final responseData =
                                          json.decode(response.body);
                                      final historyData =
                                          responseData['payload']
                                              as List<dynamic>;

                                      if (context.mounted) {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return Dialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width *
                                                          0.85,
                                                ),
                                                child: SingleChildScrollView(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          const Color.fromRGBO(
                                                              253, 255, 247, 1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Text(
                                                                    '${widget.caseData['petitioner'] ?? 'N/A'} vs ${widget.caseData['respondent'] ?? 'N/A'}',
                                                                    style:
                                                                        const TextStyle(
                                                                      fontSize:
                                                                          16,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .black,
                                                                    ),
                                                                    maxLines: 2,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                  Row(
                                                                    children: [
                                                                      const Text(
                                                                        'Court: ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.black87,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                          width:
                                                                              16),
                                                                      Text(
                                                                        widget.caseData['court_no'] ??
                                                                            'N/A',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.blue,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                            IconButton(
                                                              icon: const Icon(
                                                                  Icons.close),
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 16),
                                                        Text(
                                                          'Case No: #${widget.caseData['case_no']}/${widget.caseData['case_year']}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Container(
                                                          constraints:
                                                              BoxConstraints(
                                                            maxHeight: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .height *
                                                                0.5,
                                                          ),
                                                          child:
                                                              ListView.builder(
                                                            shrinkWrap: true,
                                                            itemCount:
                                                                historyData
                                                                    .length,
                                                            itemBuilder:
                                                                (context,
                                                                    index) {
                                                              final historyItem =
                                                                  historyData[
                                                                      index];
                                                              return Card(
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            8),
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          12),
                                                                  child: Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Row(
                                                                        children: [
                                                                          const Text(
                                                                            'Business Date: ',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.black87,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 16),
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              historyItem['last_date'] ?? 'N/A',
                                                                              style: const TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.blue,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      const SizedBox(
                                                                          height:
                                                                              4),
                                                                      const Text(
                                                                        'Hearing Purpose:',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.black87,
                                                                        ),
                                                                      ),
                                                                      Text(
                                                                        historyItem['stage'] ??
                                                                            'N/A',
                                                                        style:
                                                                            const TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.blue,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      if (historyItem['particular']
                                                                              ?.isNotEmpty ??
                                                                          false) ...[
                                                                        const SizedBox(
                                                                            height:
                                                                                4),
                                                                        Row(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            const Text(
                                                                              'Comments: ',
                                                                              style: TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.black87,
                                                                              ),
                                                                            ),
                                                                            Expanded(
                                                                              child: Text(
                                                                                historyItem['particular'],
                                                                                style: const TextStyle(
                                                                                  fontSize: 14,
                                                                                  color: Colors.blue,
                                                                                  fontWeight: FontWeight.w500,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                      const SizedBox(
                                                                          height:
                                                                              4),
                                                                      Row(
                                                                        children: [
                                                                          const Text(
                                                                            'Next Hearing Date: ',
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14,
                                                                              color: Colors.black87,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                              width: 16),
                                                                          Expanded(
                                                                            child:
                                                                                Text(
                                                                              historyItem['next_date'] ?? 'N/A',
                                                                              style: const TextStyle(
                                                                                fontSize: 14,
                                                                                color: Colors.blue,
                                                                                fontWeight: FontWeight.w500,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to fetch case history: ${response.body}'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Error fetching case history: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              _buildActionButton(
                                context,
                                Icons.swap_horiz,
                                'Court Transfer',
                                widget.caseData['is_desided'] == true ||
                                        widget.caseData['is_decided'] == true
                                    ? null
                                    : () {
                                        // TODO: Implement court transfer functionality
                                      },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Documents Tab
                Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 0, // TODO: Replace with actual document count
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Document Name'),
                            subtitle: const Text('Uploaded on: Date'),
                            trailing: IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () {
                                // TODO: Implement document download
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        onPressed: () {
                          // TODO: Implement document upload functionality
                        },
                        backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                // Fee Details Tab
                Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount:
                          0, // TODO: Replace with actual fee details count
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: const Icon(Icons.payments),
                            title: const Text('Fee Type'),
                            subtitle: const Text('Amount: ₹0'),
                            trailing: Text(
                              'Date: DD/MM/YYYY',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: FloatingActionButton(
                        onPressed: () {
                          // TODO: Implement add fee functionality
                        },
                        backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback? onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStages() async {
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
        return data
            .map((stage) => {
                  'id': stage['id'],
                  'stage_of_case': stage['stage_of_case'],
                })
            .toList();
      } else {
        throw Exception('Failed to load stages');
      }
    } catch (e) {
      print('Error fetching stages: $e');
      return [];
    }
  }
}
