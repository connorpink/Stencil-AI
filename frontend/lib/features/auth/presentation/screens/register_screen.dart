/*
Login page

user can log in with their username and password

once signed in the user will be directed to the home page
*/

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/widgets/auth_button_widget.dart';
import 'package:flutter_frontend/features/auth/presentation/widgets/auth_error.dart';
import 'package:flutter_frontend/features/auth/presentation/widgets/auth_textfield_widget.dart';

class RegisterScreen extends StatefulWidget{
  final void Function()? togglePages;

  const RegisterScreen({
    super.key, 
    required this.togglePages
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  //text controllers
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? errorMessage;

  // logic for registering an account
  void register() {
    // prepare info
    final String username = usernameController.text;
    final String email = emailController.text;
    final String password = passwordController.text;
    final String confirmPassword = confirmPasswordController.text;

    // auth cubit
    final authCubit = context.read<AuthCubit>();

    // ensure fields are valid
    if (username.isEmpty) { return setState(() { errorMessage = "invalid username"; }); }
    if (email.isEmpty) { return setState(() { errorMessage = "invalid email"; }); }
    if (password.isEmpty) { return setState(() { errorMessage = "invalid password"; }); }
    if (password != confirmPassword) { return setState(() { errorMessage = "passwords do not match"; }); }

    try {
      authCubit.register(username, email, password)
      .catchError((message) {
        setState(() { errorMessage = message; });
      });
    }
    catch (error) { 
      setState(() { errorMessage = "Error communicating with the server \nPlease try again"; });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            // email textfield
            CustomTextField(
              controller: emailController,
              hintText: "Email",
              obscureText: false,
            ),
            const SizedBox(height: 10),

            // password textfield
            CustomTextField(
              controller: passwordController,
              hintText: "Password",
              obscureText: true
            ),
            const SizedBox(height: 10),

            CustomTextField(
              controller: confirmPasswordController,
              hintText: "Confirm Password",
              obscureText: true
            ),

            // error box (only show if errorMessage exists)
            if (errorMessage != null) ...[
              const SizedBox(height: 10),
              ErrorMessage(errorText: errorMessage!),
            ],

            const SizedBox(height: 25),

            //register button
            CustomButton(
              onTap: register,
              text: "Create Account"
            ),

            const SizedBox(height: 25),

            // dont have an account option
            Row(
              children: [
                Text(
                  "Already have an account?",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                  ),
                ),
                GestureDetector(
                  onTap: widget.togglePages,
                  child: Text(
                    " Login now",
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
    );
  }
}