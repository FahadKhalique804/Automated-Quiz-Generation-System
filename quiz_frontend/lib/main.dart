import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_frontend/screens/login.dart';
import 'package:quiz_frontend/screens/splash_screen.dart'; 
import 'package:quiz_frontend/screens/admin_dashboard.dart';
import 'package:quiz_frontend/screens/teacher/teacher_dashboard.dart';
import 'package:quiz_frontend/screens/student/student_dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quizine AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        fontFamily: 'Roboto', // Ensure this font is available or use default
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const SplashScreen(), // Set Splash Screen as home
    );
  }
}

class MainScreen extends StatefulWidget {
  final String?
      initialRole; // Optional: to navigate directly if logic allows later
  const MainScreen({Key? key, this.initialRole}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 0: Login, 1: Teacher Dashboard, 2: Student Dashboard, 3: Admin Dashboard
  int _selectedIndex = 0;
  String _selectedRole = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      _loginAndNavigate(widget.initialRole!);
    }
  }

  void _loginAndNavigate(String role) {
    setState(() {
      _selectedRole = role;
      if (role == 'teacher') {
        _selectedIndex = 1;
      } else if (role == 'student') {
        _selectedIndex = 2;
      } else if (role == 'admin') {
        _selectedIndex = 3;
      }
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    setState(() {
      _selectedIndex = 0;
      _selectedRole = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget screen;
    switch (_selectedIndex) {
      case 0:
        screen = LoginScreen(
          onLoginSuccess: _loginAndNavigate,
        );
        break;
      case 1:
        screen = const TeacherDashboardScreen();
        // screen = TeacherDashboardScreen(onLogout: _logout); // Assuming we'll add logout callback
        break;
      case 2:
        screen = StudentDashboardScreen(
          onLogout: _logout,
        );
        break;
      case 3:
        screen = AdminDashboardScreen(
          onLogout: _logout,
        );
        break;
      default:
        screen = const Center(child: Text('Screen not found'));
    }

    // Wrap in Scaffold or return screen directly if screens have their own Scaffolds
    // Since individual screens seem to have Scaffolds, we can return them directly.
    return screen;
  }
}
