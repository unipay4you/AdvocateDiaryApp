import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CourtsListScreen extends StatefulWidget {
  const CourtsListScreen({Key? key}) : super(key: key);

  @override
  State<CourtsListScreen> createState() => _CourtsListScreenState();
}

class _CourtsListScreenState extends State<CourtsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _courts = [];
  List<dynamic> _filteredCourts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Filter states
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedCourtType;

  // Filter options
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _courtTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() => _isLoading = true);
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      print('\n=== Fetching Courts Data ===');
      // Fetch courts
      final courtsResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}superadmin/courts/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Courts Response Status: ${courtsResponse.statusCode}');
      print('Courts Response Body: ${courtsResponse.body}');

      if (courtsResponse.statusCode == 200) {
        final courtsData = json.decode(courtsResponse.body);
        print('\nParsed Courts Data: ${courtsData['court']}');

        setState(() {
          _courts = courtsData['court'] ?? [];
          _filteredCourts = List.from(_courts);

          print('\nUpdated State:');
          print('Courts Count: ${_courts.length}');
          print('Filtered Courts Count: ${_filteredCourts.length}');
          print(
              'First Court Data: ${_courts.isNotEmpty ? _courts.first : 'No courts'}');
        });
      } else {
        throw Exception('Failed to load courts data');
      }
    } catch (e) {
      print('\n=== Error in _fetchData ===');
      print('Error details: $e');
      print('=== End Error Log ===\n');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStatesAndDistricts() async {
    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      print('\n=== Fetching States and Districts ===');

      // Fetch districts (which includes states data)
      final districtsResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getdistrict/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Districts Response Status: ${districtsResponse.statusCode}');
      print('Districts Response Body: ${districtsResponse.body}');

      if (districtsResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(districtsResponse.body);

        // Use Map to ensure distinct states by ID
        final Map<int, Map<String, dynamic>> uniqueStatesMap = {};
        final List<Map<String, dynamic>> districts = [];

        for (var item in data) {
          // Add state if not already present (using ID as key)
          if (item['state'] != null) {
            final stateId = item['state']['id'];
            if (!uniqueStatesMap.containsKey(stateId)) {
              uniqueStatesMap[stateId] = {
                'id': stateId,
                'name': item['state']['state'],
              };
            }
          }

          // Add district with its state reference
          districts.add({
            'id': item['id'],
            'name': item['district'],
            'state_id': item['state']['id'],
          });
        }

        // Sort states alphabetically without case sensitivity
        final sortedStates = uniqueStatesMap.values.toList()
          ..sort((a, b) => a['name']
              .toString()
              .toLowerCase()
              .compareTo(b['name'].toString().toLowerCase()));

        // Sort districts alphabetically without case sensitivity
        districts.sort((a, b) => a['name']
            .toString()
            .toLowerCase()
            .compareTo(b['name'].toString().toLowerCase()));

        setState(() {
          _states = sortedStates;
          _districts = districts;
        });

        print('\nUpdated Filter Data:');
        print('States Count: ${_states.length}');
        print('Districts Count: ${_districts.length}');
      } else {
        throw Exception('Failed to load states and districts data');
      }

      // Fetch court types
      print('\n=== Fetching Court Types ===');
      final courtTypesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getcourttype/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Court Types Response Status: ${courtTypesResponse.statusCode}');
      print('Court Types Response Body: ${courtTypesResponse.body}');

      if (courtTypesResponse.statusCode == 200) {
        final List<dynamic> courtTypesData =
            json.decode(courtTypesResponse.body);
        // Sort court types alphabetically without case sensitivity
        final sortedCourtTypes = courtTypesData
            .map((type) => {
                  'id': type['id'],
                  'name': type['court_type'],
                })
            .toList()
          ..sort((a, b) => a['name']
              .toString()
              .toLowerCase()
              .compareTo(b['name'].toString().toLowerCase()));

        setState(() {
          _courtTypes = sortedCourtTypes;
        });
        print('Court Types Count: ${_courtTypes.length}');
      } else {
        throw Exception('Failed to load court types data');
      }
    } catch (e) {
      print('\n=== Error in _fetchStatesAndDistricts ===');
      print('Error details: $e');
      print('=== End Error Log ===\n');
    }
  }

  String _getStateName(int stateId) {
    // Since state info is now in the nested district object, we'll get it directly from there
    return 'N/A';
  }

  String _getDistrictName(int districtId) {
    // Since district info is now in the nested district object, we'll get it directly from there
    return 'N/A';
  }

  String _getCourtTypeName(int courtTypeId) {
    // Since court type info is now in the nested structure, we'll get it directly from there
    return 'N/A';
  }

  void _filterCourts() {
    setState(() {
      _filteredCourts = _courts.where((court) {
        bool matchesSearch = true;
        bool matchesState = true;
        bool matchesDistrict = true;
        bool matchesCourtType = true;

        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final courtName = court['court_name']?.toString().toLowerCase() ?? '';
          final courtNumber = court['court_no']?.toString().toLowerCase() ?? '';
          final stateName =
              court['district']?['state']?['state']?.toString().toLowerCase() ??
                  '';
          final districtName =
              court['district']?['district']?.toString().toLowerCase() ?? '';
          final courtType =
              court['court_type']?['court_type']?.toString().toLowerCase() ??
                  '';

          // Split search query into words for more flexible matching
          final searchWords =
              searchLower.split(' ').where((word) => word.isNotEmpty).toList();

          // Check if all search words are found in any of the fields
          matchesSearch = searchWords.every((word) =>
              courtName.contains(word) ||
              courtNumber.contains(word) ||
              stateName.contains(word) ||
              districtName.contains(word) ||
              courtType.contains(word));
        }

        // State filter
        if (_selectedState != null && _selectedState != 'All') {
          final selectedStateId = _states
              .firstWhere((state) => state['name'] == _selectedState)['id'];
          matchesState = court['district']?['state']?['id'] == selectedStateId;
        }

        // District filter
        if (_selectedDistrict != null && _selectedDistrict != 'All') {
          final selectedDistrictId = _districts.firstWhere(
              (district) => district['name'] == _selectedDistrict)['id'];
          matchesDistrict = court['district']?['id'] == selectedDistrictId;
        }

        // Court type filter
        if (_selectedCourtType != null && _selectedCourtType != 'All') {
          final selectedCourtTypeId = _courtTypes
              .firstWhere((type) => type['name'] == _selectedCourtType)['id'];
          matchesCourtType = court['court_type']?['id'] == selectedCourtTypeId;
        }

        return matchesSearch &&
            matchesState &&
            matchesDistrict &&
            matchesCourtType;
      }).toList();
    });
  }

  void _showFilterDialog() async {
    print('\n=== Opening Filter Dialog ===');
    try {
      // Fetch states and districts when opening the filter dialog
      await _fetchStatesAndDistricts();
      print('States and Districts fetched successfully');

      if (!mounted) {
        print('Widget not mounted, returning');
        return;
      }

      print('Showing filter dialog');
      if (!context.mounted) {
        print('Context not mounted, returning');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          print('Building filter dialog');
          return StatefulBuilder(
            builder: (context, setState) {
              // Get districts for selected state
              List<Map<String, dynamic>> filteredDistricts = [];
              if (_selectedState != null && _selectedState != 'All') {
                final selectedStateId = _states.firstWhere(
                    (state) => state['name'] == _selectedState)['id'];
                filteredDistricts = _districts
                    .where(
                        (district) => district['state_id'] == selectedStateId)
                    .toList();
              } else {
                filteredDistricts = _districts;
              }

              return AlertDialog(
                title: const Text('Filter Courts'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // State Filter
                      DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'All',
                            child: Text('All States'),
                          ),
                          ..._states.map((state) {
                            return DropdownMenuItem<String>(
                              value: state['name'],
                              child: Text(state['name']),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedState = newValue;
                            // Reset district when state changes
                            _selectedDistrict = 'All';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // District Filter
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        decoration: const InputDecoration(
                          labelText: 'District',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'All',
                            child: Text('All Districts'),
                          ),
                          ...filteredDistricts.map((district) {
                            return DropdownMenuItem<String>(
                              value: district['name'],
                              child: Text(district['name']),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDistrict = newValue;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Court Type Filter
                      DropdownButtonFormField<String>(
                        value: _selectedCourtType,
                        decoration: const InputDecoration(
                          labelText: 'Court Type',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: 'All',
                            child: Text('All Court Types'),
                          ),
                          ..._courtTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type['name'],
                              child: Text(type['name']),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCourtType = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      print('Filter dialog cancelled');
                      Navigator.pop(context);
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      print('Applying filters');
                      Navigator.pop(context);
                      _filterCourts();
                    },
                    child: const Text('Apply'),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      print('\n=== Error in _showFilterDialog ===');
      print('Error details: $e');
      print('=== End Error Log ===\n');
    }
  }

  void _showAddCourtDialog() async {
    String? selectedState;
    String? selectedDistrict;
    String? selectedCourtType;
    final courtNameController = TextEditingController();
    final courtNumberController = TextEditingController();
    bool isLoading = false;

    // Load states, districts, and court types before showing dialog
    try {
      final apiService = ApiService();
      final token = await apiService.getAccessToken();

      // Fetch districts (which includes states data)
      final districtsResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getdistrict/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (districtsResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(districtsResponse.body);

        // Use Map to ensure distinct states by ID
        final Map<int, Map<String, dynamic>> uniqueStatesMap = {};
        final List<Map<String, dynamic>> districts = [];

        for (var item in data) {
          // Add state if not already present (using ID as key)
          if (item['state'] != null) {
            final stateId = item['state']['id'];
            if (!uniqueStatesMap.containsKey(stateId)) {
              uniqueStatesMap[stateId] = {
                'id': stateId,
                'name': item['state']['state'],
              };
            }
          }

          // Add district with its state reference
          districts.add({
            'id': item['id'],
            'name': item['district'],
            'state_id': item['state']['id'],
          });
        }

        // Sort states alphabetically without case sensitivity
        final sortedStates = uniqueStatesMap.values.toList()
          ..sort((a, b) => a['name']
              .toString()
              .toLowerCase()
              .compareTo(b['name'].toString().toLowerCase()));

        // Sort districts alphabetically without case sensitivity
        districts.sort((a, b) => a['name']
            .toString()
            .toLowerCase()
            .compareTo(b['name'].toString().toLowerCase()));

        _states = sortedStates;
        _districts = districts;
      }

      // Fetch court types
      final courtTypesResponse = await http.get(
        Uri.parse('${AppConfig.baseUrl}getcourttype/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (courtTypesResponse.statusCode == 200) {
        final List<dynamic> courtTypesData =
            json.decode(courtTypesResponse.body);
        // Sort court types alphabetically without case sensitivity
        final sortedCourtTypes = courtTypesData
            .map((type) => {
                  'id': type['id'],
                  'name': type['court_type'],
                })
            .toList()
          ..sort((a, b) => a['name']
              .toString()
              .toLowerCase()
              .compareTo(b['name'].toString().toLowerCase()));

        _courtTypes = sortedCourtTypes;
      }
    } catch (e) {
      print('\n=== Error loading filter data ===');
      print('Error details: $e');
      print('=== End Error Log ===\n');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Get districts for selected state
            List<Map<String, dynamic>> filteredDistricts = [];
            if (selectedState != null && selectedState != 'All') {
              final selectedStateId = _states
                  .firstWhere((state) => state['name'] == selectedState)['id'];
              filteredDistricts = _districts
                  .where((district) => district['state_id'] == selectedStateId)
                  .toList();
            } else {
              filteredDistricts = _districts;
            }

            return AlertDialog(
              title: const Text('Add New Court'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // State Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      items: _states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state['name'],
                          child: Text(state['name']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedState = newValue;
                          // Reset district when state changes
                          selectedDistrict = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // District Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDistrict,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        border: OutlineInputBorder(),
                      ),
                      items: filteredDistricts.map((district) {
                        return DropdownMenuItem<String>(
                          value: district['name'],
                          child: Text(district['name']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedDistrict = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Court Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCourtType,
                      decoration: const InputDecoration(
                        labelText: 'Court Type',
                        border: OutlineInputBorder(),
                      ),
                      items: _courtTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['name'],
                          child: Text(type['name']),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCourtType = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Court Name TextField
                    TextField(
                      controller: courtNameController,
                      decoration: const InputDecoration(
                        labelText: 'Court Name',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 16),

                    // Court Number TextField
                    TextField(
                      controller: courtNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Court Number',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validate all fields
                          if (selectedState == null ||
                              selectedDistrict == null ||
                              selectedCourtType == null ||
                              courtNameController.text.trim().isEmpty ||
                              courtNumberController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All fields are mandatory'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final apiService = ApiService();
                            final token = await apiService.getAccessToken();

                            // Get IDs for the selected values
                            final stateId = _states.firstWhere((state) =>
                                state['name'] == selectedState)['id'];
                            final districtId = _districts.firstWhere(
                                (district) =>
                                    district['name'] == selectedDistrict)['id'];
                            final courtTypeId = _courtTypes.firstWhere((type) =>
                                type['name'] == selectedCourtType)['id'];

                            final response = await http.post(
                              Uri.parse(
                                  '${AppConfig.baseUrl}superadmin/courts/add/'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                              body: json.encode({
                                'district_id': districtId,
                                'state_id': stateId,
                                'court_name': courtNameController.text
                                    .trim()
                                    .toUpperCase(),
                                'court_type': courtTypeId,
                                'court_no': courtNumberController.text
                                    .trim()
                                    .toUpperCase(),
                              }),
                            );

                            print('\n=== Add Court API Response ===');
                            print('Status Code: ${response.statusCode}');
                            print('Response Body: ${response.body}');
                            print('=== End Response ===\n');

                            if (!context.mounted) return;

                            // Parse response
                            final responseData = json.decode(response.body);

                            if (responseData['status'] == 200) {
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Court added successfully'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 3),
                                ),
                              );

                              // Refresh the courts list
                              _fetchData();
                              // Close dialog
                              Navigator.pop(context);
                            } else {
                              // Show error message from response
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(responseData['message'] ??
                                      'Something went wrong'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                              // Keep all form data as is for retry
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Court'),
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
    print('\n=== Building Courts List Screen ===');
    print('Is Loading: $_isLoading');
    print('Courts Count: ${_courts.length}');
    print('Filtered Courts Count: ${_filteredCourts.length}');

    return Scaffold(
      backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Courts List',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(123, 109, 217, 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_filteredCourts.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromRGBO(253, 255, 247, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            onPressed: _showAddCourtDialog,
            tooltip: 'Add New Court',
          ),
        ],
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
                          hintText: 'Search courts...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _filterCourts();
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
                        onChanged: (value) {
                          _searchQuery = value;
                          _filterCourts();
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
                : _filteredCourts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No courts found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_courts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Try refreshing the page',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredCourts.length,
                          itemBuilder: (context, index) {
                            final court = _filteredCourts[index];
                            print(
                                'Building court tile for index $index: ${court['court_name']}');
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // TODO: Navigate to court details screen
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              court['court_no'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                      255, 152, 0, 1)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              court['court_type']
                                                      ?['court_type'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                color: Color.fromRGBO(
                                                    255, 152, 0, 1),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.account_balance_outlined,
                                            size: 20,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Court Name',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  court['court_name'] ?? 'N/A',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 20,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Location',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        court['district']
                                                                ?['district'] ??
                                                            'N/A',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey[200],
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Text(
                                                        court['district']
                                                                    ?['state']
                                                                ?['state'] ??
                                                            'N/A',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color:
                                                              Colors.grey[700],
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
                                        ],
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
