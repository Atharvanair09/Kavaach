import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';

// ─── Onboarding Features ───────────────────────────────────────────────────
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      (
      Icons.notifications_off_outlined,
      'Silent Triggers',
      'Discrete signals that only you know how to activate when it matters most.'
      ),
      (
      Icons.chat_bubble_outline,
      'Anonymous Chat',
      'End-to-end encrypted messaging that leaves zero digital footprint behind.'
      ),
      (
      Icons.lock_outline,
      'Secure Vault',
      'A hidden space for your sensitive data, disguised as a common utility.'
      ),
    ];

    return Scaffold(
      backgroundColor: ST.surface,
      body: Stack(
        children: [
          // bg decorations
          Positioned(
            top: -96,
            right: -96,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: ST.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -96,
            left: -96,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: ST.secondaryFixed.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Logo
                  Image.asset(
                    'assets/safetext_logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 24),
                  // Feature card
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: ST.surfaceContainerLowest,
                        borderRadius: ST.radiusMd,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: features.map((f) {
                          return Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: ST.primaryFixed,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(f.$1,
                                    color: ST.primary, size: 22),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                f.$2,
                                style: const TextStyle(
                                  fontFamily: 'Bernard MT Condensed',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: ST.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                f.$3,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ST.onSurfaceVariant,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Footer
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignUpScreen()),
                        ),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [ST.primary, ST.primaryContainer],
                            ),
                            borderRadius: ST.radiusFull,
                            boxShadow: [
                              BoxShadow(
                                color: ST.primary.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontFamily: 'Bernard MT Condensed',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: ST.primaryFixed,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: ST.radiusFull,
                          ),
                        ),
                        child: const Text(
                          'Restore existing account',
                          style: TextStyle(
                            color: ST.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

