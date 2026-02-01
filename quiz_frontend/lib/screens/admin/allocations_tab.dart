import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';
import 'assign_teacher_screen.dart';

class AllocationsTab extends StatefulWidget {
  const AllocationsTab({Key? key}) : super(key: key);

  @override
  State<AllocationsTab> createState() => _AllocationsTabState();
}

class _AllocationsTabState extends State<AllocationsTab> {
  List<dynamic> _allocations = [];
  List<dynamic> _teachers = [];
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final allocations = await ApiService.getAllocations();
      final teachers = await ApiService.getTeachers();
      final courses = await ApiService.getCourses();

      setState(() {
        _allocations = allocations;
        _teachers = teachers;
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  String _getTeacherName(int id) {
    final t = _teachers.firstWhere((t) => t['id'] == id, orElse: () => null);
    return t != null ? t['name'] : 'Unknown Teacher ($id)';
  }

  String _getCourseTitle(int id) {
    final c = _courses.firstWhere((c) => c['id'] == id, orElse: () => null);
    return c != null ? '${c['code']} - ${c['title']}' : 'Unknown Course ($id)';
  }

  Future<void> _removeAllocation(int teacherId, int courseId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Allocation'),
        content: const Text(
            'Are you sure you want to remove this teacher from this course?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.removeAllocation(teacherId, courseId);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Allocation removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing: $e')),
          );
        }
      }
    }
  }

  void _navigateToAssign() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignTeacherScreen(),
      ),
    );
    if (result == true) {
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _navigateToAssign,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Assign Teacher',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF33495F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allocations.isEmpty
                  ? const Center(child: Text('No allocations found'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                                label: Text('Teacher',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Course',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            DataColumn(
                                label: Text('Actions',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                          ],
                          rows: _allocations.map((allocation) {
                            final teacherName =
                                _getTeacherName(allocation['teacher_id']);
                            final courseTitle =
                                _getCourseTitle(allocation['course_id']);
                            return DataRow(cells: [
                              DataCell(Text(teacherName)),
                              DataCell(Text(courseTitle)),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _removeAllocation(
                                      allocation['teacher_id'],
                                      allocation['course_id']),
                                ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
