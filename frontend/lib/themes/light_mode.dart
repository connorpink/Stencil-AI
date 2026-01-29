import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Colors.red.shade800,
    secondary: Colors.blueGrey.shade400,
    onSecondary: Colors.black,
    onSecondaryContainer: Colors.white,
    tertiary: Colors.red.shade900,
    inversePrimary: Colors.grey.shade900,
    surface: Colors.white,
    onSurface: Colors.grey.shade800,

    //colors for error messages
    errorContainer: Colors.red.shade100,
    onErrorContainer: Colors.red.shade900,

  ),
  scaffoldBackgroundColor: Colors.grey.shade300,
);