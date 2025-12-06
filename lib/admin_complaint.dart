import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'token_provider.dart';
import 'generate_report.dart'; // Import the generate report page

class ManageComplaintsPage extends StatefulWidget {
  const ManageComplaintsPage({super.key});

  @override
  ManageComplaintsPageState createState() => ManageComplaintsPageState();
}

class ManageComplaintsPageState extends State<ManageComplaintsPage> {
  final TextEditingController _roomSearchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  final Map<String, String?> _selectedStatuses = {};
  final Map<String, TextEditingController> _commentControllers = {};
  String? _selectedFilterStatus;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchComplaints(); // Moved here from initState
  }

  Future<void> _fetchComplaints() async {
  final tokenProvider = TokenProvider.of(context);
  final token = tokenProvider?.token ?? '';

  try {
    final response = await http.get(
      Uri.parse('http://149.28.159.69:3000/complaints'),
      headers: {
        "Authorization": 'Bearer $token',
        'Content-Type': 'application/json'
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        _complaints = List<Map<String, dynamic>>.from(jsonDecode(response.body));

        // Sort complaints by 'createdDate' in descending order
        _complaints.sort((a, b) {
          DateTime aDate = DateTime.parse(a['createdDate']);
          DateTime bDate = DateTime.parse(b['createdDate']);
          return bDate.compareTo(aDate);  // Sort descending (latest first)
        });

        _filteredComplaints = _complaints;
      });
    } else {
      throw Exception('Failed to load complaints');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to load complaints: $e")),
    );
  }
}


  void _updateComplaintStatus(String complaintId, String newStatus, String comment) async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    try {
      final response = await http.put(
        Uri.parse('http://149.28.159.69:3000/complaints/$complaintId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'status': newStatus, 'comment': comment}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          final index = _complaints.indexWhere((complaint) => complaint['id'] == complaintId);
          if (index != -1) {
            _complaints[index]['status'] = newStatus;
            _complaints[index]['comment'] = comment;
            _selectedStatuses.remove(complaintId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated successfully')),
        );
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update status: $e")),
      );
    }
  }

  void _filterComplaints() {
    String roomSearchQuery = _roomSearchController.text.toLowerCase();
    DateTime? startDate = _startDate;
    DateTime? endDate = _endDate;
    String? filterStatus = _selectedFilterStatus;

    setState(() {
      _filteredComplaints = _complaints.where((complaint) {
        bool matchesRoomSearch = complaint['roomNumber']?.toLowerCase().contains(roomSearchQuery) ?? false;
        bool matchesStartDate = startDate == null || DateTime.parse(complaint['createdDate']).isAfter(startDate);
        bool matchesEndDate = endDate == null || DateTime.parse(complaint['createdDate']).isBefore(endDate);
        bool matchesStatus = filterStatus == null || filterStatus == 'All' || complaint['status'] == filterStatus;

        return matchesRoomSearch && matchesStartDate && matchesEndDate && matchesStatus;
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _filterComplaints();
      });
    }
  }

  void _showConfirmationDialog(String complaintId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Update'),
          content: Text('Are you sure you want to update the status and notify the student?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateComplaintStatus(complaintId, _selectedStatuses[complaintId]!, _commentControllers[complaintId]!.text);
                Navigator.pop(context);
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Align(
                      alignment: Alignment.topLeft,
                      child: Image.asset(
                        'assets/logo.png',
                        height: 60,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Back button and title row
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Manage Complaints",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Search and date filter row
                    Row(
                      children: [
                        // Search icon and field
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.search, color: Colors.grey),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _roomSearchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onChanged: (value) {
                                      _filterComplaints();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        // Date range text
                        Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(width: 8),
                        // Date pickers
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _startDate == null
                                  ? 'From'
                                  : DateFormat('MM/dd/yyyy').format(_startDate!),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text('to'),
                        ),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              _endDate == null
                                  ? 'To'
                                  : DateFormat('MM/dd/yyyy').format(_endDate!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status filter dropdown
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilterStatus ?? 'All',
                      items: <String>['All', 'Pending', 'KIV', 'Ongoing', 'Completed']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFilterStatus = value;
                          _filterComplaints();
                        });
                      },
                    ),
                  ],
                ),
              ),
              // Complaints list
              Expanded(
                child: _filteredComplaints.isEmpty
                    ? Center(
                        child: Text(
                          "No data to display.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredComplaints.length,
                        itemBuilder: (context, index) {
                          final complaint = _filteredComplaints[index];
                          final complaintId = complaint['id'];
                          _commentControllers[complaintId] ??= TextEditingController(text: complaint['comment']);
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.black, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Room: ${complaint['roomNumber'] ?? 'N/A'}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      Text(
                                        DateFormat('MM/dd/yyyy').format(DateTime.parse(complaint['createdDate'])),
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Name: ${complaint['name'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Matric No: ${complaint['matricNo'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Phone Number: ${complaint['phoneNumber'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Complaint Category: ${complaint['category'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Description: ${complaint['description'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Priority: ${complaint['priority'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (_selectedStatuses[complaintId] != null) ...[
                                    TextField(
                                      controller: _commentControllers[complaintId],
                                      decoration: InputDecoration(
                                        labelText: 'Comment',
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                  ] else ...[
                                    Text(
                                      'Comment: ${complaint['comment'] ?? 'No comment available.'}',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      Text(
                                        'Status:',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      SizedBox(width: 8),
                                      DropdownButton<String>(
                                        value: _selectedStatuses[complaintId] ?? complaint['status'],
                                        items: <String>['Pending', 'KIV', 'Ongoing', 'Completed']
                                            .map((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedStatuses[complaintId] = value;
                                          });
                                        },
                                      ),
                                      Spacer(),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 224, 153, 165),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () {
                                          if (_selectedStatuses[complaintId] != null && _commentControllers[complaintId]!.text.isNotEmpty) {
                                            _showConfirmationDialog(complaintId);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Please select a status and enter a comment')),
                                            );
                                          }
                                        },
                                        child: Text(
                                          'Notify Student',
                                          style: TextStyle(color: Colors.white),
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
              SizedBox(height: 20),
              Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(  // Center the button
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink[100],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenerateReportPage(token: token), // Pass the token
                      ),
                    );
                  },
                  child: Text('Generate Report'),
                ),
              ),
            ),

            ],
          ),
        ),
      ),
    );
  }
}