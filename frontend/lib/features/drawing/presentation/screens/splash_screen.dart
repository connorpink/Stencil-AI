import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1)
      .animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) { return; }
      Navigator.pushReplacementNamed(context, '/home');
    });

    super.initState();
  }

  @override 
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                'Stencil-AI',
                style: TextStyle(
                  fontSize: 45,
                )
              ),
              Text(
                'It\'s not a masterpiece without you'
              )
            ]
          )
        ),
      ),
    );
  }
}