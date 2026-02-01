import 'package:flutter/material.dart';

class PublishQuizScreen extends StatelessWidget {
  const PublishQuizScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy quiz data
    final String questionText = "Which of the following is an input device?";
    final List<String> options = ["Monitor", "Keyboard", "Printer", "Speaker"];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Quiz'),
        backgroundColor: const Color(0xFF33495F),
        elevation: 0,
      ),
      body: Container(
        color: const Color(0xFFE8F1F3),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Quiz Preview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Question Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question 1:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF33495F),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      questionText,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF33495F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Options
                    Column(
                      children: options.map((option) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF33495F),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement quiz download functionality
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Quiz'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF33495F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement quiz publish functionality
                  },
                  icon: const Icon(Icons.publish),
                  label: const Text('Publish Quiz'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF33495F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
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
