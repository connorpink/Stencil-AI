import 'dart:async';
import 'package:flutter_frontend/features/auth/domain/entities/user_entity.dart';
import 'package:flutter_frontend/features/drawing/data/datasources/artwork_local_datasource.dart';
import 'package:flutter_frontend/features/drawing/data/models/stencil_model.dart';
import 'package:flutter_frontend/features/drawing/domain/entities/artwork_entity.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/waiting_room_screen.dart';
import 'package:flutter_frontend/services/dio_client.dart';
import 'package:flutter_frontend/services/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'features/drawing/data/models/stroke_model.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_frontend/features/drawing/data/models/artwork_model.dart';
import 'package:flutter_frontend/features/drawing/data/models/image_model.dart';
import 'package:flutter_frontend/features/drawing/data/repositories/artwork_repository_logic.dart';
import 'package:flutter_frontend/features/drawing/domain/repositories/artwork_repository_interface.dart';
import 'package:flutter_frontend/features/drawing/presentation/screens/prompt_screen.dart';
import 'package:flutter_frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_cubit.dart';
import 'package:flutter_frontend/features/auth/presentation/cubits/auth_state.dart';
import 'package:flutter_frontend/features/auth/presentation/screens/auth_screen.dart';
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
  Hive.registerAdapter(ImageModelAdapter());
  Hive.registerAdapter(StrokeModelAdapter());
  
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
  final authRepository = AuthRepository();
  late final Box<ArtworkModel> artworkBox;
  GoRouter? _router;

  bool _appReady = false;

  @override
  void initState() {
    super.initState();
    _appStartup();
  }

  Future<void> _appStartup() async {

    // make sure the _appStartup takes a minimum of 6 seconds to complete
    final Future<void> defaultWait = Future.delayed(const Duration(seconds: 6));

    // create the auth cubit and setup dio to use it
    await _authenticateInitialUser();

    // configure hive box
    artworkBox = Hive.box<ArtworkModel>('artwork');

    late final initialWindowLocation;
    if (authCubit.state is Authenticated) { initialWindowLocation =  '/home'; }
    else { initialWindowLocation = '/auth'; }

    // make sure user has been authenticated (or unauthenticated) and the minimum 6 seconds has been waited
    setupDioAuth(() => authCubit.accessToken, () => authCubit.refreshToken, (String accessToken) => authCubit.accessToken = accessToken); // once user is fetched, setup dio properly

    await defaultWait;
    // create the router
    setState(() {
      _router = _buildRouter(initialWindowLocation);
      _appReady = true;
    });
  }

  // authenticate the user and return a starting location based on the result
  Future<void> _authenticateInitialUser() async {
    // get access tokens from storage
    final FlutterSecureStorage storage = FlutterSecureStorage();
    String? accessToken;
    late final String? refreshToken;
    try {
      accessToken = await storage.read(key: 'access_token');
      refreshToken = await storage.read(key: 'refresh_token');
    }
    catch(error) {
      appLogger.e("startup ran into an error fetching tokens from the storage", error: error);
      refreshToken = null;
    }

    // ? temporally configure dio to bypass the auth cubit while the auth cubit is being setup
    setupDioAuth(() => accessToken, () => refreshToken, (String newAccessToken) => accessToken = newAccessToken);
    final UserEntity? user = await authRepository.fetchAuthenticatedUser();

    // create in initialize the auth cubit
    authCubit = AuthCubit(authRepository: authRepository);
    await authCubit.setInitialAuthentication(accessToken, refreshToken, user);

    // ? setup dio properly to use whats stored inside the authCubit memory
    setupDioAuth(() => authCubit.accessToken, () => authCubit.refreshToken, (String accessToken) => authCubit.accessToken = accessToken);
  }

  GoRouter _buildRouter(String initialLocation,) {
    return GoRouter(
      initialLocation: initialLocation,
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) { 
            return HomeScreen(
              artworkRepository: context.read<ArtworkRepositoryInterface>(),
            );
          }
        ),
        GoRoute(
          path: '/createPrompt',
          builder: (context, state) {
            return PromptScreen(
              artworkRepository: context.read<ArtworkRepositoryInterface>(),
            );
          }
        ),
        GoRoute(
          path: '/draw',
          builder: (context, state) { 
            final artwork = state.extra as ArtworkEntity;
            return DrawScreen(
              artwork: artwork,
              artworkRepository: context.read<ArtworkRepositoryInterface>(),
            );
          }
        ),
        GoRoute(
          path: '/auth',  
          builder: (context, state) { 
            return const AuthScreen();
          }
        ),
        GoRoute(
          path: '/waitingRoom',
          builder: (context, state) {
            final artworkPromise = state.extra as Future<ArtworkEntity>;
            return WaitingRoomScreen(
              artworkPromise: artworkPromise
            );
          }
        )
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