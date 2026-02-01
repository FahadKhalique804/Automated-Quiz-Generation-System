import 'package:flutter/material.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_frontend/screens/student/quiz_taking_screen.dart';

class PendingQuizzesScreen extends StatefulWidget {
  const PendingQuizzesScreen({Key? key}) : super(key: key);

  @override
  State<PendingQuizzesScreen> createState() => _PendingQuizzesScreenState();
}

class _PendingQuizzesScreenState extends State<PendingQuizzesScreen> {
  bool _isLoading = true;
  List<dynamic> _pendingQuizzes = [];

  @override
  void initState() {
    super.initState();
    _fetchPendingQuizzes();
  }

  Future<void> _fetchPendingQuizzes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('userId');
      if (studentId == null) throw Exception("User ID not found");

      // 1. Fetch Enrollments
      final enrollments = await ApiService.getEnrollmentsByStudent(studentId);
      final enrolledCourseIds = enrollments.map((e) => e['course_id']).toSet();

      // 2. Map Notes to Courses
      final lectureNotes = await ApiService.getLectureNotes();
      final notesMap = {for (var n in lectureNotes) n['id']: n['course_id']};

      // 3. Fetch All Quizzes
      final allQuizzes = await ApiService.getQuizzes();

      // 4. Filter Available Quizzes:
      // - Correct Course
      // - IS PUBLISHED (New Condition)
      final availableQuizzes = allQuizzes.where((q) {
        // CORRECTION: Backend field is lecture_notes_id, NOT lecture_note_id
        final noteId = q['lecture_notes_id'];
        final courseId = notesMap[noteId];
        final isPublished = q['is_published'] == true;
        return enrolledCourseIds.contains(courseId) && isPublished;
      }).toList();

      // 5. Fetch My Attempts
      final attempts = await ApiService.getAttemptsByStudent(studentId);
      final attemptedQuizIds = attempts.map((a) => a['quiz_id']).toSet();

      // 6. Filter out attempted quizzes
      final pending = availableQuizzes
          .where((q) => !attemptedQuizIds.contains(q['id']))
          .toList();

      setState(() {
        _pendingQuizzes = pending;
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
        title: const Text('Pending Quizzes',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingQuizzes.isEmpty
              ? const Center(child: Text("No pending quizzes found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingQuizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = _pendingQuizzes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orangeAccent,
                          child:
                              Icon(Icons.assignment_late, color: Colors.white),
                        ),
                        // CORRECTION: Backend field is title, NOT topic
                        title: Text(quiz['title'] ?? 'Untitled Quiz'),
                        // CORRECTION: Backend field is avg_difficulty, NOT difficulty
                        subtitle: Text(
                            'Difficulty: ${quiz['avg_difficulty'] ?? "Medium"}'),
                        trailing: Stack(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizTakingScreen(
                                      // CORRECTION: Backend field is title
                                      quizTitle: quiz['title'] ?? 'Quiz',
                                      quizId: quiz['id'],
                                    ),
                                  ),
                                ).then((_) => _fetchPendingQuizzes());
                              },
                              child: const Text('Start'),
                            ),
                            const Positioned(
                              right: 0,
                              top: 0,
                              child: CircleAvatar(
                                radius: 5,
                                backgroundColor: Colors.red,
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
