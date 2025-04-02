import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../services/api_service.dart';

Future<void> showDateUpdateDialog(
  BuildContext context,
  Map<String, dynamic> caseData,
  List<dynamic> cases,
  Map<String, dynamic> userData,
  Map<String, dynamic> count,
) async {
  // Parse the next date from caseData, default to current date if null
  final nextDateStr = caseData['next_date'] ?? DateTime.now().toIso8601String();
  DateTime selectedDate = DateTime.parse(nextDateStr);
  String? selectedStage = caseData['stage_of_case']['id'].toString();
  final TextEditingController commentsController = TextEditingController();

  // Fetch stages
  final apiService = ApiService();
  final token = await apiService.getAccessToken();
  final stagesResponse = await http.get(
    Uri.parse('${AppConfig.baseUrl}case/stage/'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  List<Map<String, dynamic>> stages = [];
  if (stagesResponse.statusCode == 200) {
    final List<dynamic> data = json.decode(stagesResponse.body);
    stages = data
        .map((stage) => {
              'id': stage['id'],
              'stage_of_case': stage['stage_of_case'],
            })
        .toList();
  }

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                          '${caseData['petitioner'] ?? 'N/A'} vs ${caseData['respondent'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Case number and court information
                        Text(
                          'Case No: #${caseData['case_no']}/${caseData['case_year']} | Court No: ${caseData['court_no']}',
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
                            TextButton(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                  });
                                }
                              },
                              child: Text(
                                '${selectedDate.day.toString().padLeft(2, '0')} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue,
                                ),
                              ),
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
                            DropdownButtonFormField<String>(
                              value: selectedStage,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
                              items: stages.map((stage) {
                                return DropdownMenuItem(
                                  value: stage['id'].toString(),
                                  child: Text(
                                    stage['stage_of_case'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  selectedStage = value;
                                });
                              },
                              selectedItemBuilder: (BuildContext context) {
                                return stages.map((stage) {
                                  return Text(
                                    stage['stage_of_case'],
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  );
                                }).toList();
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
                              controller: commentsController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: 'Enter comments...',
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 8),
                              ),
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
                                // Parse last date from caseData
                                final lastDateStr = caseData['last_date'] ?? '';
                                final lastDate = DateTime.tryParse(lastDateStr);

                                if (lastDate != null &&
                                    selectedDate.isBefore(lastDate)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Next date cannot be before or equal to the last date'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  final response = await http.post(
                                    Uri.parse(
                                        '${AppConfig.baseUrl}case/dateupdate/'),
                                    headers: {
                                      'Authorization': 'Bearer $token',
                                      'Content-Type': 'application/json',
                                    },
                                    body: json.encode({
                                      'id': caseData['id'],
                                      'next_date': selectedDate
                                          .toIso8601String()
                                          .split('T')[0],
                                      'stage': selectedStage,
                                      'comments': commentsController.text,
                                    }),
                                  );

                                  if (response.statusCode == 200) {
                                    if (context.mounted) {
                                      // Update the case data in the list
                                      final updatedCaseData =
                                          Map<String, dynamic>.from(caseData);
                                      updatedCaseData['next_date'] =
                                          selectedDate
                                              .toIso8601String()
                                              .split('T')[0];
                                      updatedCaseData['stage_of_case'] = {
                                        'id': selectedStage,
                                        'stage_of_case': stages.firstWhere(
                                          (stage) =>
                                              stage['id'].toString() ==
                                              selectedStage,
                                          orElse: () => {'stage_of_case': ''},
                                        )['stage_of_case'],
                                      };

                                      // Update the case in the cases list
                                      final caseIndex = cases.indexWhere(
                                          (c) => c['id'] == caseData['id']);
                                      if (caseIndex != -1) {
                                        cases[caseIndex] = updatedCaseData;
                                      }

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Date updated successfully'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      Navigator.pop(context); // Close dialog
                                    }
                                  } else {
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
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Error updating date: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(123, 109, 217, 1),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
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
    );
  }
}

String _getMonthName(int month) {
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return monthNames[month - 1];
}
