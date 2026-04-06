import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'state/calendar_state.dart';
import 'ui/calendar_home_screen.dart';
import 'ui/login_page.dart';
import 'ui/privacy_policy_page.dart';
import 'ui/terms_of_service_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyBCBAo0wEDyzGI8_fwYyGwW1Maex1v_lps",
          authDomain: "locus-f26d5.firebaseapp.com",
          projectId: "locus-f26d5",
          storageBucket: "locus-f26d5.firebasestorage.app",
          messagingSenderId: "598135360819",
          appId: "1:598135360819:web:7ac98809fb07673b42c246",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await Hive.initFlutter();
  final box = await Hive.openBox('calendarBox');

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => CalendarStateProvider(box)),
      ],
      child: const LocusApp(),
    ),
  );
}

class LocusApp extends StatelessWidget {
  const LocusApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          Theme.of(context).textTheme,
        ).apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
        ),
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const CalendarHomeScreen(),
        '/login': (context) => const LoginPage(),
        '/privacy': (context) => const PrivacyPolicyPage(),
        '/terms': (context) => const TermsOfServicePage(),
      },
    );
  }
}
