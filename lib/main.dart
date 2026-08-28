import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/notifications/notification_service.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/auth/presentation/screens/login_screen.dart';
import 'features/ecommerce/presentation/providers/cart_provider.dart';
import 'features/ecommerce/presentation/screens/ecommerce_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Debe registrarse antes de runApp
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  await NotificationService.init();

  final prefs = await SharedPreferences.getInstance();

  final isLoggedIn = fb.FirebaseAuth.instance.currentUser != null ||
      prefs.getString('auth_current_user') != null;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: MainApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MainApp extends StatefulWidget {
  final bool isLoggedIn;

  const MainApp({super.key, required this.isLoggedIn});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Verifica si la app se abrió desde una notificación (estado Terminated)
    NotificationService.checkInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
      home: widget.isLoggedIn
          ? const EcommerceHomeScreen()
          : const LoginScreen(),
    );
  }
}