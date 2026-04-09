import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shake/shake.dart';
import 'package:geolocator/geolocator.dart';
import 'services/emergency_contact_service.dart';
import 'package:flutter/services.dart';

class ShakeToSosScreen extends StatefulWidget {
  const ShakeToSosScreen({Key? key}) : super(key: key);

  @override
  State<ShakeToSosScreen> createState() => _ShakeToSosScreenState();
}

class _ShakeToSosScreenState extends State<ShakeToSosScreen> {
  bool _isArmed = true;
  double _sensitivity = 2.0; // 1 = Low (Needs hard shake), 2 = Medium, 3 = High (Easy)
  ShakeDetector? _detector;

  @override
  void initState() {
    super.initState();
    _initShake();
  }

  void _initShake() {
    _detector?.stopListening();
    
    // Map UI sensitivity (1,2,3) to shake threshold (Higher = Harder shake)
    // Shake threshold 20 is medium, 15 is high(easy), 30 is low(hard)
    double threshold = 20;
    if (_sensitivity == 1) threshold = 30;
    if (_sensitivity == 3) threshold = 15;

    _detector = ShakeDetector.autoStart(
      onPhoneShake: (event) {
        if (_isArmed) {
          _triggerShakeSos();
        }
      },
      shakeThresholdGravity: threshold,
    );
  }

  @override
  void dispose() {
    _detector?.stopListening();
    super.dispose();
  }

  Future<void> _triggerShakeSos() async {
    HapticFeedback.vibrate(); // Silent confirmation to user

    debugPrint("CRITICAL: SHAKE DETECTED. FIRING SOS SEQUENCE.");

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await EmergencyContactService.sendSOS(
        lat: position.latitude,
        lng: position.longitude,
        message: "SHAKE ALERT: I have triggered a Shake-to-SOS alert. Please check my location immediately.",
      );

      if (mounted) {
        _showSosDialog("Emergency contacts alerted via shake sequence.");
      }
    } catch (e) {
       if (mounted) {
        _showSosDialog("Shake trigger detected but dispatch failed. Check your connection.");
      }
    }
  }

  void _showSosDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("SOS TRIGGERED", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Shake to SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon Graphic
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.vibration, size: 60, color: Color(0xFF10B981)),
              ),
              const SizedBox(height: 32),
              
              // Status Toggle Card
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isArmed ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isArmed ? const Color(0xFF10B981) : Colors.black).withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isArmed ? "System Armed" : "System Unarmed",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _isArmed ? const Color(0xFF047857) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isArmed ? "Actively listening for shakes" : "Safe to exercise or drive",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                        CupertinoSwitch(
                          value: _isArmed,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (val) {
                            setState(() {
                              _isArmed = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    const Text(
                      "When armed, quickly shaking the device 3 times horizontally will instantly dispatch a fully silent SOS containing your location.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),

              // Sensitivity Settings
              const Text(
                "Shake Sensitivity",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Adjust how hard you need to shake the device to trigger an SOS. (High sensitivity means lighter shakes will trigger it)",
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
              ),
              const SizedBox(height: 24),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Slider(
                      value: _sensitivity,
                      min: 1,
                      max: 3,
                      divisions: 2,
                      activeColor: const Color(0xFF3B82F6),
                      inactiveColor: const Color(0xFFE2E8F0),
                      onChanged: (val) {
                        setState(() {
                          _sensitivity = val;
                          _initShake();
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Low\n(Harder)", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _sensitivity == 1 ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          Text("Medium", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _sensitivity == 2 ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                          Text("High\n(Easier)", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: _sensitivity == 3 ? const Color(0xFF3B82F6) : const Color(0xFF94A3B8), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Developer Testing Button
              ElevatedButton.icon(
                onPressed: _triggerShakeSos,
                icon: const Icon(Icons.vibration, color: Colors.white),
                label: const Text('SIMULATE 3 SHAKES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Use this button to test the SOS dispatch logic without physically shaking the device.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
