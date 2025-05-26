import 'package:flutter/material.dart';

class CaseDetailScreen extends StatelessWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailScreen({
    Key? key,
    required this.caseData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: const Text(
          'Case Details',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case Title
            Text(
              '${caseData['petitioner'] ?? 'No Petitioner'} vs ${caseData['respondent'] ?? 'No Respondent'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Case Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                        'Case ID', caseData['id']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildInfoRow('Case Number',
                        '${caseData['case_no'] ?? 'N/A'} / ${caseData['case_year'] ?? 'N/A'}'),
                    const Divider(),
                    _buildInfoRow(
                        'Court Number', caseData['court_no'] ?? 'N/A'),
                    const Divider(),
                    _buildInfoRow(
                        'District',
                        caseData['district'] is Map
                            ? caseData['district']['district'] ?? 'N/A'
                            : caseData['district']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildInfoRow(
                        'State',
                        caseData['state'] is Map
                            ? caseData['state']['state'] ?? 'N/A'
                            : caseData['state']?.toString() ?? 'N/A'),
                    const Divider(),
                    _buildInfoRow(
                        'Advocate',
                        caseData['advocate'] is Map
                            ? '${caseData['advocate']['user_name'] ?? 'N/A'} (${caseData['advocate']['phone_number'] ?? 'N/A'})'
                            : 'N/A'),
                    const Divider(),
                    _buildInfoRow('Client', caseData['client_name'] ?? 'N/A'),
                    const Divider(),
                    _buildInfoRow(
                        'Case Title', caseData['case_title'] ?? 'N/A'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dates Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Important Dates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDateRow('Last Date', caseData['last_date']),
                    const Divider(),
                    _buildDateRow('Next Date', caseData['next_date']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Case Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: caseData['is_active'] == true
                            ? const Color.fromRGBO(76, 175, 80, 1)
                                .withOpacity(0.1)
                            : const Color.fromRGBO(244, 67, 54, 1)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: caseData['is_active'] == true
                                ? const Color.fromRGBO(76, 175, 80, 1)
                                : const Color.fromRGBO(244, 67, 54, 1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            caseData['is_active'] == true ? 'Active' : 'Closed',
                            style: TextStyle(
                              color: caseData['is_active'] == true
                                  ? const Color.fromRGBO(76, 175, 80, 1)
                                  : const Color.fromRGBO(244, 67, 54, 1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, dynamic date) {
    String formattedDate = 'N/A';
    if (date != null) {
      try {
        final dateTime = DateTime.parse(date.toString());
        formattedDate =
            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = date.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            formattedDate,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
