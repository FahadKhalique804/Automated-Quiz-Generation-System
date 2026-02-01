import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import 'course_enrollments_screen.dart';

class EnrollmentCourseListScreen extends StatefulWidget {
  const EnrollmentCourseListScreen({Key? key}) : super(key: key);

  @override
  State<EnrollmentCourseListScreen> createState() =>
      _EnrollmentCourseListScreenState();
}

class _EnrollmentCourseListScreenState
    extends State<EnrollmentCourseListScreen> {
  List<dynamic> _allCourses = [];
  List<dynamic> _filteredCourses = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _searchController.addListener(_filterCourses);
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await ApiService.getCourses();
      setState(() {
        _allCourses = courses;
        _filteredCourses = courses;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _filterCourses() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCourses = _allCourses.where((c) {
        final title = c['title']?.toString().toLowerCase() ?? '';
        final code = c['code']?.toString().toLowerCase() ?? '';
        return title.contains(query) || code.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title:
            const Text('Select Course', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF33495F),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Course...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? const Center(child: Text('No courses found'))
                    : ListView.builder(
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    Colors.blueAccent.withOpacity(0.2),
                                child: const Icon(Icons.book,
                                    color: Colors.blueAccent),
                              ),
                              title: Text(course['code'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(course['title'] ?? 'No Title'),
                              trailing:
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CourseEnrollmentsScreen(course: course),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
