import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/drawing/data/models/stroke.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_frontend/features/auth/data/nestjs_auth_repo.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/auth_screen.dart';
import 'package:flutter_frontend/features/drawing/data/models/offset.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/home_screen.dart';
import 'package:flutter_frontend/shared/screens/splash_screen.dart';
import 'package:flutter_frontend/themes/light_mode.dart';

void main() async {
  /*
  Setup hive (client side database) before proceeding to the main application
  */

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(OffsetCustomAdapter());
  Hive.registerAdapter(StrokeAdapter());

  // open hive
  await Hive.openBox<Map<dynamic, dynamic>>('drawings');

  // setup the reset of the application
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AuthCubit authCubit;
  GoRouter? _router;
  bool _appReady = false;

  final authRepo = NestJsAuthRepo();

  @override
  void initState() {
    super.initState();
    authCubit = AuthCubit(authRepo: authRepo);
    _appStartup();
  }

  Future<void> _appStartup() async {
    await authCubit.checkAuth();

    // pick the starting location
    final initialLocation = switch (authCubit.state) {
      Unauthenticated() => '/auth',
      _ => '/home',
    };

    await Future.delayed(const Duration(seconds: 6));
    
    // create the router
    setState(() {
      _router = _buildRouter(initialLocation);
      _appReady = true;
    });
  }

  GoRouter _buildRouter(String initialLocation) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) { return const HomeScreen(); }
        ),
        GoRoute(
          path: '/draw',
          builder: (context, state) { 
            final name = state.extra as String?;
            return DrawScreen(name: name);
          }
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) { return const AuthScreen(); }
        ),
      ],

      redirect: (context, state) {
        // If server is offline let the user use the drawing app anyway by only redirecting if server confirms the user is unauthenticated
        final isAuthed = authCubit.state is! Unauthenticated;

        // only redirect user if they are in home page (don't interrupt drawing)
        if (!isAuthed && state.matchedLocation.startsWith('/home')) { return '/auth'; }

        // prevent authed users from hanging out on /auth
        if (isAuthed && state.matchedLocation == '/auth') { return '/home'; }

        // do nothing otherwise
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // call the splashScreen without the router
    if (!_appReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        home: const SplashScreen(),
      );
    }

    // once app is ready call the actual page
    return MultiBlocProvider(
      providers: [BlocProvider<AuthCubit>.value(value: authCubit)], 
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: lightMode,
        routerConfig: _router,
      ),
    );
  }

  @override
  void dispose() {
    authCubit.close();
    super.dispose();
  }
}

// event listener for changes to the users authentication status
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) { return notifyListeners(); });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}