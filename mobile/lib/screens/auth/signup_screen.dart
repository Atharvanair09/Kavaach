import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_input_fields.dart';
import '../../auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'pin_screen.dart';

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
      backgroundColor: const Color(0xFFF7FAFD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Centered Logo
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: Color(0xFF0052CC), size: 36),
                ),
              ),
              const SizedBox(height: 24),
              // Brand
              const Text(
                'SafeText',
                style: TextStyle(
                  fontFamily: 'Rockwell',
                  fontStyle: FontStyle.italic,
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0052CC),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Secure Registration',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171C1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'One-tap sign-on. No passwords to remember.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 40),
              // Safety Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    // Google Button
                    GestureDetector(
                      onTap: () async {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => const Center(
                                child: CircularProgressIndicator()),
                          );
                          final result = await AuthService.signInWithGoogle();
                          Navigator.pop(context);
                          if (result != null) {
                            final hasPin = await AuthService.hasAppPin();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => hasPin ? const PinScreen() : const HomeScreen()),
                            );
                          }
                        } catch (e) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Registration failed: $e')),
                          );
                        }
                      },
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              'https://cdn-icons-png.flaticon.com/512/3002/3002219.png',
                              height: 24,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign up with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171C1F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE6F5),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Color(0xFF455A64), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'ZERO-KNOWLEDGE AUTH ACTIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Color(0xFF455A64),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Toggle Link
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                    children: [
                      TextSpan(text: 'Already a user? '),
                      TextSpan(
                        text: 'Log In',
                        style: TextStyle(
                          color: Color(0xFF0052CC),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 64),
              // Bottom Watermark Icons
              Opacity(
                opacity: 0.1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.shield, size: 64, color: Colors.black45),
                    Icon(Icons.fingerprint, size: 60, color: Colors.black45),
                    Icon(Icons.lock, size: 60, color: Colors.black45),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

