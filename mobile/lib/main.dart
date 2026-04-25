import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'constants/st_style.dart';
import 'auth_gate.dart';
import 'timed_check_in.dart' show initNotifications;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  await initNotifications();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const SafeTextApp());
}

class SafeTextApp extends StatelessWidget {
  const SafeTextApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeText',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: ST.primary,
          onPrimary: ST.onPrimary,
          surface: ST.surface,
          onSurface: ST.onSurface,
        ),
        fontFamily: 'Rockwell',
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}