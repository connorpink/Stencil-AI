import 'dart:async';
import 'package:flutter_frontend/features/drawing/data/datasources/artwork_local_datasource.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/drawing/data/models/stroke_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/drawing/data/models/artwork_model.dart';
import 'package:flutter_frontend/features/drawing/data/models/stencil_model.dart';
import 'package:flutter_frontend/features/drawing/data/repositories/artwork_repository_logic.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/prompt_screen.dart';
import 'package:flutter_frontend/features/auth/data/auth_repository.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_states.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/auth_screen.dart';
import 'package:flutter_frontend/features/drawing/data/models/offset_model.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/draw_screen.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/home_screen.dart';
import 'package:flutter_frontend/shared/splash_screen.dart';
import 'package:flutter_frontend/themes/light_mode.dart';

void main() async {
  /*
    Setup hive (client side database) before proceeding to the main application
  */

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register the adapters
  Hive.registerAdapter(ArtworkModelAdapter());
  Hive.registerAdapter(StencilModelAdapter());
  Hive.registerAdapter(StrokeModelAdapter());
  Hive.registerAdapter(OffsetModelAdapter());

  // open hive
  await Hive.openBox<ArtworkModel>('artwork');

  /*
    Setup the main application
  */
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AuthCubit authCubit;
  late final Box<ArtworkModel> artworkBox;
  GoRouter? _router;
  bool _appReady = false;

  final authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    authCubit = AuthCubit(authRepository: authRepository);
    _appStartup();
  }

  Future<void> _appStartup() async {
    // pick the starting location
    final initialLocation = switch (authCubit.state) {
      Unauthenticated() => '/auth',
      _ => '/home',
    };

    // configure hive while the splash screen plays
    artworkBox = Hive.box<ArtworkModel>('artwork');
    await authCubit.checkAuth();
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
          path: '/createPrompt',
          builder: (context, state) { return const PromptScreen(); }
        ),
        GoRoute(
          path: '/draw',
          builder: (context, state) { 
            final id = state.extra as String?;
            return DrawScreen(id: id);
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
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        RepositoryProvider<ArtworkRepositoryInterface>(
          create: (context) => ArtworkRepositoryLogic(
            localDatasource: ArtworkLocalDatasource(artworkBox)
          ),
        )
      ], 
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

// event listener for changes to the users authentication status, watches for changes to Authenticated and Unauthenticated
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;
  dynamic _lastState; // Keep track of the previous state

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((state) {
      // Only react when the state changes to Authenticated or Unauthenticated
      if (state.runtimeType != _lastState?.runtimeType && (state is Authenticated || state is Unauthenticated)) { notifyListeners(); }
      _lastState = state;
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}