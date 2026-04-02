import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hasToken = await AuthService.hasToken();
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(SafeTextApp(hasToken: hasToken));
}

// ─── Design Tokens ───────────────────────────────────────────────────────────
class ST {
  static const primary = Color(0xFF0053D3);
  static const primaryContainer = Color(0xFF1A6BFF);
  static const primaryFixed = Color(0xFFDAE1FF);
  static const primaryFixedDim = Color(0xFFB3C5FF);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFFFFFEFF);
  static const onPrimaryFixed = Color(0xFF001849);
  static const onPrimaryFixedVariant = Color(0xFF003FA4);

  static const secondary = Color(0xFF575F6B);
  static const secondaryFixed = Color(0xFFDBE3F1);
  static const onSecondary = Color(0xFFFFFFFF);

  static const tertiary = Color(0xFFB8103E);
  static const tertiaryContainer = Color(0xFFDB3155);
  static const tertiaryFixed = Color(0xFFFFDADB);
  static const onTertiary = Color(0xFFFFFFFF);
  static const onTertiaryContainer = Color(0xFFFFFEFF);
  static const onTertiaryFixedVariant = Color(0xFF91002D);

  static const surface = Color(0xFFF6FAFE);
  static const surfaceBright = Color(0xFFF6FAFE);
  static const surfaceContainer = Color(0xFFEAEEF2);
  static const surfaceContainerLow = Color(0xFFF0F4F8);
  static const surfaceContainerHigh = Color(0xFFE4E9ED);
  static const surfaceContainerHighest = Color(0xFFDFE3E7);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceDim = Color(0xFFD6DADE);

  static const onSurface = Color(0xFF171C1F);
  static const onSurfaceVariant = Color(0xFF424655);
  static const onBackground = Color(0xFF171C1F);
  static const background = Color(0xFFF6FAFE);
  static const outline = Color(0xFF727687);
  static const outlineVariant = Color(0xFFC2C6D8);

  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);

  static BorderRadius get radiusSm => BorderRadius.circular(16);
  static BorderRadius get radiusMd => BorderRadius.circular(24);
  static BorderRadius get radiusLg => BorderRadius.circular(32);
  static BorderRadius get radiusFull => BorderRadius.circular(9999);
}

// ─── App Root ─────────────────────────────────────────────────────────────────
class SafeTextApp extends StatelessWidget {
  final bool hasToken;
  const SafeTextApp({super.key, required this.hasToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeText',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: ST.primary,
          onPrimary: ST.onPrimary,
          surface: ST.surface,
          onSurface: ST.onSurface,
        ),
        fontFamily: 'Rockwell',
        useMaterial3: true,
      ),
      home: hasToken ? const PinScreen() : const OnboardingScreen1(),
    );
  }
}

// ─── Shared Widgets ────────────────────────────────────────────────────────────
class STButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  const STButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 56,
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
            colors: [ST.primary, ST.primaryContainer],
          )
              : null,
          color: primary ? null : ST.surfaceContainerHigh,
          borderRadius: ST.radiusFull,
          boxShadow: primary
              ? [
            BoxShadow(
              color: ST.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: primary ? ST.onPrimary : ST.onSurface,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: primary ? ST.onPrimary : ST.onSurface, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  final int current;
  final int count;
  const PageDots({super.key, required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 28 : 7,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: ST.radiusFull,
          ),
        );
      }),
    );
  }
}

class PageDotsBlue extends StatelessWidget {
  final int current;
  final int count;
  const PageDotsBlue({super.key, required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 28 : 7,
          height: 6,
          decoration: BoxDecoration(
            color: active ? ST.primary : ST.surfaceContainerHigh,
            borderRadius: ST.radiusFull,
          ),
        );
      }),
    );
  }
}

