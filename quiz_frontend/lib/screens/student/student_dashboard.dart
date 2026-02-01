import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:quiz_frontend/screens/login.dart';
import 'package:quiz_frontend/screens/student/pending_quizzes_screen.dart';
import 'package:quiz_frontend/screens/student/quiz_history_screen.dart';
import 'package:quiz_frontend/screens/student/graded_quizzes_screen.dart';
import 'package:quiz_frontend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentDashboardScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const StudentDashboardScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPendingCount();
  }

  Future<void> _fetchPendingCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getInt('userId');
      if (studentId == null) return;

      final enrollments = await ApiService.getEnrollmentsByStudent(studentId);
      final enrolledCourseIds = enrollments.map((e) => e['course_id']).toSet();

      final lectureNotes = await ApiService.getLectureNotes();
      final notesMap = {for (var n in lectureNotes) n['id']: n['course_id']};

      final allQuizzes = await ApiService.getQuizzes();
      final attempts = await ApiService.getAttemptsByStudent(studentId);
      final attemptedQuizIds = attempts.map((a) => a['quiz_id']).toSet();

      final count = allQuizzes.where((q) {
        // CORRECTION: Backend field is lecture_notes_id, NOT lecture_note_id
        final noteId = q['lecture_notes_id'];
        final courseId = notesMap[noteId];
        final isPublished = q['is_published'] == true;
        return enrolledCourseIds.contains(courseId) &&
            isPublished &&
            !attemptedQuizIds.contains(q['id']);
      }).length;

      if (mounted) setState(() => _pendingCount = count);
    } catch (e) {
      if (kDebugMode) print("Error fetching pending count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Student Dashboard',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) =>
                            LoginScreen(onLoginSuccess: (role) {})),
                    (route) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Student',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF33495F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Track your progress and take quizzes.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  _buildDashboardCard(
                    context,
                    title: 'Pending Quizzes',
                    icon: Icons.assignment_late,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PendingQuizzesScreen()))
                          .then((_) => _fetchPendingCount());
                    },
                    badgeCount: _pendingCount,
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Quiz History',
                    icon: Icons.history,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const StudentQuizHistoryScreen()));
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Graded Quizzes',
                    icon: Icons.grade,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const GradedQuizzesScreen()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
      int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                    child: CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, size: 30, color: color),
                )),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF33495F),
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              right: 15,
              top: 15,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
