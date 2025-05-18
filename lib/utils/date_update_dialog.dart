import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show min;
import '../config/app_config.dart';
import '../services/api_service.dart';

Future<bool?> showDateUpdateDialog(
  BuildContext context,
  Map<String, dynamic> caseData,
  List<dynamic> cases,
  Map<String, dynamic> userData,
  Map<String, dynamic> count,
  String filter,
) async {
  print('\n=== Starting Date Update Dialog ===');
  print('Test 1: Initializing dialog with case data');
  print('Case ID: ${caseData['id']}');
  print('Next Date: ${caseData['next_date']}');
  print('Stage: ${caseData['stage_of_case']}');

  // Parse the next date from caseData, default to current date if null
  final nextDateStr = caseData['next_date'] ?? DateTime.now().toIso8601String();
  DateTime selectedDate = DateTime.parse(nextDateStr);
  String? selectedStage = caseData['stage_of_case']['id'].toString();
  final TextEditingController commentsController = TextEditingController();
  final TextEditingController dateController = TextEditingController(
      text:
          '${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}');

  // Get token for API calls
  final apiService = ApiService();
  final token = await apiService.getAccessToken();

  // Function to format date input with separators
  String formatDateInput(String input, {bool isDeleting = false}) {
    // Remove all non-digit characters
    String digits = input.replaceAll(RegExp(r'[^\d]'), '');

    // Format the date with separators
    if (digits.isEmpty) {
      return '';
    } else if (digits.length <= 2) {
      return digits;
    } else if (digits.length <= 4) {
      return '${digits.substring(0, 2)}-${digits.substring(2)}';
    } else {
      return '${digits.substring(0, 2)}-${digits.substring(2, 4)}-${digits.substring(4, min(8, digits.length))}';
    }
  }

  // Function to handle backspace/delete
  void handleDateDeletion(TextEditingController controller, bool isBackspace) {
    final currentText = controller.text;
    final cursorPosition = controller.selection.baseOffset;

    if (currentText.isEmpty) return;

    // If cursor is at a separator, move it back one position
    if (cursorPosition > 0 && currentText[cursorPosition - 1] == '-') {
      controller.selection =
          TextSelection.collapsed(offset: cursorPosition - 1);
      return;
    }

    // Calculate the start and end of the current section (day, month, or year)
    int sectionStart = 0;
    int sectionEnd = currentText.length;

    if (cursorPosition <= 2) {
      // Day section
      sectionStart = 0;
      sectionEnd = 2;
    } else if (cursorPosition <= 5) {
      // Month section
      sectionStart = 3;
      sectionEnd = 5;
    } else {
      // Year section
      sectionStart = 6;
      sectionEnd = currentText.length;
    }

    // Get the current section
    String currentSection = currentText.substring(sectionStart, sectionEnd);

    // If section is empty, move to previous section
    if (currentSection.isEmpty || currentSection == '-') {
      if (sectionStart > 0) {
        controller.selection =
            TextSelection.collapsed(offset: sectionStart - 1);
      }
      return;
    }

    // Delete the last character in the current section
    String newText = currentText.substring(0, sectionEnd - 1) +
        currentText.substring(sectionEnd);

    // Format the new text
    String formattedText = formatDateInput(newText, isDeleting: true);

    // Update the text and cursor position
    controller.value = TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: sectionEnd - 1),
    );
  }

  // Function to show custom date picker
  Future<void> showCustomDatePicker(
      BuildContext context, StateSetter setState) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(123, 109, 217, 1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                child: child!,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color.fromRGBO(123, 109, 217, 0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, selectedDate);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(123, 109, 217, 1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null && context.mounted) {
      setState(() {
        selectedDate = picked;
        dateController.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  if (context.mounted) {
    print('Test 2: Showing dialog');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Fetch stages when dialog is opened
            Future<List<Map<String, dynamic>>> fetchStages() async {
              print('Test 3: Fetching stages from API');
              print('Access Token: ${token != null ? 'Present' : 'Missing'}');

              final stagesResponse = await http.get(
                Uri.parse('${AppConfig.baseUrl}case/stage/'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              print('Stages API Response Status: ${stagesResponse.statusCode}');
              print('Stages API Response Body: ${stagesResponse.body}');

              if (stagesResponse.statusCode == 200) {
                final List<dynamic> data = json.decode(stagesResponse.body);
                return data
                    .map((stage) => {
                          'id': stage['id'],
                          'stage_of_case': stage['stage_of_case'],
                        })
                    .toList();
              } else {
                print(
                    'Error: Failed to fetch stages. Status: ${stagesResponse.statusCode}');
                return [];
              }
            }

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchStages(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stages = snapshot.data ?? [];

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
                            Wrap(
                              spacing: 8,
                              children: [
                                Text(
                                  'Case No: #${caseData['case_no']}/${caseData['case_year']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '| Court No: ${caseData['court_no']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
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
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final DateTime? picked =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: selectedDate,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.light(
                                                primary: Color.fromRGBO(
                                                    123, 109, 217, 1),
                                                onPrimary: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          selectedDate = picked;
                                          dateController.text =
                                              '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: const Color.fromRGBO(
                                                123, 109, 217, 1)),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              dateController.text,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                  123, 109, 217, 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.calendar_today,
                                              size: 20,
                                              color: Color.fromRGBO(
                                                  123, 109, 217, 1),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.85,
                                  child: DropdownButtonFormField<String>(
                                    value: selectedStage,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding:
                                          EdgeInsets.symmetric(horizontal: 8),
                                    ),
                                    items: stages.map((stage) {
                                      return DropdownMenuItem(
                                        value: stage['id'].toString(),
                                        child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.58,
                                          child: Text(
                                            stage['stage_of_case'],
                                            style:
                                                const TextStyle(fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? value) {
                                      setState(() {
                                        selectedStage = value;
                                      });
                                    },
                                    selectedItemBuilder:
                                        (BuildContext context) {
                                      return stages.map((stage) {
                                        return Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.58,
                                          child: Text(
                                            stage['stage_of_case'],
                                            style:
                                                const TextStyle(fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
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
                                    try {
                                      // Validate the date format
                                      final parts =
                                          dateController.text.split('-');
                                      if (parts.length != 3) {
                                        throw Exception('Invalid date format');
                                      }

                                      final day = int.parse(parts[0]);
                                      final month = int.parse(parts[1]);
                                      final year = int.parse(parts[2]);

                                      // Validate date values
                                      if (day < 1 ||
                                          day > 31 ||
                                          month < 1 ||
                                          month > 12 ||
                                          year < 2000 ||
                                          year > 2100) {
                                        throw Exception('Invalid date values');
                                      }

                                      // Create the date object
                                      selectedDate = DateTime(year, month, day);

                                      print('\n=== Starting Date Update ===');
                                      print('Test 5: Validating date');
                                      // Get today's date at midnight for comparison
                                      final today = DateTime(
                                        DateTime.now().year,
                                        DateTime.now().month,
                                        DateTime.now().day,
                                      );
                                      print('Today: $today');
                                      print('Selected Date: $selectedDate');

                                      if (selectedDate.isBefore(today)) {
                                        print(
                                            'Error: Selected date is before today');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Next date cannot be before today'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      print('Test 6: Sending update request');
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

                                      print(
                                          'Update API Response Status: ${response.statusCode}');
                                      print(
                                          'Update API Response Body: ${response.body}');

                                      if (response.statusCode == 200) {
                                        print(
                                            'Test 7: Successfully updated date');
                                        final responseData =
                                            json.decode(response.body);
                                        if (responseData['status'] == 200 &&
                                            responseData['message'] ==
                                                'Date Updated') {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Date updated successfully'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                            Navigator.pop(context,
                                                true); // Return true for success
                                          }
                                        } else {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error: ${responseData['message']}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            Navigator.pop(context,
                                                false); // Return false for failure
                                          }
                                        }
                                      } else {
                                        print(
                                            'Error: Failed to update date. Status: ${response.statusCode}');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Failed to update date: ${response.body}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                          Navigator.pop(context,
                                              false); // Return false for failure
                                        }
                                      }
                                    } catch (e) {
                                      print(
                                          'Error: Exception during date update: $e');
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
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
