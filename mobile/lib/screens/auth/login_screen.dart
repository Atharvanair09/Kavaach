import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_input_fields.dart';
import '../../auth_service.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

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
                        UnderlineField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 28),
                        // Password field
                        UnderlinePasswordField(
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
