import 'package:flutter/material.dart';
import '../utils/date_update_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config/app_config.dart';
import 'home_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
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
      body: TabBarView(
        controller: _tabController,
        children: [
          // Case Details Tab
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailCard(
                  'Case Information',
                  [
                    _buildDetailRow('CRN', widget.caseData['crn'] ?? 'N/A'),
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
                    _buildDetailRow(
                        'Court Type', widget.caseData['court_type'] ?? 'N/A'),
                    _buildDetailRow('Court',
                        '${widget.caseData['court_name'] ?? 'N/A'} (${widget.caseData['court_no'] ?? 'N/A'})'),
                    _buildDetailRow('Under Section',
                        widget.caseData['under_section'] ?? 'N/A'),
                    _buildDetailRow('Case Type',
                        widget.caseData['case_type']['case_type'] ?? 'N/A'),
                    _buildDetailRow(
                        'Stage',
                        widget.caseData['stage_of_case']['stage_of_case'] ??
                            'N/A'),
                    _buildDetailRow(
                        'Reference', widget.caseData['sub_advocate'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 4),
                _buildDetailCard(
                  'Parties',
                  [
                    _buildDetailRow(
                        'Petitioner', widget.caseData['petitioner'] ?? 'N/A'),
                    _buildDetailRow(
                        'Respondent', widget.caseData['respondent'] ?? 'N/A'),
                    _buildDetailRow(
                        'Client Type', widget.caseData['client_type'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 4),
                _buildDetailCard(
                  'Dates',
                  [
                    _buildDetailRow(
                        'Last Date', widget.caseData['last_date'] ?? 'N/A'),
                    _buildDetailRow(
                        'Next Date', widget.caseData['next_date'] ?? 'N/A'),
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
                    // First row - Edit Case and Clients buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.edit,
                            'Edit Case',
                            () {
                              // TODO: Implement edit case functionality
                            },
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            Icons.people,
                            'Clients',
                            () {
                              // TODO: Implement clients functionality
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Second row - Case History and Court Transfer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          Icons.history,
                          'Case History',
                          () async {
                            try {
                              print('\n=== Starting Case History Fetch ===');
                              final apiService = ApiService();
                              final token = await apiService.getAccessToken();
                              print('Test 1: Got access token');

                              print('Test 2: Sending case history request');
                              final response = await http.post(
                                Uri.parse('${AppConfig.baseUrl}case/history/'),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: json.encode({
                                  'id': widget.caseData['id'],
                                }),
                              );

                              print(
                                  'Test 3: Case history response status: ${response.statusCode}');
                              if (response.statusCode == 200) {
                                final responseData = json.decode(response.body);
                                print(
                                    'Test 4: Raw response data: $responseData');

                                // Extract the history data from the payload
                                final historyData =
                                    responseData['payload'] as List<dynamic>;
                                print(
                                    'Test 5: Extracted history data: $historyData');

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
                                            maxWidth: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.85,
                                          ),
                                          child: SingleChildScrollView(
                                            child: Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: const Color.fromRGBO(
                                                    253, 255, 247, 1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // Header
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
                                                                fontSize: 16,
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
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 16),
                                                                Text(
                                                                  widget.caseData[
                                                                          'court_no'] ??
                                                                      'N/A',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .blue,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
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
                                                  const SizedBox(height: 16),

                                                  // Case Info
                                                  Text(
                                                    'Case No: #${widget.caseData['case_no']}/${widget.caseData['case_year']}',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),

                                                  // History List
                                                  Container(
                                                    constraints: BoxConstraints(
                                                      maxHeight:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              0.5,
                                                    ),
                                                    child: ListView.builder(
                                                      shrinkWrap: true,
                                                      itemCount:
                                                          historyData.length,
                                                      itemBuilder:
                                                          (context, index) {
                                                        final historyItem =
                                                            historyData[index];
                                                        print(
                                                            'Test 6: Processing history item: $historyItem');
                                                        return Card(
                                                          margin:
                                                              const EdgeInsets
                                                                  .only(
                                                                  bottom: 8),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(12),
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
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            16),
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        historyItem['last_date'] ??
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
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 4),
                                                                const Text(
                                                                  'Hearing Purpose:',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .black87,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  historyItem[
                                                                          'stage'] ??
                                                                      'N/A',
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    color: Colors
                                                                        .blue,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                                if (historyItem[
                                                                            'particular']
                                                                        ?.isNotEmpty ??
                                                                    false) ...[
                                                                  const SizedBox(
                                                                      height:
                                                                          4),
                                                                  Row(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      const Text(
                                                                        'Comments: ',
                                                                        style:
                                                                            TextStyle(
                                                                          fontSize:
                                                                              14,
                                                                          color:
                                                                              Colors.black87,
                                                                        ),
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          historyItem[
                                                                              'particular'],
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
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ],
                                                                const SizedBox(
                                                                    height: 4),
                                                                Row(
                                                                  children: [
                                                                    const Text(
                                                                      'Next Hearing Date: ',
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        color: Colors
                                                                            .black87,
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        width:
                                                                            16),
                                                                    Expanded(
                                                                      child:
                                                                          Text(
                                                                        historyItem['next_date'] ??
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
                                print(
                                    'Test 7: Failed to fetch case history: ${response.body}');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Failed to fetch case history: ${response.body}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              print(
                                  'Test 8: Error in case history process: $e');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Error fetching case history: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                            print('=== End Case History Fetch ===\n');
                          },
                        ),
                        _buildActionButton(
                          context,
                          Icons.swap_horiz,
                          'Court Transfer',
                          () {
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
                itemCount: 0, // TODO: Replace with actual fee details count
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
          if (label == 'Next Date')
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.85,
                        ),
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(253, 255, 247, 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title with Petitioner vs Respondent
                                Text(
                                  '${widget.caseData['petitioner'] ?? 'N/A'} vs ${widget.caseData['respondent'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Case number and court information
                                Text(
                                  'Case No: #${widget.caseData['case_no']}/${widget.caseData['case_year']} | Court No: ${widget.caseData['court_no']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Next Date Field
                                Row(
                                  children: [
                                    const Text(
                                      'Next Date: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    StatefulBuilder(
                                      builder: (context, setState) {
                                        return TextButton(
                                          onPressed: () async {
                                            final DateTime? picked =
                                                await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.parse(widget
                                                      .caseData['next_date'] ??
                                                  DateTime.now()
                                                      .toIso8601String()),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              // Update the selected date
                                              widget.caseData['next_date'] =
                                                  picked
                                                      .toIso8601String()
                                                      .split('T')[0];
                                              // Update the UI to show the new date
                                              setState(() {});
                                            }
                                          },
                                          child: Text(
                                            widget.caseData['next_date'] ??
                                                'Select Date',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Stage Dropdown
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Stage: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future: _fetchStages(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return const CircularProgressIndicator();
                                        }
                                        if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        }
                                        final stages = snapshot.data ?? [];
                                        return DropdownButtonFormField<String>(
                                          value: widget
                                              .caseData['stage_of_case']['id']
                                              .toString(),
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 8),
                                          ),
                                          items: stages.map((stage) {
                                            return DropdownMenuItem(
                                              value: stage['id'].toString(),
                                              child: Text(
                                                stage['stage_of_case'],
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                          onChanged: (String? value) {
                                            if (value != null) {
                                              widget.caseData['stage_of_case'] =
                                                  {
                                                'id': value,
                                                'stage_of_case':
                                                    stages.firstWhere(
                                                  (stage) =>
                                                      stage['id'].toString() ==
                                                      value,
                                                  orElse: () =>
                                                      {'stage_of_case': ''},
                                                )['stage_of_case'],
                                              };
                                            }
                                          },
                                          selectedItemBuilder:
                                              (BuildContext context) {
                                            return stages.map((stage) {
                                              return Text(
                                                stage['stage_of_case'],
                                                style: const TextStyle(
                                                    fontSize: 14),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              );
                                            }).toList();
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Comments Field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Comments: ',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    TextField(
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter comments...',
                                        contentPadding:
                                            EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      onChanged: (value) {
                                        widget.caseData['comments'] = value;
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () async {
                                        print(
                                            '\n=== Starting Date Update Process ===');
                                        try {
                                          final apiService = ApiService();
                                          final token =
                                              await apiService.getAccessToken();
                                          print('Test 1: Got access token');

                                          print(
                                              'Test 2: Sending date update request');
                                          final response = await http.post(
                                            Uri.parse(
                                                '${AppConfig.baseUrl}case/dateupdate/'),
                                            headers: {
                                              'Authorization': 'Bearer $token',
                                              'Content-Type':
                                                  'application/json',
                                            },
                                            body: json.encode({
                                              'id': widget.caseData['id'],
                                              'next_date':
                                                  widget.caseData['next_date'],
                                              'stage': widget
                                                      .caseData['stage_of_case']
                                                  ['id'],
                                              'comments':
                                                  widget.caseData['comments'] ??
                                                      '',
                                            }),
                                          );

                                          print(
                                              'Test 3: Date update response status: ${response.statusCode}');
                                          if (response.statusCode == 200) {
                                            if (context.mounted) {
                                              print(
                                                  'Test 4: Showing success message');
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Date updated successfully'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );

                                              print('Test 5: Closing dialog');
                                              Navigator.pop(context);

                                              print(
                                                  'Test 6: Updating case data in detail screen');
                                              // Update the case data in the current screen
                                              setState(() {
                                                // The data is already updated in widget.caseData from the dialog
                                                print(
                                                    '  - New next date: ${widget.caseData['next_date']}');
                                                print(
                                                    '  - New stage: ${widget.caseData['stage_of_case']['stage_of_case']}');
                                              });
                                            }
                                          } else {
                                            print(
                                                'Test 7: Failed to update date: ${response.body}');
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Failed to update date: ${response.body}'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        } catch (e) {
                                          print(
                                              'Test 8: Error in date update process: $e');
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error updating date: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                        print(
                                            '=== End Date Update Process ===\n');
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color.fromRGBO(
                                            123, 109, 217, 1),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                      ),
                                      child: const Text('Update Date'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            )
          else
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
    VoidCallback onPressed,
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
