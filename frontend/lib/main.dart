import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/data/nestjs_auth_repo.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/auth_screen.dart';
import 'package:flutter_frontend/features/drawing/data/models/offset.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/home_screen.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/splash_screen.dart';
import 'package:flutter_frontend/themes/light_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/drawing/data/models/stroke.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(OffsetCustomAdapter());
  Hive.registerAdapter(StrokeAdapter());

  await Hive.openBox<Map<dynamic, dynamic>>('drawings');
  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  MainApp({super.key});

  final server = NestJsAuthRepo();

  @override
  
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepo: server),
        )
      ],

      child: MaterialApp(
        title: 'Stencil-AI',
        debugShowCheckedModeBanner: false,

        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/home': (context) => const HomeScreen(),
          '/draw': (context) => const DrawScreen(),
          '/authenticate': (context) => const AuthScreen(),
        },
        theme: lightMode,
      ),
    );
  }
}
