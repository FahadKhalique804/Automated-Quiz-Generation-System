import 'package:flutter/material.dart';
import 'package:quiz_frontend/services/api_service.dart';

class QuizResultDetailScreen extends StatefulWidget {
  final Map<String, dynamic> attempt;
  final String quizTitle;

  const QuizResultDetailScreen(
      {Key? key, required this.attempt, required this.quizTitle})
      : super(key: key);

  @override
  State<QuizResultDetailScreen> createState() => _QuizResultDetailScreenState();
}

class _QuizResultDetailScreenState extends State<QuizResultDetailScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final quizId = widget.attempt['quiz_id'];
      final questions = await ApiService.getQuizQuestions(quizId);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading details: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.attempt['percentage'] ?? 0;
    final totalCorrect = widget.attempt['total_correct'] ?? 0;
    final submittedAnswers = widget.attempt['submitted_answers'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.quizTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Score Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          CircularProgressIndicator(
                            value: score / 100,
                            backgroundColor: Colors.grey.shade200,
                            color: score >= 50 ? Colors.green : Colors.red,
                            strokeWidth: 8,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${score.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$totalCorrect / ${_questions.length} Correct',
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Detailed Breakdown",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  // Questions List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _questions.length,
                    itemBuilder: (context, index) {
                      final q = _questions[index];
                      final qId = q['id'].toString();

                      // Identify User Answer
                      // Submitted answers are likely stored as Stringified Int (e.g. "0") or Int (0)
                      // "0" -> Option A, "1" -> Option B etc.
                      final rawUserAns = submittedAnswers[qId];
                      int? userAnsIdx;
                      if (rawUserAns != null) {
                        userAnsIdx = int.tryParse(rawUserAns.toString());
                      }

                      // Identify Correct Answer
                      // ApiService maps q['correct_option'] usually as String "A", "B"... or text
                      // Let's resolve it.
                      // Similar logic to QuizTakingScreen
                      final options = [
                        q['option_a'] ?? '',
                        q['option_b'] ?? '',
                        q['option_c'] ?? '',
                        q['option_d'] ?? ''
                      ];

                      int correctMsgIdx = 0;
                      String correctStr = q['correct_option'].toString().trim();
                      if (correctStr == 'A' || correctStr == options[0])
                        correctMsgIdx = 0;
                      else if (correctStr == 'B' || correctStr == options[1])
                        correctMsgIdx = 1;
                      else if (correctStr == 'C' || correctStr == options[2])
                        correctMsgIdx = 2;
                      else if (correctStr == 'D' || correctStr == options[3])
                        correctMsgIdx = 3;

                      final isCorrect = (userAnsIdx == correctMsgIdx);
                      final isSkipped = (userAnsIdx == null);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: isCorrect
                            ? Colors.green.shade50
                            : (isSkipped
                                ? Colors.orange.shade50
                                : Colors.red.shade50),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Q${index + 1}: ${q['question_text']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Your Answer: ${isSkipped ? 'Skipped' : options[userAnsIdx!]}",
                                style: TextStyle(
                                    color: isCorrect
                                        ? Colors.green.shade800
                                        : (isSkipped
                                            ? Colors.orange.shade800
                                            : Colors.red.shade800),
                                    fontWeight: FontWeight.bold),
                              ),
                              if (!isCorrect) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Correct Answer: ${options[correctMsgIdx]}",
                                  style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
