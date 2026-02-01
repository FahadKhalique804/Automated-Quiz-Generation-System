import 'package:flutter/material.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_frontend/screens/student/quiz_result_detail_screen.dart';

class StudentQuizHistoryScreen extends StatefulWidget {
  const StudentQuizHistoryScreen({Key? key}) : super(key: key);

  @override
  State<StudentQuizHistoryScreen> createState() =>
      _StudentQuizHistoryScreenState();
}

class _StudentQuizHistoryScreenState extends State<StudentQuizHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _attempts = [];
  Map<int, String> _quizTitles = {};

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
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

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown Date';
    try {
      final date = DateTime.parse(dateStr);
      // Pad with 0 for better formatting
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      return "${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)} ${twoDigits(date.hour)}:${twoDigits(date.minute)}";
    } catch (_) {
      return dateStr;
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
          : _attempts.isEmpty
              ? const Center(child: Text("No past attempts."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _attempts.length,
                  itemBuilder: (context, index) {
                    final attempt = _attempts[index];
                    final quizId = attempt['quiz_id'];
                    final title = _quizTitles[quizId] ?? 'Unknown Quiz';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading:
                            const Icon(Icons.history, color: Colors.blueAccent),
                        title: Text(title),
                        subtitle: Text(
                            'Submitted: ${_formatDate(attempt['submitted_at'])}'),
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
