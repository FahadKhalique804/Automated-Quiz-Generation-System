import 'package:flutter/material.dart';

class RegisterTeacherScreen extends StatefulWidget {
  final Function(int) onSegmentedControlChanged;

  const RegisterTeacherScreen({
    Key? key,
    required this.onSegmentedControlChanged,
  }) : super(key: key);

  @override
  State<RegisterTeacherScreen> createState() => _RegisterTeacherScreenState();
}

class _RegisterTeacherScreenState extends State<RegisterTeacherScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _teacherIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F3),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              Image.asset(
                'assets/images/1 Logo.png',
                height: 150,
              ),
              const SizedBox(height: 32),

              // Login/Register Segmented Control
              _buildSegmentedControl(),
              const SizedBox(height: 48),

              // Teacher Registration Text
              const Text(
                'Teacher Registration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F),
                ),
              ),
              const SizedBox(height: 24),

              // Name Text Field
              _buildTextField(
                controller: _nameController,
                labelText: 'Full Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              // Teacher ID Text Field
              _buildTextField(
                controller: _teacherIdController,
                labelText: 'Teacher ID',
                icon: Icons.badge,
              ),
              const SizedBox(height: 16),

              // Email Text Field
              _buildTextField(
                controller: _emailController,
                labelText: 'Email',
                icon: Icons.email,
              ),
              const SizedBox(height: 16),

              // Password Text Field
              _buildTextField(
                controller: _passwordController,
                labelText: 'Password',
                icon: Icons.lock,
                isPassword: true,
              ),
              const SizedBox(height: 48),

              // Signup Button
              ElevatedButton(
                onPressed: () {
                  // Handle teacher registration logic
                  print(
                      'Registering Teacher: ${_nameController.text}, ID: ${_teacherIdController.text}, Email: ${_emailController.text}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF33495F),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Signup',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: Color(0xFF33495F),
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onSegmentedControlChanged(0);
                    },
                    child: const Text(
                      ' Login',
                      style: TextStyle(
                        color: Color(0xFF33495F),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build the segmented control
  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton(
            label: 'Login',
            isSelected: false,
            onTap: () => widget.onSegmentedControlChanged(0),
          ),
          _buildSegmentButton(
            label: 'Register',
            isSelected: true,
            onTap: () => widget.onSegmentedControlChanged(1),
          ),
        ],
      ),
    );
  }

  // Helper widget to build the individual segmented control button
  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF33495F) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF33495F),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // Helper widget for text fields
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
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
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
          prefixIcon: Icon(icon, color: const Color(0xFFB0B0B0)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
