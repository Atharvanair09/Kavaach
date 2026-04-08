import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants/st_style.dart';
import '../../auth_service.dart';
import '../home/home_screen.dart';
import '../fake_app/fake_app_screen.dart';
import 'login_screen.dart';
import '../../services/emergency_contact_service.dart';
import '../../services/location_service.dart';


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

          print("DEBUG: Entered Pin: $enteredPin, Saved: $savedPin, Decoy: $savedDecoyPin");

          if (savedDecoyPin != null && savedDecoyPin.isNotEmpty && enteredPin == savedDecoyPin) {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const FakeAppScreen()),
              );
            }
          } else if (savedPin != null && enteredPin == savedPin) {
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

  Future<void> _triggerSOS(BuildContext context) async {
    // Show loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text("SOS ALERTING CONTACTS..."),
          ],
        ),
        backgroundColor: ST.tertiary,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final position = await LocationService.getCurrentLocation();
      final user = await AuthService.getUser();
      
      if (position == null) throw Exception("Could not fetch location. Ensure GPS is on.");

      await EmergencyContactService.sendSOS(
        lat: position.latitude,
        lng: position.longitude,
        userId: user?['email'],
        message: "Emergency! SOS triggered from SafeText PIN screen.",
      );

      if (!mounted) return;

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
    } catch (e) {
      debugPrint("SOS error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SOS FAILED: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
                                decoration: const BoxDecoration(
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
                      SosButton(onConfirmedSOS: () => _triggerSOS(context)),
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
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline,
                                size: 12, color: ST.secondary),
                            SizedBox(width: 6),
                            Text(
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
        decoration: const BoxDecoration(
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

class SosButton extends StatefulWidget {
  final VoidCallback onConfirmedSOS;
  const SosButton({super.key, required this.onConfirmedSOS});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
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
    const steps = 100; // 5 seconds (100 * 50ms)
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
          _holding ? 'HOLD FOR 5 SECONDS…' : 'HOLD FOR EMERGENCY SOS',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: _holding ? ST.tertiary : ST.onSurfaceVariant.withOpacity(0.5),
          ),
        ),

      ],
    );
  }
}
