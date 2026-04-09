import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  
  const FakeCallScreen({
    Key? key, 
    this.callerName = "Mom",
  }) : super(key: key);

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isCallActive = false;
  int _callSeconds = 0;
  Timer? _timer;
  final _player = AudioPlayer();
  Timer? _vibrationTimer;

  @override
  void initState() {
    super.initState();
    _startRinging();
  }

  void _startRinging() {
    // Simulate phone vibration
    _vibrationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isCallActive) {
        HapticFeedback.heavyImpact();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _answerCall() async {
    setState(() {
      _isCallActive = true;
    });
    
    _vibrationTimer?.cancel();

    // In a real app, you'd play an asset. For now, we'll try to play a silent or mock conversation if available.
    // try {
    //   await _player.play(AssetSource('audio/fake_convo.mp3'));
    // } catch (e) {
    //   debugPrint("Audio play failed: $e");
    // }
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _callSeconds++;
        });
      }
    });
  }

  void _endCall() {
    _timer?.cancel();
    _vibrationTimer?.cancel();
    _player.stop();
    Navigator.of(context).pop();
  }

  String get _formattedTime {
    int minutes = _callSeconds ~/ 60;
    int seconds = _callSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // The screen relies on a dark, immersive "calling" theme
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E), // Apple-esque dark grey
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Profile Section
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3C),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: Center(
                  child: Text(
                    widget.callerName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.callerName,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isCallActive ? _formattedTime : "mobile",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white54,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(),

              // Dynamics based on call state
              if (!_isCallActive) _buildIncomingCallActions() else _buildActiveCallGrid(),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingCallActions() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                const Icon(Icons.alarm, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                const Text("Remind Me", style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
            Column(
              children: [
                const Icon(Icons.message, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                const Text("Message", style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 64),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF3B30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Decline", style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            Column(
              children: [
                GestureDetector(
                  onTap: _answerCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFF34C759),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.call, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 12),
                const Text("Accept", style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveCallGrid() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDialButton(Icons.mic_off, "mute"),
            _buildDialButton(Icons.dialpad, "keypad"),
            _buildDialButton(Icons.volume_up, "speaker", isActive: true), // Simulate speaker playing fake audio
          ],
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDialButton(Icons.add, "add call"),
            _buildDialButton(Icons.videocam_outlined, "FaceTime", isEnabled: false),
            _buildDialButton(Icons.account_circle_outlined, "contacts"),
          ],
        ),
        const SizedBox(height: 64),
        GestureDetector(
          onTap: _endCall,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFFF3B30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_end, color: Colors.white, size: 36),
          ),
        ),
      ],
    );
  }

  Widget _buildDialButton(IconData icon, String label, {bool isEnabled = true, bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : (isEnabled ? const Color(0xFF3A3A3C) : const Color(0xFF2C2C2E)),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.black : (isEnabled ? Colors.white : Colors.white24),
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white70 : Colors.white24,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
