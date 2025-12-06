import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_provider.dart';
import 'package:flutter/scheduler.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  ContactPageState createState() => ContactPageState();
}

class ContactPageState extends State<ContactPage> {
  String address = '';
  String phone = '';
  String fax = '';
  String emergency = '';
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token = TokenProvider.of(context)?.token;
    _fetchContactInfo();
  }

  Future<void> _fetchContactInfo() async {
    if (_token == null || _token!.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token is missing')),
        );
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://149.28.159.69:3000/contacts'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        address = data['address'] ?? '';
        phone = data['phone'] ?? '';
        fax = data['fax'] ?? '';
        emergency = data['emergency'] ?? '';
      });
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load contact information')),
        );
      });
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
                          "Contact Information",
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
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/kolejsakura.jpg',
                            width: 320, // Same width as the boxes below
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ContactCard(
                          title: 'Address',
                          content: address,
                        ),
                        const SizedBox(height: 10),
                        ContactCard(
                          title: 'Phone',
                          content: phone,
                        ),
                        const SizedBox(height: 10),
                        ContactCard(
                          title: 'Fax',
                          content: fax,
                        ),
                        const SizedBox(height: 10),
                        ContactCard(
                          title: 'Emergency Contact',
                          content: emergency,
                        ),
                      ],
                    ),
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

class ContactCard extends StatelessWidget {
  final String title;
  final String content;

  const ContactCard({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320, // Fixed width matching the image box
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title :',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
