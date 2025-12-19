/*
lib/new_faq_layout.dart
version: 1.0.0
description: A placeholder layout for the FAQ section indicating future development.
author: Dvwn
date: 2024-06-10
*/
import 'package:flutter/material.dart';

class FaqLayout extends StatelessWidget {
  const FaqLayout({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: PlaceholderWidget(),
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  const PlaceholderWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.construction, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "FAQ Layout Coming Soon",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "This section is under development.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
