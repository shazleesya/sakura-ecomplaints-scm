import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_home.dart';
import 'token_provider.dart';
import 'student_login.dart';

class AdLoginPage extends StatefulWidget {
  const AdLoginPage({super.key});

  @override
  AdLoginPageState createState() => AdLoginPageState();
}

class AdLoginPageState extends State<AdLoginPage> {
  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isObscured = true; // NEW: Added to track password visibility

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse(
            'http://149.28.159.69:3000/users/admins/login'), // Updated URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'userId': _staffIdController.text,
          'password': _passwordController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String token = responseData['token'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TokenProvider(
              token: token,
              child: AdHomePage(staffId: _staffIdController.text),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid staff ID or password")),
        );
      }
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
        child: Stack(
          children: [
            // UNIMAS Logo at the top-left
            Positioned(
              top: 20,
              left: 20,
              child: GestureDetector(
                onDoubleTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: Image.asset(
                  'assets/UNIMAS.png',
                  height: 70,
                  width: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Flex widget for layout with Column-like behavior
            Flex(
              direction: Axis
                  .vertical, // Use Flex with vertical direction (like Column)
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 50.0, bottom: 30.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 220,
                        width: 220,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _staffIdController,
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: "Staff ID",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your Staff ID";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText:
                                  _isObscured, // MODIFIED: Uses state variable
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                labelText: "Password",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.never,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                                // NEW: Added suffix icon for toggle functionality
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscured
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscured = !_isObscured;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12.0, horizontal: 50.0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                "HELLO LOGIN",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
