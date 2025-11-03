/*
Login page

user can log in with their username and password

once signed in the user will be directed to the home page
*/

import 'package:flutter/material.dart';
import 'package:flutter_frontend/features/auth/presentation/components/custom_button.dart';
import 'package:flutter_frontend/features/auth/presentation/components/custom_textfield.dart';

class LoginPage extends StatefulWidget{
  final void Function()? togglePages;

  const LoginPage({
    super.key, 
    required this.togglePages
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  //text controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

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

              const SizedBox(height: 10),

              // password textfield
              CustomTextField(
                controller: passwordController,
                hintText: "Password",
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
                text: "Login"
              ),

              const SizedBox(height: 25),

              // dont have an account option
              Row(
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary
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
      )
    );
  }
}