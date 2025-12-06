import 'package:flutter/material.dart';
import 'student_login.dart';
import 'admin_login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
      routes: {
        '/student-login': (context) => const LoginPage(),
        '/admin-login': (context) => const AdLoginPage(),
      },
    );
  }
}
