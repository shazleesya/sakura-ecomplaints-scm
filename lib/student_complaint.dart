import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_provider.dart';

class ComplaintForm extends StatefulWidget {
  final String initialRoomNo;
  final String initialPhoneNo;
  final String initialCategory;
  final String initialDescription;
  final String initialPriority;

  const ComplaintForm({
    super.key,
    required this.initialRoomNo,
    required this.initialPhoneNo,
    required this.initialCategory,
    required this.initialDescription,
    required this.initialPriority,
  });

  @override
  ComplaintFormState createState() => ComplaintFormState();
}

class ComplaintFormState extends State<ComplaintForm> {
  final TextEditingController roomNoController = TextEditingController();
  final TextEditingController phoneNoController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedCategory;
  String priority = 'Low';
  bool isFormEdited = false;

  @override
  void initState() {
    super.initState();
    roomNoController.text = widget.initialRoomNo;
    phoneNoController.text = widget.initialPhoneNo;
    selectedCategory = widget.initialCategory;
    descriptionController.text = widget.initialDescription;
    priority = widget.initialPriority;
  }

  void _handleBackNavigation() {
    if (isFormEdited) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Center(
              child: Text(
                'Back to Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            content: const Text(
              'Are you sure you want to go back? Unsaved changes will be lost.',
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center, // Center the buttons
            actions: [
              SizedBox(
                width: 100, // Fixed button width
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9), // Button background
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Sharp edges
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(), // Close dialog
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black), // Button text color
                  ),
                ),
              ),
              const SizedBox(width: 16), // Spacing between buttons
              SizedBox(
                width: 100, // Fixed button width
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFD9D9D9), // Button background
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Sharp edges
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Navigate back
                  },
                  child: const Text(
                    'Proceed',
                    style: TextStyle(color: Colors.black), // Button text color
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitForm() async {
    final tokenProvider = TokenProvider.of(context);
    final token = tokenProvider?.token ?? '';

    final response = await http.post(
      Uri.parse('http://149.28.159.69:3000/complaints'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'phoneNumber': phoneNoController.text,
        'roomNumber': roomNoController.text,
        'category': selectedCategory,
        'description': descriptionController.text,
        'priority': priority,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 201) {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent user from dismissing the dialog
        builder: (context) {
          Future.delayed(const Duration(seconds: 2), () {
            if (!context.mounted) return;
            Navigator.of(context).pop(); // Automatically close the dialog
          });
          return AlertDialog(
            alignment: Alignment.center, // Center the dialog
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            content: Text(
              'Complaint Submitted Successfully!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18, // Adjusted font size for better proportions
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
      setState(() => isFormEdited = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit complaint: ${response.reasonPhrase}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: _handleBackNavigation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "Complaint Form",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Anek Latin',
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis, //Prevent text overflow
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildInputFieldWithHint(
                      label: "Room No",
                      hint: "Eg: C.2.1",
                      controller: roomNoController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInputFieldWithHint(
                      label: "Phone No",
                      hint: "Eg: 012-xxxxxxx",
                      controller: phoneNoController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Complaint Category",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Anek Latin',
                ),
              ),
              DropdownButtonFormField<String>(
                isExpanded: true, // Prevent text overflow
                value: selectedCategory,
                hint: const Text(
                  "Select a category",
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Anek Latin',
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: "Civil",
                    child: const Text(
                      "Civil - E.g.: Building structure, doors, plumbing, sewage, leaks, blockages, and no water supply",
                      style: TextStyle(color: Colors.black, fontFamily: 'Anek Latin'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Electrical",
                    child: const Text(
                      "Electrical - E.g.: Socket, short circuit, light, and fan",
                      style: TextStyle(color: Colors.black, fontFamily: 'Anek Latin'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Mechanical",
                    child: const Text(
                      "Mechanical - E.g.: Air conditioning and fire prevention system",
                      style: TextStyle(color: Colors.black, fontFamily: 'Anek Latin'),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Furniture",
                    child: const Text(
                      "Furniture - E.g.: Chairs, tables, beds, and cabinets",
                      style: TextStyle(color: Colors.black, fontFamily: 'Anek Latin'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                    isFormEdited = true;
                  });
                },
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0x80FAB5D1),
                  border: InputBorder.none, // Removed border
                ),
                dropdownColor: const Color(0xFFDD9FB8), // Dropdown menu background color
              ),
              const SizedBox(height: 16),
              _buildTextAreaWithHint(
                label: "Description",
                hint: "Please describe the issue in detail.",
                controller: descriptionController,
              ),
              const SizedBox(height: 16),
              _buildTextAreaWithHint(
                label: "Note:",
                hint: "Additional notes.",
                controller: descriptionController,
              ),
              const SizedBox(height: 16),
              const Text(
                "Priority",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Anek Latin',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0x80FAB5D1),
                  borderRadius: BorderRadius.circular(0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildRadioButton("Urgent", "Urgent"),
                    _buildRadioButton("Medium", "Medium"),
                    _buildRadioButton("Low", "Low"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 115,
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBD3E76),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 16,
                        fontFamily: 'Anek Latin',
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

  Widget _buildInputFieldWithHint({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Anek Latin',
          ),
        ),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0x80FAB5D1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() => isFormEdited = true),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Anek Latin',
          ),
        ),
      ],
    );
  }

  Widget _buildTextAreaWithHint({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Anek Latin',
          ),
        ),
        TextField(
          controller: controller,
          maxLines: 5,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0x80FAB5D1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(0),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() => isFormEdited = true),
        ),
        const SizedBox(height: 8),
        Text(
          hint,
          style: const TextStyle(
            color: Colors.black,
            fontFamily: 'Anek Latin',
          ),
        ),
      ],
    );
  }

  Widget _buildRadioButton(String title, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: priority,
          activeColor: Colors.pink.shade700,
          onChanged: (val) {
            setState(() {
              priority = val!;
              isFormEdited = true;
            });
          },
        ),
        Text(
          title,
          style: const TextStyle(fontFamily: 'Anek Latin'),
        ),
      ],
    );
  }
}