import 'package:flutter/material.dart';

class ViewDocumentsScreen extends StatelessWidget {
  final String courseName;

  const ViewDocumentsScreen({Key? key, required this.courseName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy data for uploaded documents.
    final List<String> documents = [
      'Chapter 1: Intro to AI.pdf',
      'AI Algorithms.docx',
      'Machine Learning Models.pdf',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
        backgroundColor: const Color(0xFF33495F),
      ),
      body: Container(
        color: const Color(0xFFE8F1F3),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Uploaded Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: documents.isEmpty
                  ? const Center(
                      child: Text(
                        'No documents uploaded yet.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF5A6A78),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: documents.length,
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
                              documents[index],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF33495F),
                              ),
                            ),
                            trailing: const Icon(Icons.description,
                                color: Color(0xFF33495F)),
                            onTap: () {
                              // TODO: Implement document view or download logic
                            },
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement file upload functionality
              },
              icon: const Icon(Icons.add, size: 24),
              label: const Text('Upload a new document',
                  style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF33495F),
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
