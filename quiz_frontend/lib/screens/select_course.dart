import 'package:flutter/material.dart';
import 'package:quiz_frontend/screens/view_document.dart';

class SelectCourseScreen extends StatelessWidget {
  const SelectCourseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for courses. This will be replaced with real data later.
    final List<String> courses = [
      'Artificial Intelligence',
      'Computer Vision',
      'Data Structures',
      'Programming Fundamentals',
      'Operating Systems',
      'Calculus',
      'Database Management Systems',
      'Software Engineering'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Course'),
        backgroundColor: const Color(0xFF33495F),
      ),
      body: Container(
        color: const Color(0xFFE8F1F3),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Select a course to upload documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        courses[index],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF33495F),
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios,
                          color: Color(0xFF33495F)),
                      onTap: () {
                        // Navigate to the view documents screen for this course
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ViewDocumentsScreen(courseName: courses[index]),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
