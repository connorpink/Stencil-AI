import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/register_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthScreen> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) { return LoginScreen(togglePages: togglePages); }
    else { return RegisterScreen(togglePages: togglePages); }
  }
}