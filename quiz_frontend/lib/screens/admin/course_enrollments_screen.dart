import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class CourseEnrollmentsScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseEnrollmentsScreen({Key? key, required this.course})
      : super(key: key);

  @override
  State<CourseEnrollmentsScreen> createState() =>
      _CourseEnrollmentsScreenState();
}

class _CourseEnrollmentsScreenState extends State<CourseEnrollmentsScreen> {
  bool _isLoading = true;
  List<dynamic> _enrollments = [];
  List<dynamic> _allStudents = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final enrollments =
          await ApiService.getEnrollmentsByCourse(widget.course['id']);
      // We need all students to resolve names and for the "Add" dropdown
      final students = await ApiService.getStudents();

      setState(() {
        _enrollments = enrollments;
        _allStudents = students;
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

  String _getStudentName(int id) {
    final s = _allStudents.firstWhere((s) => s['id'] == id, orElse: () => null);
    return s != null ? s['name'] : 'Unknown Student ($id)';
  }

  String _getStudentRegNo(int id) {
    final s = _allStudents.firstWhere((s) => s['id'] == id, orElse: () => null);
    return s != null ? s['reg_no'] ?? '' : '';
  }

  Future<void> _deleteEnrollment(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Student'),
        content: const Text(
            'Are you sure you want to remove this student from the course?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteEnrollment(id);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Removed successfully')));
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddDialog() {
    int? selectedStudentId;
    // Filter out students already enrolled
    final enrolledIds = _enrollments.map((e) => e['student_id']).toSet();
    final availableStudents =
        _allStudents.where((s) => !enrolledIds.contains(s['id'])).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Enroll Student'),
              content: availableStudents.isEmpty
                  ? const Text(
                      'All students are already enrolled in this course.')
                  : DropdownButtonFormField<int>(
                      isExpanded: true,
                      decoration:
                          const InputDecoration(labelText: 'Select Student'),
                      items: availableStudents.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'],
                          child: Text('${s['name']} (${s['reg_no']})'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setStateDialog(() => selectedStudentId = val),
                    ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                if (availableStudents.isNotEmpty)
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedStudentId == null) return;
                      try {
                        await ApiService.enrollStudent(
                            selectedStudentId!, widget.course['id']);
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchData();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Student Enrolled')));
                        }
                      } catch (e) {
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33495F)),
                    child: const Text('Enroll'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: Text('Enrollments: ${widget.course['code']}'),
        backgroundColor: const Color(0xFF33495F),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF33495F),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty
              ? const Center(
                  child: Text('No students enrolled in this course.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _enrollments.length,
                  itemBuilder: (context, index) {
                    final enroll = _enrollments[index];
                    final valid = _allStudents
                        .any((s) => s['id'] == enroll['student_id']);
                    if (!valid)
                      return const SizedBox.shrink(); // Skip stale data

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purpleAccent.withOpacity(0.1),
                          child: const Icon(Icons.school,
                              color: Colors.purpleAccent),
                        ),
                        title: Text(_getStudentName(enroll['student_id']),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(_getStudentRegNo(enroll['student_id'])),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteEnrollment(enroll['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
