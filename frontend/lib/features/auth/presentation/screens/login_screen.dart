/*
Login page

user can log in with their username and password

once signed in the user will be directed to the home page
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_state.dart';
import 'package:flutter_frontend/features/auth/presentation/widgets/auth_button_widget.dart';
import 'package:flutter_frontend/features/auth/presentation/widgets/auth_error.dart';
import 'package:flutter_frontend/features/auth/presentation/widgets/auth_textfield_widget.dart';

class LoginScreen extends StatefulWidget{
  final void Function()? togglePages;

  const LoginScreen({
    super.key, 
    required this.togglePages
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  //text controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  String? errorMessage;

  void login() {
    final username = usernameController.text;
    final password = passwordController.text;

    final authCubit = context.read<AuthCubit>();

    if (username.isEmpty) { return setState(() { errorMessage = "invalid username"; }); }
    if (password.isEmpty) { return setState(() { errorMessage = "invalid password"; }); }

    authCubit.login(username, password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) { setState(() { errorMessage = state.message; } ); }
      },

      builder:(context, state) {
        final isLoading = state is AuthLoading;

        return Stack(
          children: [
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                
                    // logo
                    Icon(
                      Icons.lock_open,
                      size: 80,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 25),
                
                    // app name
                    Text(
                      "Stencil-AI",
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 25),
                
                    // username textfield
                    CustomTextField(
                      controller: usernameController,
                      hintText: "Username",
                      obscureText: false,
                    ),

                    const SizedBox(height: 10),

                    // password textfield
                    CustomTextField(
                      controller: passwordController,
                      hintText: "Password",
                      obscureText: true
                    ),

                    // error box (only show if errorMessage exists)
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      ErrorMessage(errorText: errorMessage!),
                    ],

                    const SizedBox(height: 10),

                    // forgot password
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Forgot Password?",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          )
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    //login button
                    CustomButton(
                      onTap: login,
                      text: "Login"
                    ),

                    const SizedBox(height: 25),

                    // dont have an account option
                    Row(
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.togglePages,
                          child: Text(
                            " Register now",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            if (isLoading) ...[
              AbsorbPointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ]
          ]
        );
      },
    );
  }
}