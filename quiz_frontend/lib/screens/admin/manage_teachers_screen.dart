import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import 'add_edit_teacher_screen.dart';
import 'teacher_details_screen.dart';

class ManageTeachersScreen extends StatefulWidget {
  const ManageTeachersScreen({Key? key}) : super(key: key);

  @override
  State<ManageTeachersScreen> createState() => _ManageTeachersScreenState();
}

class _ManageTeachersScreenState extends State<ManageTeachersScreen> {
  List<dynamic> _allTeachers = [];
  List<dynamic> _filteredTeachers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
    _searchController.addListener(_filterTeachers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await ApiService.getTeachers();
      setState(() {
        _allTeachers = teachers;
        _filteredTeachers = teachers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching teachers: $e')),
      );
    }
  }

  void _filterTeachers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredTeachers = _allTeachers.where((teacher) {
        final name = teacher['name']?.toString().toLowerCase() ?? '';
        final id = teacher['id']?.toString().toLowerCase() ?? '';
        return name.contains(query) || id.contains(query);
      }).toList();
    });
  }

  void _navigateToAddTeacher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddEditTeacherScreen()),
    );
    if (result == true) {
      _fetchTeachers();
    }
  }

  void _navigateToTeacherDetails(Map<String, dynamic> teacher) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherDetailsScreen(teacherId: teacher['id']),
      ),
    );
    if (result == true) {
      _fetchTeachers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F3),
      appBar: AppBar(
        title: const Text('Manage Teachers'),
        backgroundColor: const Color(0xFF33495F),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddTeacher,
        backgroundColor: const Color(0xFF33495F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Name or ID',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTeachers.isEmpty
                    ? const Center(child: Text('No teachers found'))
                    : ListView.builder(
                        itemCount: _filteredTeachers.length,
                        itemBuilder: (context, index) {
                          final teacher = _filteredTeachers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF33495F),
                                child: Text(
                                  teacher['name'] != null &&
                                          teacher['name'].isNotEmpty
                                      ? teacher['name'][0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(teacher['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(teacher['email'] ?? ''),
                              onTap: () => _navigateToTeacherDetails(teacher),
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
