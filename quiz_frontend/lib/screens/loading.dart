import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF33495F)),
              ),
              const SizedBox(height: 24),
              const Text(
                'Generating Quiz...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please wait while the questions are being created.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5A6A78),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              LinearProgressIndicator(
                value: 0.75, // Placeholder value for demonstration
                backgroundColor: Colors.grey[300],
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF33495F)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
