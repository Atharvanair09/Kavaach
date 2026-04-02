import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'main.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<bool>>(
      // Dynamically load the locally cached Auth Token and Pin Settings
      future: Future.wait([AuthService.hasToken(), AuthService.hasAppPin()]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isAuthenticated = snapshot.data?[0] ?? false;
        final hasPin = snapshot.data?[1] ?? false;

        // Bypasses Onboarding directly to PIN Screen/HomeScreen if they've logged in previously
        if (isAuthenticated) {
          return hasPin ? const PinScreen() : const HomeScreen(); 
        }

        return const OnboardingScreen1();
      },
    );
  }
}