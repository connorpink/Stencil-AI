import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/auth/data/nestjs_auth_repo.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/auth_screen.dart';
import 'package:flutter_frontend/features/drawing/data/models/offset.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/home_screen.dart';
import 'package:flutter_frontend/shared/screens/splash_screen.dart';
import 'package:flutter_frontend/themes/light_mode.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/drawing/data/models/stroke.dart';
import 'package:go_router/go_router.dart';

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
          create: (context) { return AuthCubit(authRepo: server)..checkAuth(); },
        )
      ],

      child: _AppRouter(),
    );
  }
}

class _AppRouter extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    // watch for changes in the auth state
    final authCubit = context.watch<AuthCubit>();

    final router = GoRouter(
      initialLocation: '/',

      // rebuild GoRouter based on changes to the auth state
      refreshListenable: GoRouterRefreshStream(authCubit.stream),

      redirect:(context, state) {
        // isAuthenticated should be relative to the Unauthenticated state, as redirects should only happen if the server is reachable (and can confirm authentication status)
        final isAuthenticated = authCubit.state is! Unauthenticated;
        final atAuthScreen = state.matchedLocation == '/auth';
        final atSplashScreen = state.matchedLocation == '/';

        // if user isn't signed in, make sure they are going to or already at the /auth screen
        if (!isAuthenticated && !(atAuthScreen || atSplashScreen)) {
          print("Redirecting to auth screen");
          return '/auth'; 
        }

        // is user is logged in make sure they are no longer at the auth screen
        if (isAuthenticated && atAuthScreen) { 
          print("Redirecting to home screen");
          return '/home';
        }

        // no redirection needed
        return null;
      },

      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) { return const SplashScreen(); }
        ),
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
      
    );

    return MaterialApp.router(
      title: 'Stencil-AI',
      theme: lightMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
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