import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'token_provider.dart';

class NotificationsPage extends StatefulWidget {
  final String matricNo;

  const NotificationsPage({super.key, required this.matricNo});

  @override
  NotificationsPageState createState() => NotificationsPageState();
}

class NotificationsPageState extends State<NotificationsPage> {
  List<Map<String, dynamic>> _notifications = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://149.28.159.69:3000/notifications/${widget.matricNo}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<Map<String, dynamic>> notifications =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
        notifications.sort((a, b) => DateTime.parse(b['createdDate'])
            .compareTo(DateTime.parse(a['createdDate'])));
        setState(() {
          _notifications = notifications;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notifications: $e")),
      );
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    try {
      final response = await http.put(
        Uri.parse(
            'http://149.28.159.69:3000/notifications/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      } else {
        setState(() {
          _notifications = _notifications.map((notification) {
            if (notification['id'] == notificationId) {
              notification['isRead'] = true;
            }
            return notification;
          }).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark notification as read: $e")),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    try {
      final response = await http.delete(
        Uri.parse('http://149.28.159.69:3000/notifications/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      } else {
        setState(() {
          _notifications.removeWhere(
              (notification) => notification['id'] == notificationId);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete notification: $e")),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchComplaintById(String complaintId) async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://149.28.159.69:3000/complaints/$complaintId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load complaint');
      }
    } catch (e) {
      throw Exception('Failed to load complaint: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchFeedbackById(String feedbackId) async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://149.28.159.69:3000/feedbacks/$feedbackId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load feedback');
      }
    } catch (e) {
      throw Exception('Failed to load feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
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
                          "Notifications",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // TabBar and TabBarView
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Colors.black,
                        tabs: [
                          Tab(text: 'Complaint'),
                          Tab(text: 'Review'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            ComplaintTab(
                              notifications: _notifications,
                              fetchComplaintById: _fetchComplaintById,
                              markAsRead: _markAsRead,
                              deleteNotification: _deleteNotification,
                            ),
                            ReviewTab(
                              notifications: _notifications,
                              fetchFeedbackById: _fetchFeedbackById,
                              fetchComplaintById: _fetchComplaintById,
                              markAsRead: _markAsRead,
                              deleteNotification: _deleteNotification,
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
      ),
    );
  }
}

class ComplaintTab extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Future<Map<String, dynamic>> Function(String) fetchComplaintById;
  final Future<void> Function(String) markAsRead;
  final Future<void> Function(String) deleteNotification;

  const ComplaintTab({
    super.key,
    required this.notifications,
    required this.fetchComplaintById,
    required this.markAsRead,
    required this.deleteNotification,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: notifications
          .where((notification) =>
              notification['type'].toString().startsWith('Complaint'))
          .map((notification) {
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchComplaintById(notification['data']['complaintId']),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text('Failed to load complaint details'));
            } else if (!snapshot.hasData) {
              return const Center(
                  child: Text('No complaint details available'));
            } else {
              final complaint = snapshot.data!;
              Color backgroundColor;
              String title;

              final status = complaint['status'];
              if (status == 'Ongoing') {
                backgroundColor = const Color.fromARGB(255, 252, 102, 102);
                title = 'Ongoing Maintenance Work!';
              } else if (status == 'Completed') {
                backgroundColor = Colors.green[100]!;
                title = 'Maintenance Work Completed!';
              } else if (status == 'KIV') {
                backgroundColor = const Color.fromARGB(255, 255, 244, 149);
                title = 'Keep in View (KIV)';
              } else {
                backgroundColor = Colors.pink[50]!;
                title = 'Complaint Received!';
              }

              return ComplaintCard(
                title: title,
                backgroundColor: backgroundColor,
                details: {
                  'Name': complaint['name'] ?? 'N/A',
                  'Matric No': complaint['matricNo'] ?? 'N/A',
                  'Room No': complaint['roomNumber'] ?? 'N/A',
                  'Phone No': complaint['phoneNumber'] ?? 'N/A',
                  'Category': complaint['category'] ?? 'N/A',
                  'Description': complaint['description'] ?? 'N/A',
                  'Priority': complaint['priority'] ?? 'N/A',
                  'Date': DateFormat('dd/MM/yyyy')
                      .format(DateTime.parse(complaint['createdDate'])),
                  'Comments': complaint['comment'] ?? 'No comments available.',
                },
                markAsRead: notification['isRead'] != true
                    ? () => markAsRead(notification['id'])
                    : null,
                deleteNotification: () => _showDeleteConfirmation(
                    context, notification['id'], deleteNotification),
              );
            }
          },
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String notificationId,
      Future<void> Function(String) deleteNotification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content:
              const Text('Are you sure you want to delete this notification?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deleteNotification(notificationId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ReviewTab extends StatelessWidget {
  final List<Map<String, dynamic>> notifications;
  final Future<Map<String, dynamic>> Function(String) fetchFeedbackById;
  final Future<Map<String, dynamic>> Function(String) fetchComplaintById;
  final Future<void> Function(String) markAsRead;
  final Future<void> Function(String) deleteNotification;

  const ReviewTab({
    super.key,
    required this.notifications,
    required this.fetchFeedbackById,
    required this.fetchComplaintById,
    required this.markAsRead,
    required this.deleteNotification,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: notifications
          .where((notification) =>
              notification['type'].toString().startsWith('Feedback'))
          .map((notification) {
        return FutureBuilder<Map<String, dynamic>>(
          future: fetchFeedbackById(notification['data']['feedbackId']),
          builder: (context, feedbackSnapshot) {
            if (feedbackSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (feedbackSnapshot.hasError) {
              return const Center(
                  child: Text('Failed to load feedback details'));
            } else if (!feedbackSnapshot.hasData) {
              return const Center(child: Text('No feedback details available'));
            } else {
              final feedback = feedbackSnapshot.data!;
              return FutureBuilder<Map<String, dynamic>>(
                future: fetchComplaintById(feedback['complaintId']),
                builder: (context, complaintSnapshot) {
                  if (complaintSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (complaintSnapshot.hasError) {
                    return const Center(
                        child: Text('Failed to load complaint details'));
                  } else if (!complaintSnapshot.hasData) {
                    return const Center(
                        child: Text('No complaint details available'));
                  } else {
                    final complaint = complaintSnapshot.data!;
                    Color backgroundColor;
                    String title;

                    switch (notification['type']) {
                      case 'FeedbackSubmit':
                        backgroundColor = Colors.pink[100]!;
                        title = 'You have submitted your review!';
                        break;
                      case 'FeedbackReply':
                        backgroundColor = Colors.green[100]!;
                        title = 'Admin replied to your review!';
                        break;
                      default:
                        backgroundColor = Colors.grey[100]!;
                        title = 'Notification';
                    }

                    return ReviewCard(
                      title: title,
                      backgroundColor: backgroundColor,
                      details: {
                        'Name': complaint['name'] ?? 'N/A',
                        'Matric No': complaint['matricNo'] ?? 'N/A',
                        'Room No': complaint['roomNumber'] ?? 'N/A',
                        'Phone No': complaint['phoneNumber'] ?? 'N/A',
                        'Category': complaint['category'] ?? 'N/A',
                        'Description': complaint['description'] ?? 'N/A',
                        'Priority': complaint['priority'] ?? 'N/A',
                        'Date': DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(feedback['createdDate'])),
                        'Review':
                            feedback['comments'] ?? 'No comments available.',
                      },
                      rating: feedback['rating'] ?? 0,
                      reply: notification['type'] == 'FeedbackReply'
                          ? feedback['reply'] ?? ''
                          : '',
                      markAsRead: notification['isRead'] != true
                          ? () => markAsRead(notification['id'])
                          : null,
                      deleteNotification: () => _showDeleteConfirmation(
                          context, notification['id'], deleteNotification),
                    );
                  }
                },
              );
            }
          },
        );
      }).toList(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String notificationId,
      Future<void> Function(String) deleteNotification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Notification'),
          content:
              const Text('Are you sure you want to delete this notification?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                deleteNotification(notificationId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class ComplaintCard extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Map<String, String> details;
  final String additionalInfo;
  final VoidCallback? markAsRead;
  final VoidCallback deleteNotification;

  const ComplaintCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.details,
    this.additionalInfo = '',
    this.markAsRead,
    required this.deleteNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (markAsRead != null)
                    IconButton(
                      icon: const Icon(Icons.mark_email_read),
                      onPressed: markAsRead,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: deleteNotification,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ...details.entries
              .map((entry) => Text('${entry.key}: ${entry.value}')),
          if (additionalInfo.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(additionalInfo),
          ],
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Map<String, String> details;
  final int rating;
  final String reply;
  final VoidCallback? markAsRead;
  final VoidCallback deleteNotification;

  const ReviewCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    required this.details,
    required this.rating,
    this.reply = '',
    this.markAsRead,
    required this.deleteNotification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  if (markAsRead != null)
                    IconButton(
                      icon: const Icon(Icons.mark_email_read),
                      onPressed: markAsRead,
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: deleteNotification,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ...details.entries
              .map((entry) => Text('${entry.key}: ${entry.value}')),
          const SizedBox(height: 8.0),
          Row(
            children: List.generate(
                5,
                (index) => Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.yellow,
                    )),
          ),
          if (reply.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text('Reply: $reply'),
          ],
        ],
      ),
    );
  }
}
