import 'package:flutter/material.dart';
import '../../../../services/api_service.dart';

class AssignTeacherScreen extends StatefulWidget {
  const AssignTeacherScreen({Key? key}) : super(key: key);

  @override
  State<AssignTeacherScreen> createState() => _AssignTeacherScreenState();
}

class _AssignTeacherScreenState extends State<AssignTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _teachers = [];
  List<dynamic> _courses = [];
  dynamic _selectedTeacher;
  dynamic _selectedCourse;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final teachers = await ApiService.getTeachers();
      final courses = await ApiService.getCourses();
      setState(() {
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

  Future<void> _assign() async {
    if (!_formKey.currentState!.validate() ||
        _selectedTeacher == null ||
        _selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select both a teacher and a course')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ApiService.assignTeacher(
          _selectedTeacher['id'], _selectedCourse['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher assigned successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F3),
      appBar: AppBar(
        title: const Text('Assign Teacher to Course'),
        backgroundColor: const Color(0xFF33495F),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Select Teacher',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF33495F)),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      hint: 'Choose a Teacher',
                      value: _selectedTeacher,
                      items: _teachers.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text('${t['name']} (${t['id']})'),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedTeacher = val),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Select Course',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF33495F)),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown(
                      hint: 'Choose a Course',
                      value: _selectedCourse,
                      items: _courses.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c['code']} - ${c['title']}'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCourse = val),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _assign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF33495F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Assign',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required dynamic value,
    required List<DropdownMenuItem<dynamic>> items,
    required Function(dynamic) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
