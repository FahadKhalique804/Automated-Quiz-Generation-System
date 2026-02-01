import 'package:flutter/material.dart';
import 'package:quiz_frontend/screens/teacher/quiz_generation_screen.dart';
import 'package:quiz_frontend/screens/teacher/quiz_history.dart';
import 'package:quiz_frontend/screens/teacher/assessment_scores.dart';
import 'package:quiz_frontend/screens/teacher/upload_notes_screen.dart';
import 'package:quiz_frontend/screens/login.dart';

class TeacherDashboardScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const TeacherDashboardScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Teacher Dashboard',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              if (onLogout != null) {
                onLogout!();
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
              'Welcome, Teacher',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF33495F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage your quizzes and track student performance.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
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
                    title: 'Generate Quiz',
                    icon: Icons.add_circle_outline,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizGenerationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Quiz History',
                    icon: Icons.history,
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QuizHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Assessment Scores',
                    icon: Icons.analytics_outlined,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AssessmentScoresScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Upload Notes',
                    icon: Icons.upload_file,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadNotesScreen(),
                        ),
                      );
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
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
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
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, size: 30, color: color),
            ),
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
    );
  }
}
