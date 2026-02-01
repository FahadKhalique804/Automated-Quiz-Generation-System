import 'package:flutter/material.dart';

class RegistrationRoleSelectorScreen extends StatelessWidget {
  final Function(int) onSegmentedControlChanged;
  final Function(String) onRoleSelected;

  const RegistrationRoleSelectorScreen({
    Key? key,
    required this.onSegmentedControlChanged,
    required this.onRoleSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1F3),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder
              Image.asset(
                'assets/images/logo withoud bg.png',
                height: 150,
              ),
              const SizedBox(height: 32),

              // Login/Register Segmented Control
              _buildSegmentedControl(),
              const SizedBox(height: 48),

              // "Register as" Text
              const Text(
                'Register as:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF33495F),
                ),
              ),
              const SizedBox(height: 24),

              // Student Button
              _buildRoleButton(
                label: 'Student',
                icon: Icons.school,
                onPressed: () {
                  onRoleSelected('student');
                },
              ),
              const SizedBox(height: 24),

              // Teacher Button
              _buildRoleButton(
                label: 'Teacher',
                icon: Icons.person_pin,
                onPressed: () {
                  onRoleSelected('teacher');
                },
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
            onTap: () => onSegmentedControlChanged(0),
          ),
          _buildSegmentButton(
            label: 'Register',
            isSelected: true,
            onTap: () => onSegmentedControlChanged(1),
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

  // Helper widget to build the role selection buttons
  Widget _buildRoleButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF33495F)),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF33495F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
