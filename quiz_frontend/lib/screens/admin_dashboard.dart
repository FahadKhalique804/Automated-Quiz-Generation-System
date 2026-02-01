import 'package:flutter/material.dart';
import 'package:quiz_frontend/screens/admin/student_management/manage_students_screen.dart';
import 'package:quiz_frontend/screens/admin/teacher_management/manage_teachers_screen.dart';
import 'package:quiz_frontend/screens/admin/course_allocation/course_allocation_screen.dart';
import 'package:quiz_frontend/screens/admin/enrollment_management/enrollment_course_list_screen.dart';
import 'package:quiz_frontend/screens/login.dart';

class AdminDashboardScreen extends StatelessWidget {
  final VoidCallback? onLogout;

  const AdminDashboardScreen({Key? key, this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Admin Dashboard',
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
                // Fallback logout if using direct navigation
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => LoginScreen(
                            onLoginSuccess: (role) {} // No-op, just resetting
                            )),
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
              'Welcome, Admin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF33495F),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage your university users below.',
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
                    title: 'Manage Students',
                    icon: Icons.people,
                    color: Colors.blueAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageStudentsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Manage Teachers',
                    icon: Icons.school,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageTeachersScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Course Allocation',
                    icon: Icons.class_,
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CourseAllocationScreen(),
                        ),
                      );
                    },
                  ),
                  _buildDashboardCard(
                    context,
                    title: 'Course Enrollment',
                    icon: Icons.school,
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const EnrollmentCourseListScreen(),
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
