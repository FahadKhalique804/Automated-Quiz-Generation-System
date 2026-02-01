import 'package:flutter/material.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for quiz history
    final List<Map<String, dynamic>> quizHistory = [
      {
        'course': 'Programming Fundamentals',
        'score': 85,
        'date': 'Oct 26, 2023',
        'details': 'Chapter 1 Quiz'
      },
      {
        'course': 'Data Structures',
        'score': 72,
        'date': 'Oct 20, 2023',
        'details': 'Midterm Practice'
      },
      {
        'course': 'Artificial Intelligence',
        'score': 91,
        'date': 'Oct 15, 2023',
        'details': 'Chapter 5: Neural Networks'
      },
      {
        'course': 'Computer Vision',
        'score': 68,
        'date': 'Oct 10, 2023',
        'details': 'Image Processing Quiz'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz History'),
        backgroundColor: const Color(0xFF33495F),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFE8F1F3),
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: quizHistory.length,
          itemBuilder: (context, index) {
            final quiz = quizHistory[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16.0),
                title: Text(
                  quiz['course'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF33495F),
                  ),
                ),
                subtitle: Text(
                  '${quiz['details']} | Date: ${quiz['date']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6A78),
                  ),
                ),
                trailing: Text(
                  'Score: ${quiz['score']}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: quiz['score'] >= 80 ? Colors.green : Colors.red,
                  ),
                ),
                onTap: () {
                  // TODO: Implement navigation to a detailed results screen
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
