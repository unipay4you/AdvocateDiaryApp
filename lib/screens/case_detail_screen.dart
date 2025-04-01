import 'package:flutter/material.dart';

class CaseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailScreen({
    Key? key,
    required this.caseData,
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
            padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                Column(
                  children: [
                    // First row - Edit Case button
                    SizedBox(
                      width: double.infinity,
                      child: _buildActionButton(
                        context,
                        Icons.edit,
                        'Edit Case',
                        () {
                          // TODO: Implement edit case functionality
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Second row - Case History and Court Transfer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          Icons.history,
                          'Case History',
                          () {
                            // TODO: Implement case history functionality
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
            const SizedBox(height: 12),
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
}
