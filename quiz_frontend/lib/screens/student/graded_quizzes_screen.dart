import 'package:flutter/material.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_frontend/screens/student/quiz_result_detail_screen.dart';

class GradedQuizzesScreen extends StatefulWidget {
  const GradedQuizzesScreen({Key? key}) : super(key: key);

  @override
  State<GradedQuizzesScreen> createState() => _GradedQuizzesScreenState();
}

class _GradedQuizzesScreenState extends State<GradedQuizzesScreen> {
  bool _isLoading = true;
  List<dynamic> _attempts = [];
  Map<int, String> _quizTitles = {};

  @override
  void initState() {
    super.initState();
    _fetchGrades();
  }

  Future<void> _fetchGrades() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('userId');
      if (studentId == null) throw Exception("User ID not found");

      // Fetch Attempts
      final attempts = await ApiService.getAttemptsByStudent(studentId);

      // Fetch Quizzes to get Titles
      final quizzes = await ApiService.getQuizzes();
      final quizMap = {
        for (var q in quizzes) q['id']: q['title'] ?? 'Untitled Quiz'
      };

      setState(() {
        _attempts = attempts;
        _quizTitles = quizMap.cast<int, String>();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            const Text('Graded Quizzes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _attempts.isEmpty
              ? const Center(child: Text("No graded quizzes found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _attempts.length,
                  itemBuilder: (context, index) {
                    final attempt = _attempts[index];
                    final quizId = attempt['quiz_id'];
                    final title = _quizTitles[quizId] ?? 'Unknown Quiz';
                    final score = attempt['percentage'] ?? 0;
                    final isPass = score >= 50;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPass
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          child: Text(
                            '${score.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: isPass ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(isPass ? 'Passed' : 'Failed'),
                        trailing: const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizResultDetailScreen(
                                attempt: attempt,
                                quizTitle: title,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
