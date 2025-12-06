import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'token_provider.dart';
import 'student_complaint.dart';
import 'review_form.dart'; // Import the review form

class ComplaintStatusScreen extends StatelessWidget {
  final String matricNo;

  const ComplaintStatusScreen({super.key, required this.matricNo});

  void _handleBackNavigation(BuildContext context) {
    Navigator.pop(context); // Navigate back
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Number of tabs
      child: Scaffold(
        backgroundColor: Colors.white, // Set background color to white
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(165),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => _handleBackNavigation(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Complaint Status",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Anek Latin',
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const TabBar(
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.black,
                  tabs: [
                    Tab(text: "Pending"),
                    Tab(text: "Ongoing"),
                    Tab(text: "Completed"),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            ComplaintList(
              matricNo: matricNo,
              status: 'Pending',
            ),
            ComplaintList(
              matricNo: matricNo,
              status: 'Ongoing',
            ),
            ComplaintList(
              matricNo: matricNo,
              status: 'Completed',
              showButtons: true, // Add buttons for solved complaints
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintList extends StatefulWidget {
  final String matricNo;
  final String status;
  final bool showButtons;

  const ComplaintList({
    super.key,
    required this.matricNo,
    required this.status,
    this.showButtons = false, // Default to false
  });

  @override
  ComplaintListState createState() => ComplaintListState();
}

class ComplaintListState extends State<ComplaintList> {
  List<Complaint> complaints = [];
  TokenProvider? _tokenProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tokenProvider = TokenProvider.of(context);
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
  final token = _tokenProvider?.token ?? '';

  try {
    final response = await http.get(
      Uri.parse(
          'http://149.28.159.69:3000/complaints/matric/${widget.matricNo}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        complaints = data
            .map((json) => Complaint.fromJson(json))
            .where((complaint) {
          if (widget.status == 'Pending') {
            return complaint.status == 'Pending' || complaint.status == 'KIV';
          } else {
            return complaint.status == widget.status;
          }
        }).toList()
          ..sort((a, b) => DateTime.parse(b.date).compareTo(DateTime.parse(a.date))); // Sort complaints by date, latest first
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


  @override
  Widget build(BuildContext context) {
    final token = _tokenProvider?.token ?? '';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        final complaint = complaints[index];
        return Column(
          children: [
            ComplaintCard(
              complaint: complaint,
              showButtons: widget.showButtons, // Pass the parameter
              token: token, // Pass the token
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class ComplaintCard extends StatelessWidget {
  final Complaint complaint;
  final bool showButtons; // New parameter
  final String token; // New parameter

  const ComplaintCard({
    super.key,
    required this.complaint,
    this.showButtons = false, // Default to false
    required this.token, // Required token parameter
  });

  Future<void> _fetchComplaintData(
      BuildContext context, String complaintId) async {
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token is missing")),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://149.28.159.69:3000/complaints/$complaintId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComplaintForm(
              initialRoomNo: data['roomNumber'], // Pass the room number
              initialPhoneNo: data['phoneNumber'], // Pass the phone number
              initialCategory: data['category'], // Pass the category
              initialDescription: data['description'], // Pass the description
              initialPriority: data['priority'], // Pass the priority
            ),
          ),
        );
      } else {
        throw Exception('Failed to fetch complaint data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch complaint data: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('yyyy-MM-dd').format(DateTime.parse(complaint.date));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                complaint.category,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Anek Latin',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontFamily: 'Anek Latin',
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            complaint.description,
            style: const TextStyle(
              fontFamily: 'Anek Latin',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Priority: ${complaint.priority}',
            style: const TextStyle(
              fontFamily: 'Anek Latin',
              fontSize: 14,
              color: Colors.black,
            ),
          ),
          if (showButtons) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewForm(
                          complaintId: complaint.id,
                          category: complaint.category,
                          description: complaint.description,
                          priority: complaint.priority,
                          token: token,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD3E76),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Review',
                    style: TextStyle(
                      fontFamily: 'Anek Latin',
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10), // Customize dialog border radius
                          ),
                          title: const Center(
                            child: Text(
                              'Re-Complaint',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          content: const Text(
                            'Is the issue still happening? If so, you may proceed to re-complaint.',
                            textAlign: TextAlign.center,
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            SizedBox(
                              width: 100,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFD9D9D9),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0)),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 100,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFD9D9D9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(0),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _fetchComplaintData(context, complaint.id);
                                },
                                child: const Text(
                                  'Proceed',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD3E76),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Recomplaint',
                    style: TextStyle(
                      fontFamily: 'Anek Latin',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class Complaint {
  final String id;
  final String category;
  final String description;
  final String date;
  final String priority;
  final String status;
  final String roomNo;
  final String phoneNo;

  const Complaint({
    required this.id,
    required this.category,
    required this.description,
    required this.date,
    required this.priority,
    required this.status,
    required this.roomNo,
    required this.phoneNo,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      category: json['category'],
      description: json['description'],
      date: json['createdDate'],
      priority: json['priority'],
      status: json['status'],
      roomNo: json['roomNumber'],
      phoneNo: json['phoneNumber'],
    );
  }
}
