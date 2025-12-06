import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'student_home.dart';
import 'token_provider.dart';
import 'admin_login.dart';

class LoginPage extends StatefulWidget {
  final String? logoutMessage;

  const LoginPage({super.key, this.logoutMessage});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _matricNoController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.logoutMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.logoutMessage!)),
        );
      });
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final response = await http.post(
        Uri.parse('http://149.28.159.69:3000/users/students/login'), // Updated URL
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'userId': _matricNoController.text,
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
              child: HomePage(matricNo: _matricNoController.text),
            ),
          ),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid matric number or password")),
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
          color: Color(0xFFFFEEF4), // Updated background color
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
                    MaterialPageRoute(builder: (context) => const AdLoginPage()),
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
              direction: Axis.vertical, // Use Flex with vertical direction (like Column)
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo
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
                // Form Fields
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _matricNoController,
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.center, // Center the text
                              decoration: InputDecoration(
                                labelText: "Matric Number",
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your matric number";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              textAlign: TextAlign.center, // Center the text
                              decoration: InputDecoration(
                                labelText: "Password",
                                floatingLabelBehavior: FloatingLabelBehavior.never,
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide.none,
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
                                "LOGIN",
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
