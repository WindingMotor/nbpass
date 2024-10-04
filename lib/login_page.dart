import 'package:flutter/material.dart';
import 'teacher_page.dart';
import 'student_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _idController = TextEditingController();

  void _login() {
    String id = _idController.text.trim();
    if (id.isEmpty) {
      _showSnackBar('Please enter an ID');
      return;
    }

    if (id.startsWith('T')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TeacherPage(teacherId: id)),
      );
    } else if (int.tryParse(id) != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => StudentPage(studentId: id)),
      );
    } else {
      _showSnackBar('Invalid ID format');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.school_rounded, size: 80, color: Colors.orange[700]),
                const SizedBox(height: 24),
                Text(
                  'NBPass',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Enter ID',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _login,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
