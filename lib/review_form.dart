import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReviewForm extends StatefulWidget {
  final String complaintId;
  final String category;
  final String description;
  final String priority;
  final String token;

  const ReviewForm({
    super.key, // Use super parameter
    required this.complaintId,
    required this.category,
    required this.description,
    required this.priority,
    required this.token,
  });

  @override
  State<ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<ReviewForm> {
  final TextEditingController _feedbackController = TextEditingController();
  double _rating = 0;
  bool isFormEdited = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_rating < 0 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating must be between 0 and 5')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://149.28.159.69:3000/feedbacks'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'complaintId': widget.complaintId,
          'rating': _rating,
          'comments': _feedbackController.text,
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
              content: const Text(
                'Review Submitted Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18, // Adjusted font size for better proportions
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
        setState(() => isFormEdited = false);
      } else {
        throw Exception('Failed to submit review');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit review: $e')),
      );
    }
  }

  void _handleBackNavigation() {
    Navigator.pop(context); // Navigate back without submitting
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
                    const Text(
                      "Review Form",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Anek Latin',
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Complaint Category',
              style: TextStyle(
                fontFamily: 'Anek Latin',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0x80FAB5D1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.category,
                style: const TextStyle(fontFamily: 'Anek Latin'),
              ),
            ),
            const Text(
              'Description',
              style: TextStyle(
                fontFamily: 'Anek Latin',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0x80FAB5D1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.description,
                style: const TextStyle(fontFamily: 'Anek Latin'),
              ),
            ),
            Row(
              children: [
                const Text(
                  'Priority : ',
                  style: TextStyle(
                    fontFamily: 'Anek Latin',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.priority,
                  style: const TextStyle(
                    fontFamily: 'Anek Latin',
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Review : ',
                  style: TextStyle(
                    fontFamily: 'Anek Latin',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFFF00),
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1;
                          isFormEdited = true;
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Improvement/Feedback',
              style: TextStyle(
                fontFamily: 'Anek Latin',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: const Color(0x80FAB5D1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: TextField(
                controller: _feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(12),
                ),
                style: const TextStyle(fontFamily: 'Anek Latin'),
                onChanged: (_) => setState(() => isFormEdited = true),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_rating > 0 && _rating <= 5) {
                    _submitForm();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a rating between 0 and 5'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD3E76),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontFamily: 'Anek Latin',
                    fontSize: 16,
                    color: Colors.white, // Submit button text color set to white
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}