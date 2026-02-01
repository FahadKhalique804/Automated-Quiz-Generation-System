import 'package:flutter/material.dart';
import 'package:quiz_frontend/screens/teacher/quiz_preview_screen.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizHistoryScreen extends StatefulWidget {
  const QuizHistoryScreen({Key? key}) : super(key: key);

  @override
  State<QuizHistoryScreen> createState() => _QuizHistoryScreenState();
}

class _QuizHistoryScreenState extends State<QuizHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchQuizzes();
  }

  Future<void> _fetchQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final teacherId = prefs.getInt('userId');

      // Ideally we filter by teacher, but for now fetch all
      final allQuizzes = await ApiService.getQuizzes();
      // Filter if needed, but existing endpoint retrieves all.
      // Assuming 'created_by' is in response (it is in Quiz model, checking schema coverage)
      // QuizOut has created_by inherited from QuizBase.

      final myQuizzes = teacherId != null
          ? allQuizzes.where((q) => q['created_by'] == teacherId).toList()
          : allQuizzes;

      setState(() {
        _quizzes = myQuizzes;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _publishQuiz(int id) async {
    try {
      await ApiService.publishQuiz(id);
      _fetchQuizzes(); // Refresh
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Quiz Published!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            const Text('Quiz History', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? const Center(child: Text("No quizzes generated yet."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _quizzes[index];
                    final isPublished = quiz['is_published'] == true;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizPreviewScreen(
                                quizId: quiz['id'],
                                quizTitle: quiz['title'] ?? 'Untitled Quiz',
                              ),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8F1F3),
                          child: Icon(
                              isPublished ? Icons.check_circle : Icons.history,
                              color: isPublished
                                  ? Colors.green
                                  : const Color(0xFF33495F)),
                        ),
                        title: Text(quiz['title'] ?? 'Untitled'),
                        subtitle: Text(
                            '${quiz['total_questions']} Questions • ${isPublished ? "Published" : "Draft"}'),
                        trailing: isPublished
                            ? const Chip(
                                label: Text("Published",
                                    style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.green)
                            : ElevatedButton(
                                onPressed: () => _publishQuiz(quiz['id']),
                                child: const Text("Publish"),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
