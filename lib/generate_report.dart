import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GenerateReportPage extends StatefulWidget {
  final String token;

  const GenerateReportPage({super.key, required this.token});

  @override
  GenerateReportPageState createState() => GenerateReportPageState();
}

class GenerateReportPageState extends State<GenerateReportPage> {
  List<Map<String, dynamic>> _complaints = [];
  List<Map<String, dynamic>> _filteredComplaints = [];
  DateTime? _selectedMonth;
  int? _selectedYear;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = DateTime(now.year, now.month);
    _filterComplaintsByMonth(_selectedMonth);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final response = await http.get(
        Uri.parse('http://149.28.159.69:3000/complaints'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _complaints =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
          _filteredComplaints = _complaints;
        });
      } else {
        throw Exception('Failed to load complaints');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load complaints: $e")),
      );
    }
  }

  void _filterComplaintsByMonth(DateTime? selectedMonth) {
    setState(() {
      _selectedMonth = selectedMonth;
      if (selectedMonth == null) {
        _filteredComplaints = _complaints;
      } else {
        _filteredComplaints = _complaints.where((complaint) {
          DateTime complaintDate = DateTime.parse(complaint['createdDate']);
          return complaintDate.year == selectedMonth.year &&
              complaintDate.month == selectedMonth.month;
        }).toList();
      }
    });
  }

  String _formatStatus(String status, String comment) {
    String statusWithNote =
        comment.isNotEmpty ? '$status\nNote: $comment' : status;
    List<String> words = statusWithNote.split(' ');
    StringBuffer formattedStatus = StringBuffer();
    int wordCount = 0;

    for (String word in words) {
      formattedStatus.write(word);
      formattedStatus.write(' ');
      wordCount++;
      if (wordCount >= 5) {
        formattedStatus.write('\n');
        wordCount = 0;
      }
    }

    return formattedStatus.toString().trim();
  }

  String _formatName(String name) {
    List<String> words = name.split(' ');
    StringBuffer formattedName = StringBuffer();
    int wordCount = 0;

    for (String word in words) {
      formattedName.write(word);
      formattedName.write(' ');
      wordCount++;
      if (wordCount >= 3) {
        formattedName.write('\n');
        wordCount = 0;
      }
    }

    return formattedName.toString().trim();
  }

  String _formatDateTime(String dateTime) {
    DateTime parsedDateTime = DateTime.parse(dateTime).toLocal();
    String formattedTime = DateFormat('HH:mm', 'en_US').format(parsedDateTime);
    String formattedDate =
        DateFormat('dd/MM/yyyy', 'en_US').format(parsedDateTime);
    return '$formattedTime\n$formattedDate';
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    const int rowsPerPage = 12; // Adjust this value as needed
    int totalRows = _filteredComplaints.length;
    int totalPages = (totalRows / rowsPerPage).ceil();

    for (int page = 0; page < totalPages; page++) {
      int startRow = page * rowsPerPage;
      int endRow = startRow + rowsPerPage;
      if (endRow > totalRows) endRow = totalRows;

      List<List> data =
          _filteredComplaints.sublist(startRow, endRow).map((complaint) {
        String status = complaint['status'] ?? 'N/A';
        String comment = complaint['comment'] ?? '';
        String formattedStatus = _formatStatus(status, comment);
        String formattedDateTime = _formatDateTime(complaint['createdDate']);
        String formattedName = _formatName(complaint['name'] ?? 'N/A');
        return [
          formattedDateTime,
          formattedName,
          complaint['matricNo']?.isNotEmpty == true
              ? complaint['matricNo']
              : 'N/A',
          complaint['roomNumber']?.isNotEmpty == true
              ? complaint['roomNumber']
              : 'N/A',
          complaint['description']?.isNotEmpty == true
              ? complaint['description']
              : 'N/A',
          formattedStatus,
        ];
      }).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Text('Complaints Report',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.TableHelper.fromTextArray(
                  headers: [
                    'Date',
                    'Name',
                    'Matric No',
                    'Room No',
                    'Complaint',
                    'Status'
                  ],
                  data: data,
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: pw.TextStyle(fontSize: 10),
                  headerStyle: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey300),
                  rowDecoration: pw.BoxDecoration(
                    border: pw.Border(
                      bottom:
                          pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
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
          child: SingleChildScrollView(
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
                            "Generate Report",
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
                // Main content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            flex: 2,
                            child: const Text(
                              'Filter by Month:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 3,
                            child: DropdownButton<int>(
                              isExpanded: true, // Ensures the dropdown adapts to the width
                              value: _selectedYear,
                              hint: const Text('Select Year'),
                              items: List.generate(10, (index) {
                                int year = DateTime.now().year - index;
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString()),
                                );
                              }),
                              onChanged: (int? newValue) {
                                setState(() {
                                  _selectedYear = newValue;
                                  if (_selectedMonth != null && _selectedYear != null) {
                                    _filterComplaintsByMonth(DateTime(_selectedYear!, _selectedMonth!.month));
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 3,
                            child: DropdownButton<int>(
                              isExpanded: true, // Ensures the dropdown adapts to the width
                              value: _selectedMonth?.month,
                              hint: const Text('Select Month'),
                              items: List.generate(12, (index) {
                                int month = index + 1;
                                return DropdownMenuItem<int>(
                                  value: month,
                                  child: Text(DateFormat('MMMM').format(DateTime(0, month))),
                                );
                              }),
                              onChanged: (int? newValue) {
                                setState(() {
                                  if (newValue != null) {
                                    _selectedMonth = DateTime(_selectedYear ?? DateTime.now().year, newValue);
                                    if (_selectedYear != null) {
                                      _filterComplaintsByMonth(DateTime(_selectedYear!, newValue));
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      _filteredComplaints.isEmpty
                          ? const Center(
                              child: Text(
                                'No data to display.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Date')),
                                  DataColumn(label: Text('Name')),
                                  DataColumn(label: Text('Matric No')),
                                  DataColumn(label: Text('Room No')),
                                  DataColumn(label: Text('Complaint')),
                                  DataColumn(label: Text('Status')),
                                ],
                                rows: _filteredComplaints.map((complaint) {
                                  String status = complaint['status'] ?? 'N/A';
                                  String formattedDateTime =
                                      _formatDateTime(complaint['createdDate']);
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(formattedDateTime)),
                                      DataCell(Text(
                                          complaint['name']?.isNotEmpty == true
                                              ? complaint['name']
                                              : 'N/A')),
                                      DataCell(Text(
                                          complaint['matricNo']?.isNotEmpty ==
                                                  true
                                              ? complaint['matricNo']
                                              : 'N/A')),
                                      DataCell(Text(
                                          complaint['roomNumber']?.isNotEmpty ==
                                                  true
                                              ? complaint['roomNumber']
                                              : 'N/A')),
                                      DataCell(Text(complaint['description']
                                                  ?.isNotEmpty ==
                                              true
                                          ? complaint['description']
                                          : 'N/A')),
                                      DataCell(Text(status)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          onPressed: _generatePdf,
                          child: const Text('Print'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
