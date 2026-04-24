import 'dart:async';
import 'dart:ui';
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
      _secondsElapsed = 0;
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
      });
    });
  }

  void _resetSOS() {
    _sosTimer?.cancel();
    setState(() {
      _isSOSActive = false;
      _secondsElapsed = 0;
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

    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: _onLongPressEnd,
      onTap: () {
        if (_isSOSActive) {
          _showStopSOSConfirmation();
        } else {
          HapticFeedback.lightImpact();
        }
      },
      child: Container(
        width: outerSize,
        height: outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rounded Rectangle Progress Ring
            if (_isPressing)
              CustomPaint(
                size: const Size(size + 12, size + 12),
                painter: RoundedRectProgressPainter(
                  progress: _progress,
                  color: const Color(0xFFEF4444),
                  strokeWidth: 6,
                  borderRadius: 28,
                ),
              ),
            
            // Button Body
            ScaleTransition(
              scale: _isPressing 
                ? const AlwaysStoppedAnimation(0.95)
                : Tween<double>(begin: 1.0, end: 1.05).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: _isSOSActive ? const Color(0xFFEF4444) : const Color(0xFF0052D3),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (_isSOSActive ? const Color(0xFFEF4444) : const Color(0xFF0052D3)).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isSOSActive) ...[
                        const Icon(Icons.emergency_share, color: Colors.white, size: 20),
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
                  ),
                ),
              ),
            ),
          ],
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

class RoundedRectProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  RoundedRectProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // Draw background path
    canvas.drawRRect(rrect, paint);

    // Draw progress path
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..addRRect(rrect);

    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(0.0, pathMetrics.length * progress);
    
    canvas.drawPath(extractPath, progressPaint);
  }

  @override
  bool shouldRepaint(covariant RoundedRectProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
