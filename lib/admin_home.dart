// Admin Home Page
// This screen serves as the main dashboard for administrators.
// It provides access to administrative features such as user management,
// content moderation, and system overview.
// This file contains only UI and navigation logic for the admin homepage.

import 'package:flutter/material.dart';
import 'admin_review.dart';
import 'admin_faq.dart';
import 'admin_complaint.dart';
import 'admin_contact.dart'; // Import the ContactViewScreen page
import 'token_provider.dart';
import 'student_login.dart'; // Import the login page

class AdHomePage extends StatelessWidget {
  final String staffId;

  const AdHomePage({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    return Scaffold(
      backgroundColor: Colors.lightBlue.shade50, // Lighter blue color
      body: Stack(
        children: [
          // SAKURA College Logo with additional elements at the top-left
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
                SizedBox(width: 10),
                Text(
                  "WELCOME, $staffId",
                  style: TextStyle(
                    fontSize: 17,
                    color: const Color.fromARGB(255, 11, 11, 11),
                  ),
                ),
              ],
            ),
          ),
          // Logout icon at the top-right
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginPage(
                      logoutMessage: 'You have been logged out successfully',
                    ),
                  ),
                );
              },
              icon: Icon(Icons.logout, color: Colors.black),
            ),
          ),
          // Main content of the page
          Center(
            child: Column(
              children: [
                SizedBox(height: 110),
                Image.asset(
                  'assets/adhome.png',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover, // Ensures no cropping or stretching
                ),
                SizedBox(height: 10), // Adjusted spacing
                Text(
                  "CATEGORIES",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 0), // Adjusted spacing
                // Wrap the category boxes in an Expanded widget to avoid overflow
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // First row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: CategoryBox(
                              label: "Manage Complaint",
                              imageAsset: "assets/A1.png",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TokenProvider(
                                      token: token,
                                      child: ManageComplaintsPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Flexible(
                            child: CategoryBox(
                              label: "Student's Review",
                              imageAsset: "assets/A2.png",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TokenProvider(
                                      token: token,
                                      child: ReviewPage(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Second row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: CategoryBox(
                              label: "Manage F.A.Q",
                              imageAsset: "assets/A3.png",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TokenProvider(
                                      token: token,
                                      child: FAQManagementScreen(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Flexible(
                            child: CategoryBox(
                              label: "Manage Contact",
                              imageAsset: "assets/A4.png",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TokenProvider(
                                      token: token,
                                      child: ContactViewScreen(),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
        width: double.infinity, // Let the container use the available width
        height: 165,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 184, 215,
              240), // Darker shade of background color for category box
          borderRadius: BorderRadius.circular(90),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
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
