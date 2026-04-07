import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_input_fields.dart';
import '../../auth_service.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

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
                    const FormLabel(label: 'FULL NAME'),
                    const SizedBox(height: 6),
                    FormFieldWidget(
                      controller: _nameController,
                      hint: 'Enter your name',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 20),
                    // Email
                    const FormLabel(label: 'EMAIL ADDRESS'),
                    const SizedBox(height: 6),
                    FormFieldWidget(
                      controller: _emailController,
                      hint: 'hello@safetext.io',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    // Number
                    const FormLabel(label: 'MOBILE NUMBER'),
                    const SizedBox(height: 6),
                    FormFieldWidget(
                      controller: _numberController,
                      hint: 'Enter your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 20),
                    // Password
                    const FormLabel(label: 'PASSWORD'),
                    const SizedBox(height: 6),
                    FormPasswordField(
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, color: ST.onSurfaceVariant, size: 16),
                            SizedBox(width: 6),
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
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.security, size: 72, color: ST.onSurface),
                    SizedBox(width: 16),
                    Icon(Icons.fingerprint, size: 72, color: ST.onSurface),
                    SizedBox(width: 16),
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
