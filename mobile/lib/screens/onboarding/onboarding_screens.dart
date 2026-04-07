import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../auth/signup_screen.dart';
import '../auth/login_screen.dart';

// ─── Screen 1: Onboarding Hero ────────────────────────────────────────────────
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuDh_Zv0VmuSrO8v6wu2PCmldbcP0n7xR4dL4fXmZ1_RF1SeDzkwUIyWckVLFILaTAEkfsBEMAHkV9eKfIo56jKxzDjcgSvKNCrgUBnK8VH4ty6F9zJW3gv4OLJxL7Oqt6_R6fZNHAZu_8aLWa4BCv5uPrUUULC06j5ncoKmZdbbA5YJHXmoi6HM8kCZtw9yGYh-2UtnBCAvuRm_qCdMzLvwGBBizwYWCc85yC4a-Jts3h4Z2VBJJgd8fdZs4imIEENCEIXBsdCpm2g',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A2B4A), Color(0xFF0F1B33)],
                ),
              ),
            ),
          ),
          // Scrim
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x66171C1F),
                  Color(0xE6171C1F),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Brand pill
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: ST.radiusFull,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12), width: 1),
                  ),
                  child: const Text(
                    'SafeText',
                    style: TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const Spacer(),
                // Headline
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Text(
                        'You are not alone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Rockwell',
                          fontStyle: FontStyle.italic,
                          fontSize: 56,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                                blurRadius: 24,
                                color: Colors.black45,
                                offset: Offset(0, 4))
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SafeText is your silent, discreet guardian.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const OnboardingScreen2()),
                        ),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: ST.primaryContainer,
                            borderRadius: ST.radiusFull,
                            boxShadow: [
                              BoxShadow(
                                color: ST.primary.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 28),
                                child: Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontFamily: 'Bernard MT Condensed',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 17,
                                    color: ST.onPrimaryContainer,
                                  ),
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: const Icon(Icons.arrow_forward,
                                    color: ST.onPrimaryContainer, size: 22),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const PageDots(current: 0, count: 3),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 2: Onboarding Split ───────────────────────────────────────────────
class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surfaceContainerLowest,
      body: Column(
        children: [
          // Top half - image
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDrfHb1wh-RYhSgiMvdh36nKgayV2zk5N9Z160t9zht7M4q3Njsu9679eBRYh1KCaYhgzM-Ck2SiRTe33q3Q2Cu-Z-_F2B63yU661nVLK5JxlsxTgQTUmwaNsxDeW1LaLZQDzndis0LMUKDOAWuGnmDEwekTVG93Oas4onUjn3UUvM3ZRDipOs05h1IOl6nm3NlSD83_FhDLKUS_RxenFz3NHQvOBCjc6lyt5f1Rj57w6F9D82EpHw5rGTUaEmT8CE5jdJknSvY3KI',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: ST.surfaceContainerHigh,
                    child: const Icon(Icons.landscape,
                        size: 80, color: ST.outline),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Colors.transparent],
                    ),
                  ),
                ),
                // Brand
                SafeArea(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: ST.radiusFull,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shield_outlined,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'SafeText',
                            style: TextStyle(
                              fontFamily: 'Bernard MT Condensed',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom card
          SizedBox(
            height: 320,
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: ST.surfaceContainerLowest,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Column(
                  children: [
                    const Text(
                      "You're in Safe Hands",
                      style: TextStyle(
                        fontFamily: 'Rockwell',
                        fontStyle: FontStyle.italic,
                        fontSize: 36,
                        fontWeight: FontWeight.w600,
                        color: ST.primary,
                        height: 1.15,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 42),
                    Text(
                      'Your journey to peace of mind starts here.',
                      style: TextStyle(
                        fontSize: 16,
                        color: ST.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    const PageDotsBlue(current: 1, count: 3),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OnboardingScreen3()),
                      ),
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ST.primary, ST.primaryContainer],
                          ),
                          borderRadius: ST.radiusMd,
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
                                fontSize: 17,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: ST.onSurfaceVariant,
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: const TextStyle(
                              color: ST.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Screen 3: Onboarding Features ───────────────────────────────────────────
class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

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
                  Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ST.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield_outlined,
                            color: ST.primary, size: 24),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'SAFETEXT',
                        style: TextStyle(
                          fontFamily: 'Haettenschweiler',
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 2.5,
                          color: ST.primary,
                        ),
                      ),
                    ],
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
                      const Text(
                        'Your Safe Place',
                        style: TextStyle(
                          fontFamily: 'Rockwell',
                          fontStyle: FontStyle.italic,
                          fontSize: 40,
                          color: ST.primary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        child: const Text(
                          'Restore existing account',
                          style: TextStyle(
                            color: ST.onSurfaceVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
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