class STBottomNav extends StatelessWidget {
  final int selected;
  final Function(int) onTap;
  const STBottomNav({super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.shield_outlined, Icons.shield, 'Status'),
      (Icons.timer_outlined, Icons.timer, 'Chat'),
      (Icons.group_outlined, Icons.group, 'Circle'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == selected;
              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEFF4FF)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? items[i].$2 : items[i].$1,
                        color: active
                            ? const Color(0xFF1D4ED8)
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$3,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: active
                              ? const Color(0xFF1D4ED8)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

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

// ─── Login Screen ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF3FA),
      body: Stack(
        children: [
          // Decorative orbs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: ST.primary.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.45,
            left: -130,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: ST.tertiary.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield, color: ST.primary, size: 22),
                          const SizedBox(width: 6),
                          const Text(
                            'Sanctuary',
                            style: TextStyle(
                              fontFamily: 'Bernard MT Condensed',
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              color: ST.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ST.surfaceContainerLow.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.info_outline, color: ST.onSurfaceVariant, size: 18),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        // Logo
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'SafeText',
                                style: TextStyle(
                                  fontFamily: 'Rockwell',
                                  fontStyle: FontStyle.italic,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w400,
                                  color: ST.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 48,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: ST.primary.withOpacity(0.2),
                                  borderRadius: ST.radiusFull,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Greeting
                        const Text(
                          'Welcome Back',
                          style: TextStyle(
                            fontFamily: 'Rockwell',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: ST.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your credentials to access your secure vault.',
                          style: TextStyle(
                            fontSize: 14,
                            color: ST.secondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Email field
                        _UnderlineField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 28),
                        // Password field
                        _UnderlinePasswordField(
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 16),
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: ST.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Login button
                        GestureDetector(
                          onTap: () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              final result = await AuthService.signInWithEmail(
                                _emailController.text.trim(),
                                _passwordController.text,
                              );
                              Navigator.pop(context); // Remove progress indicator
                              if (result != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Login failed: $e')),
                              );
                            }
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ST.primary, ST.primaryContainer],
                              ),
                              borderRadius: ST.radiusFull,
                              boxShadow: [
                                BoxShadow(
                                  color: ST.primary.withOpacity(0.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Login',
                                  style: TextStyle(
                                    fontFamily: 'Bernard MT Condensed',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Google Login
                        GestureDetector(
                          onTap: () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              final result = await AuthService.signInWithGoogle();
                              Navigator.pop(context); // Remove progress indicator
                              if (result != null) {
                                // Navigate on success
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Login failed: $e')),
                              );
                            }
                          },
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: ST.radiusMd,
                              border: Border.all(color: ST.outlineVariant.withOpacity(0.5)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rocket_launch, size: 20, color: ST.primary),
                                const SizedBox(width: 10),
                                Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ST.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Biometrics
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                          ),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: ST.surfaceContainerLowest,
                              borderRadius: ST.radiusMd,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fingerprint, color: ST.primary, size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'Or login with Biometrics',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ST.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Sign up link
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: ST.secondary),
                              children: [
                                const TextSpan(text: "Don't have an account? "),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                    ),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: ST.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                // Quick Exit footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: ST.tertiary.withOpacity(0.1),
                            borderRadius: ST.radiusFull,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.logout, color: ST.tertiary, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'QUICK EXIT',
                                style: TextStyle(
                                  fontFamily: 'Bernard MT Condensed',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  letterSpacing: 2,
                                  color: ST.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.enhanced_encryption_outlined, color: ST.outline.withOpacity(0.3), size: 16),
                          const SizedBox(width: 24),
                          Icon(Icons.verified_user_outlined, color: ST.outline.withOpacity(0.3), size: 16),
                          const SizedBox(width: 24),
                          Icon(Icons.vpn_key_outlined, color: ST.outline.withOpacity(0.3), size: 16),
                        ],
                      ),
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

// ─── Underline Input Field ─────────────────────────────────────────────────────
class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _UnderlineField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 10),
          child: Icon(icon, color: ST.outlineVariant, size: 20),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15, color: ST.onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: ST.outlineVariant.withOpacity(0.7), fontSize: 15),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ST.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.only(bottom: 10),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnderlinePasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _UnderlinePasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, right: 10),
          child: Icon(Icons.lock_outline, color: ST.outlineVariant, size: 20),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 15, color: ST.onSurface),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: ST.outlineVariant.withOpacity(0.7), fontSize: 15),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFDDE0EC), width: 1.5),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: ST.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.only(bottom: 10),
              suffixIcon: IconButton(
                onPressed: onToggle,
                icon: Icon(
                  obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: ST.outlineVariant,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sign Up Screen ────────────────────────────────────────────────────────────
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _obscurePassword = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _numberController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _numberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            children: [
              // Header
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: ST.primary.withOpacity(0.07),
                      borderRadius: ST.radiusSm,
                    ),
                    child: const Icon(Icons.shield_outlined, color: ST.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SafeText',
                    style: TextStyle(
                      fontFamily: 'Rockwell',
                      fontStyle: FontStyle.italic,
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: ST.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Your Secure Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rockwell',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: ST.onSurface,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy is our priority. No data is stored locally.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: ST.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Form card
              Container(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Full Name
                    _FormLabel(label: 'FULL NAME'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _nameController,
                      hint: 'Enter your name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    // Email
                    _FormLabel(label: 'EMAIL ADDRESS'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _emailController,
                      hint: 'hello@safetext.io',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    // Number
                    _FormLabel(label: 'MOBILE NUMBER'),
                    const SizedBox(height: 6),
                    _FormField(
                      controller: _numberController,
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    // Password
                    _FormLabel(label: 'PASSWORD'),
                    const SizedBox(height: 6),
                    _FormPasswordField(
                      controller: _passwordController,
                      obscure: _obscurePassword,
                      onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    const SizedBox(height: 28),
                        // CTA
                        GestureDetector(
                          onTap: () async {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => const Center(child: CircularProgressIndicator()),
                              );
                              final result = await AuthService.signUpWithEmail(
                                _nameController.text.trim(),
                                _emailController.text.trim(),
                                _numberController.text.trim(),
                                _passwordController.text,
                              );
                              Navigator.pop(context); // Remove progress indicator
                              if (result != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              }
                            } catch (e) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Sign up failed: $e')),
                              );
                            }
                          },
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [ST.primary, ST.primaryContainer],
                              ),
                              borderRadius: ST.radiusFull,
                              boxShadow: [
                                BoxShadow(
                                  color: ST.primary.withOpacity(0.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontFamily: 'Bernard MT Condensed',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Google Sign Up
                    GestureDetector(
                      onTap: () async {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          final result = await AuthService.signInWithGoogle();
                          Navigator.pop(context); // Remove progress indicator
                          if (result != null) {
                            // Navigate on success
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign up failed: $e')),
                          );
                        }
                      },
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: ST.radiusMd,
                          border: Border.all(color: ST.outlineVariant.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network('https://cdn-icons-png.flaticon.com/512/3002/3002219.png', width: 20, height: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Sign up with Google',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ST.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Trust badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: ST.secondaryFixed,
                          borderRadius: ST.radiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, color: ST.onSurfaceVariant, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'PRIVACY PROTOCOL ACTIVE',
                              style: TextStyle(
                                fontFamily: 'Bernard MT Condensed',
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: ST.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              // Login link
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen()),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            color: ST.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Decorative icons
              Opacity(
                opacity: 0.08,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 72, color: ST.onSurface),
                    const SizedBox(width: 16),
                    Icon(Icons.fingerprint, size: 72, color: ST.onSurface),
                    const SizedBox(width: 16),
                    Icon(Icons.enhanced_encryption, size: 72, color: ST.onSurface),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Bernard MT Condensed',
        fontWeight: FontWeight.w700,
        fontSize: 10,
        letterSpacing: 2,
        color: ST.outline,
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: ST.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: ST.outlineVariant, fontSize: 14),
          prefixIcon: Icon(icon, color: ST.outlineVariant, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _FormPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _FormPasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: ST.onSurface),
        decoration: InputDecoration(
          hintText: '••••••••••••',
          hintStyle: TextStyle(color: ST.outlineVariant, fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline, color: ST.outlineVariant, size: 20),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: ST.outlineVariant,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

// ─── Screen 4: PIN Entry ──────────────────────────────────────────────────────
class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  List<String> pin = [];

  void _onDigit(String d) {
    if (pin.length < 4) {
      setState(() => pin.add(d));
      if (pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 350), () async {
          final savedPin = await AuthService.getAppPin();
          final savedDecoyPin = await AuthService.getDecoyPin();
          final enteredPin = pin.join();

          if (savedDecoyPin != null && savedDecoyPin.isNotEmpty && enteredPin == savedDecoyPin) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FakeAppScreen()),
              );
            }
          } else if (enteredPin == savedPin) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          } else {
            if (mounted) {
              setState(() => pin.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Incorrect PIN')),
              );
            }
          }
        });
      }
    }
  }

  void _onDelete() {
    if (pin.isNotEmpty) setState(() => pin.removeLast());
  }

  void _triggerSOS(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: ST.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: ST.radiusMd),
        icon: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: ST.tertiaryFixed,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sos, color: ST.tertiary, size: 30),
        ),
        title: const Text(
          'SOS Alert Sent',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Rockwell',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: ST.onSurface,
          ),
        ),
        content: const Text(
          'Your emergency contacts and location have been shared silently. Help is on the way.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: ST.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ST.tertiary,
                shape: RoundedRectangleBorder(
                    borderRadius: ST.radiusFull),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK, I\'m Safe Now',
                style: TextStyle(
                  fontFamily: 'Bernard MT Condensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      body: Stack(
        children: [
          Positioned(
            top: -48,
            left: -24,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                color: ST.primaryFixed.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -24,
            right: -48,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: ST.secondaryFixed.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              color: ST.primary, size: 22),
                          const SizedBox(width: 6),
                          const Text(
                            'SafeText',
                            style: TextStyle(
                              fontFamily: 'Times New Roman',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: ST.primary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Quick Exit',
                          style: TextStyle(
                            color: ST.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontFamily: 'Rockwell',
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    color: ST.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter secure PIN to continue',
                  style: TextStyle(
                    fontSize: 15,
                    color: ST.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                // PIN card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: ST.surfaceContainerLowest.withOpacity(0.7),
                      borderRadius: ST.radiusMd,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Column(
                      children: [
                        // Dots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) {
                            final filled = i < pin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin:
                              const EdgeInsets.symmetric(horizontal: 10),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: filled
                                    ? ST.primary
                                    : ST.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        // Numpad
                        ...List.generate(3, (row) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: List.generate(3, (col) {
                                final n =
                                (row * 3 + col + 1).toString();
                                return _NumKey(
                                  label: n,
                                  onTap: () => _onDigit(n),
                                );
                              }),
                            ),
                          );
                        }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 64),
                            _NumKey(
                                label: '0',
                                onTap: () => _onDigit('0')),
                            GestureDetector(
                              onTap: _onDelete,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.backspace_outlined,
                                  color: ST.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Biometric + SOS side by side
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SOS Button
                      _SosButton(onConfirmedSOS: () => _triggerSOS(context)),
                      const SizedBox(width: 44),
                      // Biometric
                      Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: ST.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ST.primary.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.face,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tap for Biometric\nEntry',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: ST.secondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Privacy tip
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: ST.surfaceContainerLow,
                          borderRadius: ST.radiusFull,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline,
                                size: 12, color: ST.secondary),
                            const SizedBox(width: 6),
                            const Text(
                              'PRIVACY PROTOCOL',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: ST.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Long-press Quick Exit or flip phone to swap to Notes instantly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: ST.secondary.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(child: CircularProgressIndicator()),
                          );
                          await AuthService.signOut();
                          if (context.mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text(
                          'Forgot PIN? Sign out',
                          style: TextStyle(
                            color: ST.secondary,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NumKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Bernard MT Condensed',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ST.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── SOS Button ───────────────────────────────────────────────────────────────
class _SosButton extends StatefulWidget {
  final VoidCallback onConfirmedSOS;
  const _SosButton({required this.onConfirmedSOS});

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _holding = false;
  double _holdProgress = 0.0;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    setState(() {
      _holding = true;
      _holdProgress = 0.0;
    });
    const steps = 30;
    int count = 0;
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      count++;
      setState(() => _holdProgress = count / steps);
      if (count >= steps) {
        t.cancel();
        setState(() {
          _holding = false;
          _holdProgress = 0.0;
        });
        HapticFeedback.heavyImpact();
        widget.onConfirmedSOS();
      }
    });
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    setState(() {
      _holding = false;
      _holdProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTapDown: (_) => _startHold(),
          onTapUp: (_) => _cancelHold(),
          onTapCancel: _cancelHold,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, child) {
              final scale = _holding ? 0.95 : _pulseAnim.value;
              return Transform.scale(
                scale: scale,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing outer ring
                    if (!_holding)
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ST.tertiary.withOpacity(0.15),
                        ),
                      ),
                    // Progress ring when holding
                    if (_holding)
                      SizedBox(
                        width: 74,
                        height: 74,
                        child: CircularProgressIndicator(
                          value: _holdProgress,
                          strokeWidth: 3,
                          backgroundColor: ST.tertiaryFixed,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              ST.tertiary),
                        ),
                      ),
                    // Main button
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ST.tertiary,
                        boxShadow: [
                          BoxShadow(
                            color: ST.tertiary.withOpacity(0.45),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            fontFamily: 'Bernard MT Condensed',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _holding ? 'Hold to send SOS…' : 'Hold for Emergency SOS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _holding ? ST.tertiary : ST.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

// ─── Screen 5: Home / Sanctuary Dashboard ────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIdx = 0;

  final _screens = const [
    _HomeContent(),
    ChatScreen(),
    LocationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.background,
      body: _screens[_navIdx],
      bottomNavigationBar: STBottomNav(
        selected: _navIdx,
        onTap: (i) => setState(() => _navIdx = i),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white.withOpacity(0.85),
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.06),
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1D4ED8)),
            onPressed: () {},
          ),
          title: const Text(
            'SafeText',
            style: TextStyle(
              fontFamily: 'Bernard MT Condensed',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF1D4ED8),
              letterSpacing: -0.3,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined,
                  color: Color(0xFF1D4ED8)),
              onPressed: () {},
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Status card
              Container(
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
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: ST.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield,
                          color: ST.primary, size: 48),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Security Protocol Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                        color: ST.secondary.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Current Status: Secure',
                      style: TextStyle(
                        fontFamily: 'Rockwell',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: ST.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: ST.primaryContainer.withOpacity(0.1),
                        borderRadius: ST.radiusFull,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: ST.primary, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'ALL SYSTEMS NORMAL',
                            style: TextStyle(
                              fontFamily: 'Haettenschweiler',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: ST.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Bento grid
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.timer,
                                color: Colors.white, size: 26),
                          ),
                          const Spacer(),
                          const Text(
                            'Start Check-in',
                            style: TextStyle(
                              fontFamily: 'Bernard MT Condensed',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Timed safety alerts',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: ST.surfaceContainerHighest,
                        borderRadius: ST.radiusMd,
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ST.tertiaryContainer.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.contact_emergency_outlined,
                                color: ST.tertiary, size: 26),
                          ),
                          const Spacer(),
                          const Text(
                            'Emergency Contact',
                            style: TextStyle(
                              fontFamily: 'Bernard MT Condensed',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: ST.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Alert trusted circle',
                            style: TextStyle(
                              fontSize: 12,
                              color: ST.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Safe Tips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Safe Tips',
                    style: TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: ST.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See all',
                      style: TextStyle(
                          color: ST.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 230,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _TipCard(
                        title: 'Mindful Awareness',
                        body:
                        'Stay present and aware of your surroundings in unfamiliar areas.'),
                    const SizedBox(width: 12),
                    _TipCard(
                        title: 'Digital Shield',
                        body:
                        'Set up your private quick-alert gestures before you head out.'),
                    const SizedBox(width: 12),
                    _TipCard(
                        title: 'Circle Updates',
                        body:
                        'Keep your trusted contacts updated with your frequent routes.'),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String body;
  const _TipCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: ST.surfaceContainerLowest,
        borderRadius: ST.radiusSm,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              height: 120,
              color: ST.surfaceContainerHigh,
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDfeFU0K_nYkG3OJjZ9f8vfjdhriaT9ld7FsWPtO9ZDXv9fMre_UUWJQKcIKQGMULzGURFUzVeWUdrysWnQZvGMznVcDbvWKvsBV_ExzRimL4nUeKHZpV6LVPFi5ptclH48szvji-rU3dXlzrVD8jgh5IURrkS8l3e1AAvAqig9J1xwXPlYhQHd7ApS7Gg6_xNYTcVCiG1SJ_aMOM_mkuNxC1K41YL3iWPpMykUr2YyPbszFCApKM74Ya_Hzhs8LZd1QVYgSheE0vc',
                fit: BoxFit.cover,
                width: double.infinity,
                color: Colors.grey.withOpacity(0.4),
                colorBlendMode: BlendMode.saturation,
                errorBuilder: (_, __, ___) => const Icon(Icons.landscape,
                    size: 40, color: ST.outline),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    color: ST.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ST.onSurfaceVariant,
                    height: 1.4,
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

// ─── Screen 6: Chat ───────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _analyzing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.85),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.04),
        leading: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.location_on_outlined,
                color: Color(0xFF1D4ED8), size: 22),
          ],
        ),
        title: const Text(
          'SafeText',
          style: TextStyle(
            fontFamily: 'Bernard MT Condensed',
            fontStyle: FontStyle.italic,
            fontSize: 22,
            color: Color(0xFF1D4ED8),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: ST.surfaceContainerHigh,
              child: ClipOval(
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDh_Zv0VmuSrO8v6wu2PCmldbcP0n7xR4dL4fXmZ1_RF1SeDzkwUIyWckVLFILaTAEkfsBEMAHkV9eKfIo56jKxzDjcgSvKNCrgUBnK8VH4ty6F9zJW3gv4OLJxL7Oqt6_R6fZNHAZu_8aLWa4BCv5uPrUUULC06j5ncoKmZdbbA5YJHXmoi6HM8kCZtw9yGYh-2UtnBCAvuRm_qCdMzLvwGBBizwYWCc85yC4a-Jts3h4Z2VBJJgd8fdZs4imIEENCEIXBsdCpm2g',
                  fit: BoxFit.cover,
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person, size: 20, color: ST.secondary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Dot grid bg
                Positioned.fill(
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
                ListView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  children: [
                    // Timestamp
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: ST.surfaceContainerLow.withOpacity(0.5),
                          borderRadius: ST.radiusFull,
                        ),
                        child: const Text(
                          'Today, 10:42 PM',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Support bubble
                    _SupportBubble(
                        text:
                        "I'm here with you. How are you feeling about your current surroundings?"),
                    const SizedBox(height: 16),
                    // User bubble
                    _UserBubble(
                        text:
                        'Someone has been following me for two blocks. I\'m walking towards the main square now.'),
                    const SizedBox(height: 16),
                    // Analyzing card
                    if (_analyzing)
                      _AnalyzingCard(),
                    const SizedBox(height: 16),
                    // Support reply
                    _SupportBubble(
                        text:
                        "Understood. I've locked your GPS coordinates. Keep your phone visible. Would you like me to alert your emergency contacts or play a fake phone call audio?"),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
          // Location + quick action row
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: Row(
              children: [
                // Live location pill
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ST.primaryFixed,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ST.primaryFixedDim, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: ST.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on, color: ST.primary, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'Share Live Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ST.onPrimaryFixedVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Emergency call pill
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ST.tertiaryFixed,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ST.tertiary.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emergency_outlined, color: ST.tertiary, size: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'SOS',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ST.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  ST.surface.withOpacity(0),
                  ST.surface,
                ],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: ST.surfaceContainerLowest,
                borderRadius: ST.radiusMd,
                border:
                Border.all(color: ST.surfaceContainerHigh, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.grey),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle:
                        TextStyle(color: Colors.grey, fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_outlined,
                        color: Colors.grey),
                    onPressed: () {},
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ST.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ST.primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.send,
                        color: Colors.white, size: 20),
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

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ST.primaryFixedDim.withOpacity(0.4)
      ..strokeWidth = 1;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + 2, y + 2), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SupportBubble extends StatelessWidget {
  final String text;
  const _SupportBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              color: ST.primaryContainer, shape: BoxShape.circle),
          child:
          const Icon(Icons.shield, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: ST.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              border:
              Border.all(color: ST.surfaceContainer, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: ST.onSurface,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: ST.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Delivered',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _AnalyzingCard extends StatefulWidget {
  @override
  State<_AnalyzingCard> createState() => _AnalyzingCardState();
}

class _AnalyzingCardState extends State<_AnalyzingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: ST.surfaceContainerLowest.withOpacity(0.85),
          borderRadius: ST.radiusSm,
          border: Border.all(
              color: ST.primary.withOpacity(0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: ST.primary.withOpacity(0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _ac,
              builder: (_, __) => Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ST.primary.withOpacity(0.6 * _ac.value + 0.4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analyzing situation...',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ST.primary,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI monitoring active & surrounding audio scan in progress',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final bool fullWidth;
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: fullWidth ? 14 : 10,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: ST.radiusSm,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: fg,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Screen 7: Location / Safe Havens ────────────────────────────────────────
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locations = [
      (Icons.local_police_outlined, 'Police Station', '1.2km • Central District',
      ST.primary, ST.primaryFixed),
      (Icons.shield_outlined, 'Safe Shelter', '2.5km • North Center',
      ST.tertiary, ST.tertiaryFixed),
      (Icons.local_hospital_outlined, 'Hospital', '4.0km • General Medical',
      ST.secondary, ST.secondaryFixed),
    ];

    return Scaffold(
      backgroundColor: ST.surface,
      body: Column(
        children: [
          // Map section — no header overlay, just pins + location button
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.38,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: ST.surfaceContainer),
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDh_Zv0VmuSrO8v6wu2PCmldbcP0n7xR4dL4fXmZ1_RF1SeDzkwUIyWckVLFILaTAEkfsBEMAHkV9eKfIo56jKxzDjcgSvKNCrgUBnK8VH4ty6F9zJW3gv4OLJxL7Oqt6_R6fZNHAZu_8aLWa4BCv5uPrUUULC06j5ncoKmZdbbA5YJHXmoi6HM8kCZtw9yGYh-2UtnBCAvuRm_qCdMzLvwGBBizwYWCc85yC4a-Jts3h4Z2VBJJgd8fdZs4imIEENCEIXBsdCpm2g',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  color: ST.surfaceContainer.withOpacity(0.5),
                  colorBlendMode: BlendMode.multiply,
                  errorBuilder: (_, __, ___) => Container(
                    color: ST.surfaceContainerHigh,
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                ),
                // Map pins
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.10,
                  left: MediaQuery.of(context).size.width * 0.33,
                  child: _MapPin(color: ST.tertiary, pulsing: true),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  right: MediaQuery.of(context).size.width * 0.25,
                  child: _MapPin(color: ST.tertiary),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.08,
                  left: MediaQuery.of(context).size.width * 0.48,
                  child: _MapPin(color: ST.tertiary),
                ),
                // My location button only — no header bar
                Positioned(
                  right: 16,
                  bottom: 52,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location,
                        color: ST.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),
          // Content card — Expanded with inner Column so button is always visible
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                decoration: const BoxDecoration(
                  color: ST.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F171C1F),
                      blurRadius: 32,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Scrollable list content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Safe Havens Nearby',
                                      style: TextStyle(
                                        fontFamily: 'Rockwell',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 26,
                                        color: ST.onSurface,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Verifying secure locations\nwithin your radius',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ST.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                _ActiveScanBadge(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ...locations.map((loc) => _LocationRow(
                              icon: loc.$1,
                              title: loc.$2,
                              subtitle: loc.$3,
                              iconColor: loc.$4,
                              iconBg: loc.$5,
                            )),
                          ],
                        ),
                      ),
                    ),
                    // CTA pinned at bottom — always fully visible
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0052D4),
                                borderRadius: ST.radiusSm,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0052D4).withOpacity(0.35),
                                    blurRadius: 40,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_car,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Request Ride',
                                    style: TextStyle(
                                      fontFamily: 'Bernard MT Condensed',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'YOUR CURRENT COORDINATES ARE SHARED WITH TRUSTED CONTACTS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: ST.onSurfaceVariant.withOpacity(0.5),
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ST.outlineVariant.withOpacity(0.4)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _MapPin extends StatefulWidget {
  final Color color;
  final bool pulsing;
  const _MapPin({required this.color, this.pulsing = false});

  @override
  State<_MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<_MapPin> with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.pulsing) _ac.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.pulsing)
          AnimatedBuilder(
            animation: _ac,
            builder: (_, __) => Container(
              width: 32 * _ac.value + 8,
              height: 32 * _ac.value + 8,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2 * (1 - _ac.value)),
                shape: BoxShape.circle,
              ),
            ),
          ),
        Icon(Icons.location_on, color: widget.color, size: 32),
      ],
    );
  }
}

class _ActiveScanBadge extends StatefulWidget {
  @override
  State<_ActiveScanBadge> createState() => _ActiveScanBadgeState();
}

class _ActiveScanBadgeState extends State<_ActiveScanBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: ST.radiusFull,
        border: Border.all(color: const Color(0xFFBFD7FF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ac,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFF2563EB),
                    const Color(0xFF60A5FA), _ac.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'ACTIVE SCAN',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D4ED8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  const _LocationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: ST.radiusSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    color: ST.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ST.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Show Map',
              style: TextStyle(
                color: ST.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ─── Screen 8: Settings ───────────────────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _decoyPin = false;
  bool _shakeToAlert = true;
  bool _disguiseMode = false;
  bool _silentAlerts = true;
  bool _checkinReminders = true;
  bool _enterPin = true;

  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDecoyPinStatus();
  }

  Future<void> _loadDecoyPinStatus() async {
    final hasDecoy = await AuthService.hasDecoyPin();
    if (mounted) setState(() => _decoyPin = hasDecoy);
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white.withOpacity(0.85),
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.06),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF1D4ED8),
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Profile Card ──────────────────────────────────────────
                _buildProfileCard(),
                _buildDivider(),

                // ── Safety Section ────────────────────────────────────────
                _buildSectionHeader('Safety'),
                _buildNavRow(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFFDAE1FF),
                  iconColor: ST.primary,
                  label: 'Trusted Circle',
                  subtitle: '3 contacts added',
                  onTap: () => _showComingSoon(context),
                ),
                _buildNavRow(
                  icon: Icons.timer_outlined,
                  iconBg: const Color(0xFFEAF3DE),
                  iconColor: const Color(0xFF3B6D11),
                  label: 'Check-in Timer',
                  subtitle: 'Default: 30 min',
                  onTap: () => _showCheckinTimerSheet(context),
                ),
                _buildNavRow(
                  icon: Icons.location_on_outlined,
                  iconBg: const Color(0xFFFFDADB),
                  iconColor: ST.tertiary,
                  label: 'Safe Zones',
                  subtitle: 'Home, Work added',
                  onTap: () => _showComingSoon(context),
                ),
                _buildNavRow(
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  label: 'Enter PIN',
                  subtitle: 'Seceure your app using PIN',
                  onTap: () => _showPinScreen(context),
                ),
                _buildToggleRow(
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  label: 'Decoy PIN',
                  subtitle: 'Triggers fake app screen',
                  value: _decoyPin,
                  onChanged: (v) {
                    if (v) {
                      _showDecoyPinSetup(context);
                    } else {
                      AuthService.clearDecoyPin();
                      setState(() => _decoyPin = false);
                    }
                  },
                ),
                _buildToggleRow(
                  icon: Icons.sensors,
                  iconBg: const Color(0xFFFBEAF0),
                  iconColor: const Color(0xFF993556),
                  label: 'Shake-to-Alert',
                  subtitle: 'Shake phone to send SOS',
                  value: _shakeToAlert,
                  onChanged: (v) => setState(() => _shakeToAlert = v),
                ),
                _buildDivider(),

                // ── Privacy Section ───────────────────────────────────────
                _buildSectionHeader('Privacy'),
                _buildToggleRow(
                  icon: Icons.visibility_off_outlined,
                  iconBg: const Color(0xFFDAE1FF),
                  iconColor: ST.primary,
                  label: 'Disguise Mode',
                  subtitle: 'App looks like a notes app',
                  value: _disguiseMode,
                  onChanged: (v) => setState(() => _disguiseMode = v),
                ),
                _buildNavRow(
                  icon: Icons.auto_delete_outlined,
                  iconBg: const Color(0xFFEEEDFE),
                  iconColor: const Color(0xFF534AB7),
                  label: 'Chat Auto-Delete',
                  subtitle: 'After 24 hours',
                  onTap: () => _showAutoDeleteSheet(context),
                ),
                _buildNavRow(
                  icon: Icons.history_toggle_off_outlined,
                  iconBg: const Color(0xFFEAF3DE),
                  iconColor: const Color(0xFF3B6D11),
                  label: 'Location History',
                  subtitle: 'Stored locally only',
                  onTap: () => _showComingSoon(context),
                ),
                _buildDivider(),

                // ── Notifications Section ─────────────────────────────────
                _buildSectionHeader('Notifications'),
                _buildToggleRow(
                  icon: Icons.vibration,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  label: 'Silent Alerts',
                  subtitle: 'Vibrate only in danger mode',
                  value: _silentAlerts,
                  onChanged: (v) => setState(() => _silentAlerts = v),
                ),
                _buildToggleRow(
                  icon: Icons.notifications_active_outlined,
                  iconBg: const Color(0xFFE1F5EE),
                  iconColor: const Color(0xFF0F6E56),
                  label: 'Check-in Reminders',
                  subtitle: '15 min before expiry',
                  value: _checkinReminders,
                  onChanged: (v) => setState(() => _checkinReminders = v),
                ),
                _buildDivider(),

                // ── Account Section ───────────────────────────────────────
                _buildSectionHeader('Account'),
                _buildNavRow(
                  icon: Icons.cloud_upload_outlined,
                  iconBg: const Color(0xFFF1EFE8),
                  iconColor: const Color(0xFF5F5E5A),
                  label: 'Backup & Restore',
                  subtitle: 'Encrypted cloud backup',
                  onTap: () => _showComingSoon(context),
                ),
                _buildNavRow(
                  icon: Icons.info_outline,
                  iconBg: const Color(0xFFF1EFE8),
                  iconColor: const Color(0xFF5F5E5A),
                  label: 'About & Legal',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutSheet(context),
                ),
                _buildDivider(),

                // ── Danger Zone ───────────────────────────────────────────
                _buildDeleteRow(context),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Builder helpers ─────────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    if (_isLoading) return const SizedBox.shrink();
    if (_user == null) return const SizedBox.shrink();

    final name = _user!['name']?.toString() ?? 'Unknown User';
    final email = _user!['email']?.toString() ?? '';
    final nameParts = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    if (nameParts.isNotEmpty) {
      initials += nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '';
      if (nameParts.length > 1) {
        initials += nameParts[1].isNotEmpty ? nameParts[1][0].toUpperCase() : '';
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: ST.surfaceContainerLowest,
        borderRadius: ST.radiusSm,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ST.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Bernard MT Condensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: ST.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: ST.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ST.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: ST.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B6D11),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Protected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B6D11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: ST.onSurfaceVariant, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: ST.surfaceContainer,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Haettenschweiler',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: ST.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: ST.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ST.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ST.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: ST.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: ST.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: ST.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ST.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ST.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteRow(BuildContext context) {
    bool isLoggedIn = _user != null;
    return InkWell(
      onTap: () async {
        if (isLoggedIn) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          await AuthService.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Container(
        color: ST.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isLoggedIn ? const Color(0xFFFFDADB) : ST.primaryFixed,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              Icon(isLoggedIn ? Icons.logout : Icons.login, color: isLoggedIn ? ST.tertiary : ST.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              isLoggedIn ? 'LogOut' : 'LogIn',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isLoggedIn ? ST.tertiary : ST.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheets & dialogs ─────────────────────────────────────────────────
  void _showPinScreen(BuildContext context) {
    final pinController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter PIN',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: ST.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure your app using PIN',
              style: TextStyle(
                fontSize: 14,
                color: ST.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: 'Enter a 4-digit PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  if (pin.length == 4) {
                    await AuthService.saveAppPin(pin);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN successfully saved!')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be 4 digits.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ST.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save PIN',
                  style: TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDecoyPinSetup(BuildContext context) {
    final pinController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Decoy PIN',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: ST.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a secondary PIN to open the fake app screen.',
              style: TextStyle(
                fontSize: 14,
                color: ST.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Decoy PIN',
                hintText: 'Enter a 4-digit PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  if (pin.length == 4) {
                    await AuthService.saveDecoyPin(pin);
                    if (mounted) setState(() => _decoyPin = true);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Decoy PIN saved!')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be 4 digits.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ST.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enable Decoy Mode',
                  style: TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon'),
        backgroundColor: ST.primary,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCheckinTimerSheet(BuildContext context) {
    final options = ['15 min', '30 min', '1 hour', '2 hours', '4 hours'];
    String selected = '30 min';
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ST.outlineVariant,
                    borderRadius: ST.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check-in Timer',
                style: TextStyle(
                  fontFamily: 'Rockwell',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: ST.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alert contacts if you don\'t check in within this time.',
                style: TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ...options.map((opt) => InkWell(
                onTap: () => setS(() => selected = opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? ST.primaryFixed
                        : ST.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == opt
                          ? ST.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontFamily: 'Bernard MT Condensed',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: selected == opt
                              ? ST.primary
                              : ST.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (selected == opt)
                        const Icon(Icons.check_circle,
                            color: ST.primary, size: 18),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ST.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: ST.radiusFull),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoDeleteSheet(BuildContext context) {
    final options = ['Off', 'After 1 hour', 'After 24 hours', 'After 7 days'];
    String selected = 'After 24 hours';
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ST.outlineVariant,
                    borderRadius: ST.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chat Auto-Delete',
                style: TextStyle(
                  fontFamily: 'Rockwell',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: ST.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Messages will be permanently erased after the selected time.',
                style: TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ...options.map((opt) => InkWell(
                onTap: () => setS(() => selected = opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? ST.primaryFixed
                        : ST.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == opt
                          ? ST.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontFamily: 'Bernard MT Condensed',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: selected == opt
                              ? ST.primary
                              : ST.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (selected == opt)
                        const Icon(Icons.check_circle,
                            color: ST.primary, size: 18),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ST.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: ST.radiusFull),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ST.outlineVariant,
                borderRadius: ST.radiusFull,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ST.primaryFixed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: ST.primary, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'SafeText',
              style: TextStyle(
                fontFamily: 'Rockwell',
                fontWeight: FontWeight.w700,
                fontSize: 26,
                color: ST.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0 • Build 100',
              style: TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _aboutRow('Privacy Policy', Icons.privacy_tip_outlined),
            _aboutRow('Terms of Service', Icons.description_outlined),
            _aboutRow('Open Source Licenses', Icons.code_outlined),
            _aboutRow('Contact Support', Icons.mail_outline),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: ST.onSurfaceVariant, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Bernard MT Condensed',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ST.onSurface,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right,
              color: ST.onSurfaceVariant, size: 18),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ST.surfaceContainerLowest,
        shape: RoundedRectangleBorder(borderRadius: ST.radiusMd),
        title: const Text(
          'Delete Account?',
          style: TextStyle(
            fontFamily: 'Rockwell',
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: ST.onSurface,
          ),
        ),
        content: const Text(
          'This will permanently delete your account, all trusted contacts, messages, and settings. This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: ST.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: ST.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ST.tertiary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FakeAppScreen extends StatelessWidget {
  const FakeAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Notes', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.yellow[600],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1,
            color: Colors.yellow[50],
            child: ListTile(
              title: Text('Note ${index + 1}'),
              subtitle: const Text('This is a completely normal note. Nothing to see here.'),
              trailing: const Icon(Icons.edit_note),
            ),
          );
        },
      ),
    );
  }
}