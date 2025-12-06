import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_provider.dart';

class ContactViewScreen extends StatefulWidget {
  const ContactViewScreen({super.key});

  @override
  ContactViewScreenState createState() => ContactViewScreenState();
}

class ContactViewScreenState extends State<ContactViewScreen> {
  String address = 'Kolej Sakura\nPusat Khidmat Pelajar, BHEPA\nUniversiti Malaysia Sarawak\n94300 Kota Samarahan\nSarawak';
  String phone = '082-593497';
  String fax = '082-582900';
  String emergencyContact = 'khananiq@unimas.my';
  String? _token;
  bool isEditing = false;

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController faxController = TextEditingController();
  final TextEditingController emergencyContactController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token = TokenProvider.of(context)?.token;
    _fetchContactInfo();
  }

  Future<void> _fetchContactInfo() async {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing')),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://149.28.159.69:3000/contacts'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        address = data['address'] ?? '';
        phone = data['phone'] ?? '';
        fax = data['fax'] ?? '';
        emergencyContact = data['emergency'] ?? '';
        addressController.text = address;
        phoneController.text = phone;
        faxController.text = fax;
        emergencyContactController.text = emergencyContact;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load contact information')),
      );
    }
  }

  Future<void> _updateContactInfo() async {
    final response = await http.put(
      Uri.parse('http://149.28.159.69:3000/contacts'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'address': addressController.text,
        'phone': phoneController.text,
        'fax': faxController.text,
        'emergency': emergencyContactController.text,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      setState(() {
        address = addressController.text;
        phone = phoneController.text;
        fax = faxController.text;
        emergencyContact = emergencyContactController.text;
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact Updated Successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update contact: ${response.reasonPhrase}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          "Manage Contact",
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
              SizedBox(height: 16),
              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    color: Colors.lightBlue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 170,
                            child: Image.asset(
                              'assets/kolejsakura.jpg',
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 16),
                          _buildEditableField(
                            label: 'Address',
                            controller: addressController,
                            isEditing: isEditing,
                            maxLines: 3,
                          ),
                          SizedBox(height: 8),
                          _buildEditableField(
                            label: 'Phone',
                            controller: phoneController,
                            isEditing: isEditing,
                          ),
                          SizedBox(height: 8),
                          _buildEditableField(
                            label: 'Fax',
                            controller: faxController,
                            isEditing: isEditing,
                          ),
                          SizedBox(height: 8),
                          _buildEditableField(
                            label: 'Emergency Contact',
                            controller: emergencyContactController,
                            isEditing: isEditing,
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                          Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (isEditing) {
                                _updateContactInfo();
                              } else {
                                setState(() {
                                  isEditing = true;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 224, 153, 165),
                            ),
                            child: Text(
                              isEditing ? 'Save' : 'Edit',
                              style: TextStyle(color: Colors.white), // Set the font color to white
                            ),
                          ),
                        ),
                        ],
                      ),
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

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    int maxLines = 1,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          isEditing
              ? TextField(
                  controller: controller,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                )
              : Text(controller.text),
        ],
      ),
    );
  }
}