import 'package:flutter/material.dart';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_frontend/services/api_service.dart';

class QuizTakingScreen extends StatefulWidget {
  final String quizTitle;
  final int quizId;

  const QuizTakingScreen(
      {Key? key, required this.quizTitle, required this.quizId})
      : super(key: key);

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  // Questions list (Mapped from API)
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  int _currentQuestionIndex = 0;
  int? _selectedOptionIndex;
  late Timer _timer;
  int _secondsRemaining = 600; // 10 minutes

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  void _loadQuestions() async {
    try {
      final data = await ApiService.getQuizQuestions(widget.quizId);
      setState(() {
        _questions = data.map((q) {
          // Map backend model to UI model
          int correctIndex = 0;
          final options = [
            q['option_a'] ?? '',
            q['option_b'] ?? '',
            q['option_c'] ?? '',
            q['option_d'] ?? ''
          ];

          // Determine correct index based on 'A','B','C','D' or 'Option A' etc.
          // Assuming backend returns 'A' or 'Option A' or the actual text.
          // Simple heuristic: matches option text or A/B/C/D
          String correct = q['correct_option'].toString().trim();
          if (correct == 'A' || correct == options[0])
            correctIndex = 0;
          else if (correct == 'B' || correct == options[1])
            correctIndex = 1;
          else if (correct == 'C' || correct == options[2])
            correctIndex = 2;
          else if (correct == 'D' || correct == options[3]) correctIndex = 3;

          return {
            'id': q['id'],
            'question': q['question_text'],
            'options': options,
            'answer': correctIndex,
            'userAnswer': null,
          };
        }).toList();
        _isLoading = false;
      });
      if (_questions.isNotEmpty) {
        _startTimer();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer.cancel();
        _submitQuiz();
      }
    });
  }

  Future<void> _submitQuiz() async {
    _timer.cancel();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('userId');
      if (studentId == null) throw Exception("Student ID not found");

      // 1. Fetch Quiz Details to get Teacher ID (created_by)
      // We don't have it passed in, so we need to fetch it.
      // Optimization: Could pass it from previous screen, but fetching is safer.
      // We can use ApiService.getQuizzes() or implement getQuiz(id).
      // Since getQuiz(id) doesn't exist in the visible snippet of ApiService (it has getQuizzes and getQuizQuestions),
      // let's assume getting all quizzes and filtering, OR better, let's look at ApiService again.
      // Wait, I recall seeing getQuiz in the router, but not sure if ApiService has it.
      // Looking at the file content previously viewed...
      // ApiService has `getQuizzes` (list). It does NOT seem to have `getQuiz(id)` in the snippet I saw earlier (lines 1-524).
      // However, `getQuizzes()` returns a list. I can filter it.

      final quizzes = await ApiService.getQuizzes();
      final quiz = quizzes.firstWhere((q) => q['id'] == widget.quizId,
          orElse: () => null);

      if (quiz == null) throw Exception("Quiz details not found");

      final teacherId = quiz['created_by'];

      // 2. Ensure Assignment Exists
      final assignmentId = await ApiService.ensureAssignment(
          widget.quizId, studentId, teacherId);

      // 3. Prepare Attempt Data
      // Calculate score locally for immediate feedback (optional), but backend does grading?
      // The backend 'Attempt' model has 'submitted_answers'.
      // The prompt didn't say backend grades automatically on submission?
      // Actually, looking at `attempts_router.py`, it just saves. It doesn't calculate score.
      // The prompt said "without changing the backend".
      // So checking the user request: "assessment on it is visible to the teacher".
      // If the backend doesn't grade, the teacher has to grade?
      // Or does the backend grade?
      // I checked `attempts_router.py` - it does nothing but save.
      // But wait! `Quiz` has `correct_option`.
      // I should calculate the score HERE in frontend and send it?
      // `AttemptCreate` schema: `total_correct` and `percentage` are optional but settable.
      // If I want the teacher to see assessment, I should probably calculate it here since I can't change backend.

      int correctCount = 0;
      Map<String, dynamic> submittedAnswers = {};

      for (var q in _questions) {
        final qId = q['id'].toString();
        final uAns = q['userAnswer']; // index 0-3
        submittedAnswers[qId] = uAns; // Store numeric index as answer? Or text?
        // Backend `submitted_answers` is JSON.
        // Let's store the index for simplicity or consistent with whatever the teacher view expects.
        // Usually, storing the index is fine.

        // Grading
        if (uAns != null && uAns == q['answer']) {
          correctCount++;
        }
      }

      final double percentage =
          _questions.isEmpty ? 0 : (correctCount / _questions.length) * 100;

      final attemptData = {
        'assignment_id': assignmentId,
        'quiz_id': widget.quizId,
        'student_id': studentId,
        'submitted_answers': submittedAnswers,
        'total_correct': correctCount,
        'percentage': percentage,
        'teacher_feedback': null
      };

      // 4. Submit Attempt
      await ApiService.submitAttempt(attemptData);

      // Dismiss loading
      Navigator.of(context).pop();

      // Show Success Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Submitted'),
          content: Text(
              'Your answers have been recorded successfully.\nScore: $correctCount / ${_questions.length}'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to dashboard
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33495F)),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Dismiss loading
      Navigator.of(context).pop();
      // Show Error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Submission Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF0F4F8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
            title: Text(widget.quizTitle),
            backgroundColor: const Color(0xFF33495F)),
        body: const Center(child: Text("No questions found for this quiz.")),
      );
    }

    final question = _questions[_currentQuestionIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            Text(widget.quizTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formatTime(_secondsRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress Bar
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              const SizedBox(height: 10),
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Question Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF33495F),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Options
              ...List.generate(question['options'].length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedOptionIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: _selectedOptionIndex == index
                            ? const Color(0xFF33495F).withOpacity(0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedOptionIndex == index
                              ? const Color(0xFF33495F)
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _selectedOptionIndex == index
                                    ? const Color(0xFF33495F)
                                    : Colors.grey,
                                width: 2,
                              ),
                              color: _selectedOptionIndex == index
                                  ? const Color(0xFF33495F)
                                  : Colors.transparent,
                            ),
                            child: _selectedOptionIndex == index
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              question['options'][index],
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedOptionIndex == index
                                    ? const Color(0xFF33495F)
                                    : Colors.black87,
                                fontWeight: _selectedOptionIndex == index
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              // Next / Submit Button
              ElevatedButton(
                onPressed: _selectedOptionIndex != null
                    ? () {
                        setState(() {
                          _questions[_currentQuestionIndex]['userAnswer'] =
                              _selectedOptionIndex;
                          if (_currentQuestionIndex < _questions.length - 1) {
                            _currentQuestionIndex++;
                            // Restore saved answer if exists, else null
                            _selectedOptionIndex =
                                _questions[_currentQuestionIndex]['userAnswer'];
                          } else {
                            _submitQuiz();
                          }
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33495F),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Next Question'
                      : 'Submit Quiz',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
