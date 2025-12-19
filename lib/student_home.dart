import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'student_faq.dart';
import 'student_contact.dart';
import 'token_provider.dart';
import 'student_login.dart';
import 'student_complaint.dart'; // Import the ComplaintForm page
import 'student_status.dart'; // Import the ComplaintStatusScreen page
import 'student_notification.dart'; // Import the NotificationsPage

class HomePage extends StatefulWidget {
  final String matricNo;

  const HomePage({super.key, required this.matricNo});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _hasUnreadNotifications = false;

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
        final hasUnread =
            notifications.any((notification) => notification['isRead'] != true);
        setState(() {
          _hasUnreadNotifications = hasUnread;
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

  @override
  Widget build(BuildContext context) {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    return Scaffold(
      backgroundColor: Colors.white, // Set background color to white
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  height: 60,
                  width: 60,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  "WELCOME BACK, ${widget.matricNo}",
                  style: const TextStyle(
                    fontSize: 17,
                    color: Color.fromARGB(255, 11, 11, 11),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TokenProvider(
                          token: token,
                          child: NotificationsPage(matricNo: widget.matricNo),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    _hasUnreadNotifications
                        ? Icons.notifications_active
                        : Icons.notifications,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(
                          logoutMessage:
                              'You have been logged out successfully',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.black),
                ),
              ],
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 100),
                Image.asset(
                  'assets/shome.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 20),
                const Text(
                  "CATEGORIES",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CategoryBox(
                          label: "Submit Complaint",
                          imageAsset: "assets/C1.png",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenProvider(
                                  token: token,
                                  child: ComplaintForm(
                                    initialRoomNo: '',
                                    initialPhoneNo: '',
                                    initialCategory: 'Civil',
                                    initialDescription: '',
                                    initialPriority: 'Low',
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        CategoryBox(
                          label: "Complaint Status",
                          imageAsset: "assets/C2.png",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenProvider(
                                  token: token,
                                  child: ComplaintStatusScreen(
                                      matricNo: widget.matricNo),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CategoryBox(
                          label: "F.A.Q",
                          imageAsset: "assets/C3.png",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenProvider(
                                  token: token,
                                  child: const FAQPage(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        CategoryBox(
                          label: "Contact",
                          imageAsset: "assets/C4.png",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TokenProvider(
                                  token: token,
                                  child: const ContactPage(),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBox extends StatelessWidget {
  final String label;
  final String imageAsset;
  final VoidCallback onPressed;

  const CategoryBox({
    super.key,
    required this.label,
    required this.imageAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.pink[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
