import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes/route_generator.dart';
import 'core/routes/route_observer.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/birthday_provider.dart';
import 'providers/note_provider.dart';
import 'providers/password_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trip_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';

class NooLureApp extends StatelessWidget {
  const NooLureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => BirthdayProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => PasswordProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'NooLure',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(accentSeed: themeProvider.accentSeed),
            darkTheme: AppTheme.dark(accentSeed: themeProvider.accentSeed),
            themeMode: themeProvider.mode,
            navigatorObservers: [appRouteObserver],
            onGenerateRoute: RouteGenerator.generateRoute,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

/// Picks the initial screen based on session state: signed out → onboarding,
/// mid sign-in → the "setting up your space" transient screen, signed in →
/// Home. Login/SettingUp use `pushReplacement` internally so Back never
/// returns into the sign-in flow.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return switch (auth.status) {
          AuthStatus.unknown => const SplashScreen(),
          AuthStatus.authenticating ||
          AuthStatus.unauthenticated => const LoginScreen(),
          AuthStatus.authenticated => const HomeScreen(),
        };
      },
    );
  }
}
