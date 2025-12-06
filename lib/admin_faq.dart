import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'token_provider.dart';

class FAQManagementScreen extends StatefulWidget {
  const FAQManagementScreen({super.key});

  @override
  FAQManagementScreenState createState() => FAQManagementScreenState();
}

class FAQManagementScreenState extends State<FAQManagementScreen> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load FAQs')),
      );
    }
  }

  bool _showEditIcons = false;
  bool _showDeleteIcons = false;

  void _toggleEditIcons() {
    setState(() {
      _showEditIcons = !_showEditIcons;
      if (_showEditIcons) _showDeleteIcons = false;
    });
  }

  void _toggleDeleteIcons() {
    setState(() {
      _showDeleteIcons = !_showDeleteIcons;
      if (_showDeleteIcons) _showEditIcons = false;
    });
  }

  void _showEditPopup(Map<String, String> faq, int index) {
    final questionController = TextEditingController(text: faq['Question']);
    final answerController = TextEditingController(text: faq['Answer']);

    if (_token == null || _token!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Frequently Asked Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await http.put(
                  Uri.parse('http://149.28.159.69:3000/faqs/${faq['id']}'),
                  headers: {
                    'Authorization': 'Bearer $_token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'question': questionController.text,
                    'answer': answerController.text,
                  }),
                );

                if (!context.mounted) return;

                if (response.statusCode == 200) {
                  setState(() {
                    _faqs[index] = {
                      'id': faq['id']!,
                      'Question': questionController.text,
                      'Answer': answerController.text,
                    };
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ Updated Successfully')),
                  );
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update FAQ')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPopup() async {
    final questionController = TextEditingController();
    final answerController = TextEditingController();

    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Frequently Asked Question'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(labelText: 'Question'),
              ),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(labelText: 'Answer'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await http.post(
                  Uri.parse('http://149.28.159.69:3000/faqs'),
                  headers: {
                    'Authorization': 'Bearer $_token',
                    'Content-Type': 'application/json',
                  },
                  body: jsonEncode({
                    'question': questionController.text,
                    'answer': answerController.text,
                  }),
                );

                if (!context.mounted) return;

                if (response.statusCode == 201) {
                  final newFaq = jsonDecode(response.body);
                  setState(() {
                    _faqs.add({
                      'id': newFaq['faq']['id']?.toString() ?? '',
                      'Question': questionController.text,
                      'Answer': answerController.text,
                    });
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ Added Successfully')),
                  );
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add FAQ')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showDeletePopup(int index) {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token is missing')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete FAQ'),
          content: const Text('Are you sure you want to delete this FAQ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final response = await http.delete(
                  Uri.parse('http://149.28.159.69:3000/faqs/${_faqs[index]['id']}'),
                  headers: {
                    'Authorization': 'Bearer $_token',
                    'Content-Type': 'application/json',
                  },
                );

                if (!context.mounted) return;

                if (response.statusCode == 200) {
                  setState(() {
                    _faqs.removeAt(index);
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ Deleted Successfully')),
                  );
                } else {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete FAQ')),
                  );
                }
              },
              child: const Text('Delete'),
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
                          "Manage FAQs",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Edit, Add, Delete buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _toggleEditIcons,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: const Color.fromARGB(255, 224, 153, 165),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showAddPopup,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: const Color.fromARGB(255, 224, 153, 165),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'Add',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _toggleDeleteIcons,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: const Color.fromARGB(255, 224, 153, 165),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // FAQs list
              Expanded(
                child: ListView.builder(
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        title: Text(
                          faq['Question']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(faq['Answer']!),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_showEditIcons)
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditPopup(faq, index),
                              ),
                            if (_showDeleteIcons)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeletePopup(index),
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