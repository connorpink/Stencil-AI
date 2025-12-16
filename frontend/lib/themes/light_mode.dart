import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Colors.red.shade800,
    secondary: Colors.grey.shade200,
    tertiary: Colors.white,
    inversePrimary: Colors.grey.shade900,
    onSurfaceVariant: Colors.grey.shade500,

    //colors for error messages
    errorContainer: Colors.red.shade100,
    onErrorContainer: Colors.red.shade900,

  ),
  scaffoldBackgroundColor: Colors.grey.shade300,
);