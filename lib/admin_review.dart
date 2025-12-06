import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_provider.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key});

  @override
  ReviewPageState createState() => ReviewPageState();
}

class ReviewPageState extends State<ReviewPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  List<dynamic> _reviews = [];
  List<dynamic> _filteredReviews = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    final response = await http.get(
      Uri.parse('http://149.28.159.69:3000/feedbacks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> reviews = jsonDecode(response.body);
      List<dynamic> reviewsWithComplaints = [];

      for (var review in reviews) {
        final complaintResponse = await http.get(
          Uri.parse('http://149.28.159.69:3000/complaints/${review['complaintId']}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (complaintResponse.statusCode == 200) {
          var complaint = jsonDecode(complaintResponse.body);
          review['phoneNumber'] = complaint['phoneNumber'];
          review['complaintAuthor'] = complaint['submittedBy'];
          review['name'] = complaint['name'];
          review['roomNumber'] = complaint['roomNumber'];
          review['category'] = complaint['category'];
          review['description'] = complaint['description'];
          review['priority'] = complaint['priority'];
          reviewsWithComplaints.add(review);
        }
      }

      // Sort reviews from latest to oldest based on createdDate
      reviewsWithComplaints.sort((a, b) {
        DateTime dateA = DateTime.parse(a['createdDate']);
        DateTime dateB = DateTime.parse(b['createdDate']);
        return dateB.compareTo(dateA); // Sort in descending order (latest first)
      });

      if (!mounted) return;

      setState(() {
        _reviews = reviewsWithComplaints;
        _filterReviews();
      });
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load reviews")),
      );
    }
  }

  void _filterReviews() {
    String searchQuery = _searchController.text.toLowerCase();
    DateTime? startDate = _startDate;
    DateTime? endDate = _endDate;

    setState(() {
      _filteredReviews = _reviews.where((review) {
        bool matchesSearch = review['roomNumber']?.toLowerCase().contains(searchQuery) ?? false;
        bool matchesStartDate = startDate == null || DateTime.parse(review['createdDate']).isAfter(startDate);
        bool matchesEndDate = endDate == null || DateTime.parse(review['createdDate']).isBefore(endDate);

        return matchesSearch && matchesStartDate && matchesEndDate;
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
        _filterReviews();
      });
    }
  }

  Future<void> _replyToFeedback(String feedbackId) async {
    final TextEditingController replyController = TextEditingController();
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Reply to Feedback'),
          content: TextField(
            controller: replyController,
            decoration: InputDecoration(hintText: 'Enter your reply'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final response = await http.post(
                  Uri.parse('http://149.28.159.69:3000/feedbacks/reply'),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'feedbackId': feedbackId,
                    'reply': replyController.text,
                  }),
                );

                if (!context.mounted) return;

                if (response.statusCode == 200) {
                  setState(() {
                    _reviews.firstWhere((review) => review['id'] == feedbackId)['reply'] = replyController.text;
                    _filterReviews();
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reply sent successfully')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send reply')),
                  );
                }
              },
              child: Text('Send'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.lightBlue.shade50, // Match the background color with AdHomePage
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
                          "Student's Review",
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
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search by room number',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    onChanged: (value) {
                                      _filterReviews();
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
              // "All" text
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'All',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Reviews list
              Expanded(
                child: _filteredReviews.isEmpty
                    ? Center(
                        child: Text(
                          "No data to display.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredReviews.length,
                        itemBuilder: (context, index) {
                          final review = _filteredReviews[index];
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
                                        'Room: ${review['roomNumber'] ?? 'N/A'}',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      Text(
                                        DateFormat('MM/dd/yyyy').format(DateTime.parse(review['createdDate'])),
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Name: ${review['name'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Complaint Category: ${review['category'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Description: ${review['description'] ?? 'N/A'}',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Priority: ${review['priority'] ?? 'N/A'}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text(
                                        'Review:',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(review['comments'] ?? 'No comments available.', style: TextStyle(color: Colors.black)),
                                      ),
                                    ],
                                  ),
                                  if (review['reply'] != null) ...[
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          'Reply from Staff:',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(review['reply'] ?? 'No reply available.', style: TextStyle(color: Colors.black)),
                                        ),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: List.generate(5, (starIndex) {
                                          return Icon(
                                            starIndex < review['rating'] ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 20,
                                          );
                                        }),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color.fromARGB(255, 224, 153, 165),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: review['id'] != null ? () {
                                          _replyToFeedback(review['id']);
                                        } : null,
                                        child: Text(
                                          'Reply',
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
            ],
          ),
        ),
      ),
    );
  }
}
