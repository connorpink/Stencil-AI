import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_states.dart';
import 'package:go_router/go_router.dart';

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
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), _handleRedirect);
  }

  void _handleRedirect() {
    if (!mounted) { return; }

    final authCubit = context.read<AuthCubit>();

    if (authCubit.state is Unauthenticated) { context.go('/auth'); }
    else { context.go('/home'); }
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
                "Stencil-AI",
                style: TextStyle(
                  fontSize: 45,
                )
              ),
              Text(
                "It's not a masterpiece without you"
              )
            ]
          )
        ),
      ),
    );
  }
}