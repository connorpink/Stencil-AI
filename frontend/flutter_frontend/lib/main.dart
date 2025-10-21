import 'package:flutter/material.dart';
import 'package:flutter_frontend/src/models/offset.dart';
import 'package:flutter_frontend/src/screens/draw_screen.dart';
import 'package:flutter_frontend/src/screens/home_screen.dart';
import 'package:flutter_frontend/src/screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './src/models/stroke.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(OffsetCustomAdapter());
  Hive.registerAdapter(StrokeAdapter());

  await Hive.openBox<Map<dynamic, dynamic>>('drawings');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stencil-AI',
      debugShowCheckedModeBanner: false,

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/draw': (context) => const DrawScreen(),
      },
    );
  }
}
