import 'package:flutter/material.dart';
import '../../../services/api_service.dart';

class AddEditStudentScreen extends StatefulWidget {
  final Map<String, dynamic>? student;

  const AddEditStudentScreen({Key? key, this.student}) : super(key: key);

  @override
  State<AddEditStudentScreen> createState() => _AddEditStudentScreenState();
}

class _AddEditStudentScreenState extends State<AddEditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _regNoController;
  late TextEditingController _semesterController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.student?['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.student?['email'] ?? '');
    _regNoController =
        TextEditingController(text: widget.student?['reg_no'] ?? '');
    _semesterController =
        TextEditingController(text: widget.student?['semester'] ?? '');
    _passwordController = TextEditingController(); // Empty initially
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _regNoController.dispose();
    _semesterController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final data = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'reg_no': _regNoController.text.trim(),
      'semester': _semesterController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    try {
      if (widget.student == null) {
        // Add
        await ApiService.addStudent(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student added successfully')),
          );
        }
      } else {
        // Edit
        await ApiService.updateStudent(widget.student!['id'], data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student updated successfully')),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.student != null;
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F3),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Student' : 'Add New Student'),
        backgroundColor: const Color(0xFF33495F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                validator: (v) => v!.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                validator: (v) => v!.isEmpty || !v.contains('@')
                    ? 'Valid email required'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _regNoController,
                label: 'Registration Number',
                icon: Icons.badge,
                validator: (v) => v!.isEmpty ? 'Reg No is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _semesterController,
                label: 'Semester',
                icon: Icons.school,
                validator: (v) => v!.isEmpty ? 'Semester is required' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: isEdit
                    ? 'Password (leave blank to keep current)'
                    : 'Password',
                icon: Icons.lock,
                isPassword: true,
                validator: (v) => (!isEdit && (v == null || v.length < 6))
                    ? 'Password must be at least 6 chars'
                    : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveStudent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33495F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Update Student' : 'Add Student',
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }
}
