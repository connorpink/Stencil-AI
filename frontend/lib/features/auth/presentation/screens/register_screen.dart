/*
Login page

user can log in with their username and password

once signed in the user will be directed to the home page
*/

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/auth/presentation/components/custom_button.dart';
import 'package:flutter_frontend/features/auth/presentation/components/custom_textfield.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
          
              // logo
              Icon(
                Icons.lock_open,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 25),
          
              // app name
              Text(
                "Stencil-AI",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 25),
          
              // username textfield
              CustomTextField(
                controller: usernameController,
                hintText: "Username",
                obscureText: false,
              ),

              // email textfield
              CustomTextField(
                controller: usernameController,
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

              const SizedBox(height: 10),

              // forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )
                  ),
                ],
              ),

              const SizedBox(height: 10),

              //login button
              CustomButton(
                onTap: (){},
                text: "Create Account"
              ),

              const SizedBox(height: 25),

              // dont have an account option
              Row(
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary
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
      )
    );
  }
}