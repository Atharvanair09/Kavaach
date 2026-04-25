import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/emergency_contact_service.dart';
import '../services/location_service.dart';
import '../auth_service.dart';
import '../constants/st_style.dart';

class SOSFloatingButton extends StatefulWidget {
  const SOSFloatingButton({super.key});

  @override
  State<SOSFloatingButton> createState() => _SOSFloatingButtonState();
}

class _SOSFloatingButtonState extends State<SOSFloatingButton> with TickerProviderStateMixin {
  bool _isPressing = false;
  bool _isSOSActive = false;
  double _progress = 0.0;
  Timer? _pressTimer;
  Timer? _sosTimer;
  int _secondsElapsed = 0;
  int _lastInteractionTime = 0;
  bool _isMinimized = false;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _sosTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_isSOSActive) return;
    
    HapticFeedback.mediumImpact();
    setState(() {
      _isPressing = true;
      _progress = 0.0;
    });

    _pressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _progress += 0.011; // Slightly faster to hit 3s precisely (30ms * 90 = 2.7s)
      });

      if ((_progress * 100).toInt() % 10 == 0) {
        HapticFeedback.selectionClick();
      }

      if (_progress >= 1.0) {
        _triggerSOS();
      }
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isSOSActive) return;
    _cancelPress();
  }

  void _cancelPress() {
    _pressTimer?.cancel();
    setState(() {
      _isPressing = false;
      _progress = 0.0;
    });
  }

  Future<void> _triggerSOS() async {
    _pressTimer?.cancel();
    HapticFeedback.heavyImpact();
    
    setState(() {
      _isPressing = false;
      _isSOSActive = true;
      _isMinimized = false;
      _secondsElapsed = 0;
      _lastInteractionTime = 0;
    });

    _startSOSTimer();
    
    try {
      final position = await LocationService.getCurrentLocation();
      final user = await AuthService.getUser();
      
      if (position != null) {
        await EmergencyContactService.sendSOS(
          lat: position.latitude,
          lng: position.longitude,
          userId: user?['email'],
          message: "SOS! I need help immediately. My location is shared.",
        );
      }
    } catch (e) {
      debugPrint("SOS Failed: $e");
    }
  }

  void _startSOSTimer() {
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_isSOSActive && !_isMinimized && (_secondsElapsed - _lastInteractionTime) >= 5) {
          _isMinimized = true;
        }
      });
    });
  }

  void _resetSOS() {
    _sosTimer?.cancel();
    setState(() {
      _isSOSActive = false;
      _isMinimized = false;
      _secondsElapsed = 0;
      _lastInteractionTime = 0;
    });
  }

  void _showStopSOSConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resolve Emergency?'),
        content: const Text('Are you sure you want to stop the SOS alert and mark it as resolved?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              print('--- Resolving SOS ---');
              Navigator.pop(context);
              try {
                print('Requesting stopSOS for user...');
                await EmergencyContactService.stopSOS();
                print('stopSOS success, resetting UI...');
                _resetSOS();
                HapticFeedback.mediumImpact();
              } catch (e) {
                print('stopSOS error: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to stop SOS: $e')),
                  );
                }
              }
            },
            child: const Text('YES, RESOLVED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double size = 76.0;
    const double outerSize = 88.0;

    // Failsafe for Flutter Hot-Reload: actively running timers keep old closures in memory
    // This ensures that even if you're running on an old timer, the new minimization logic fires.
    if (_isSOSActive && !_isMinimized && (_secondsElapsed - _lastInteractionTime) >= 5) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isSOSActive && !_isMinimized) {
          setState(() {
            _isMinimized = true;
          });
        }
      });
    }

    return Transform.translate(
      offset: Offset(_isMinimized ? 10 : 0, 0),
      child: GestureDetector(
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onTap: () {
          if (_isSOSActive) {
            _lastInteractionTime = _secondsElapsed;
            if (_isMinimized) {
              setState(() => _isMinimized = false);
              HapticFeedback.lightImpact();
            } else {
              _showStopSOSConfirmation();
            }
          } else {
            HapticFeedback.lightImpact();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: _isMinimized ? 60.0 : outerSize,
          height: _isMinimized ? 80.0 : outerSize,
          color: Colors.transparent,
          child: Stack(
            alignment: _isMinimized ? Alignment.centerRight : Alignment.center,
            children: [
              // Button body with left-to-right fill animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isMinimized ? 12.0 : size,
                height: _isMinimized ? 80.0 : size,
                decoration: BoxDecoration(
                  color: _isSOSActive
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0052D3),
                  borderRadius: BorderRadius.circular(_isMinimized ? 6 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSOSActive
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0052D3))
                          .withOpacity(0.4),
                      blurRadius: _isMinimized ? 10 : 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isMinimized ? 6 : 24),
                  child: Stack(
                    children: [
                      // Red fill sweeping left → right while pressing
                      if (_isPressing && !_isMinimized)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.clamp(0.0, 1.0),
                            heightFactor: 1.0,
                            child: Container(
                              color: const Color(0xFF991B1B).withOpacity(0.3),
                            ),
                          ),
                        ),

                      // Icon / label on top
                      Center(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!_isMinimized) ...[
                                if (_isSOSActive) ...[
                                  const Icon(Icons.emergency_share,
                                      color: Colors.white, size: 20),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatTime(_secondsElapsed),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'SOS',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
