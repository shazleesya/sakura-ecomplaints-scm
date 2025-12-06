import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_provider.dart';
import 'package:flutter/scheduler.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  FAQPageState createState() => FAQPageState();
}

class FAQPageState extends State<FAQPage> {
  List<Map<String, String>> _faqs = [];
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token = TokenProvider.of(context)?.token;
    _fetchFAQs();
  }

  Future<void> _fetchFAQs() async {
    if (_token == null || _token!.isEmpty) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token is missing')),
        );
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://149.28.159.69:3000/faqs'),
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        _faqs = data.map((faq) {
          return {
            'id': faq['id'] as String,
            'Question': faq['question'] as String,
            'Answer': faq['answer'] as String,
          };
        }).toList();
      });
    } else {
      if (!mounted) return;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load FAQs')),
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
          child: Flex(
            direction: Axis.vertical, // Using Flex to control vertical layout
            children: [
              // Header section
              Container(
                padding: EdgeInsets.all(16),
                child: Flex(
                  direction: Axis.vertical, // Stack the logo and back button vertically
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
                    // Row with back button and title
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                        SizedBox(width: 8),
                        Expanded(  // Use Expanded to avoid overflow
                          child: Text(
                            "Frequently Asked Questions",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis, // Ensure text doesn't overflow
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // FAQs list (Wrapped in Expanded to handle overflow)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _faqs.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _faqs.length,
                          itemBuilder: (context, index) {
                            final faq = _faqs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: FAQItem(
                                question: faq['Question']!,
                                answer: faq['Answer']!,
                              ),
                            );
                          },
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

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible( // Flexible allows the text to wrap within the available space
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    softWrap: true, // Allow text wrapping
                  ),
                ),
                Icon(
                  isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Colors.black,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 224, 153, 165),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.answer,
              style: const TextStyle(color: Colors.black),
            ),
          ),
      ],
    );
  }
}
