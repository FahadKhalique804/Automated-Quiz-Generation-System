import 'package:flutter/material.dart';
import 'courses_tab.dart';
import 'allocations_tab.dart';

class CourseAllocationScreen extends StatelessWidget {
  const CourseAllocationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4F8),
        appBar: AppBar(
          title: const Text('Course Allocation'),
          backgroundColor: const Color(0xFF33495F),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white, // Color for selected tab text/icon
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.book), text: 'Manage Courses'),
              Tab(icon: Icon(Icons.link), text: 'Allocations'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CoursesTab(),
            AllocationsTab(),
          ],
        ),
      ),
    );
  }
}
