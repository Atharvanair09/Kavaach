import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import 'chat_bubbles.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class MessageData {
  final String text;
  final bool isUser;

  MessageData({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageData> _messages = [
    MessageData(
      text: "I'm Jarvis, your personal safety assistant. I'm here with you. How are you feeling about your current surroundings?", 
      isUser: false,
    )
  ];
  String _nearbySafePlacesContext = "";
  bool _sosAlreadyFired = false;

  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _fetchNearbyPlaces();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) => debugPrint('Error: $errorNotification'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
            });
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available.')),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      LatLng location = LatLng(position.latitude, position.longitude);
      
      final places = await LocationService.getNearbyPlaces(location, 'police', radius: 5000);
      if (places.isNotEmpty) {
        final topPlaces = places.take(3).map((p) => "${p['name']}").join(", ");
        _nearbySafePlacesContext = "Nearby safe places: $topPlaces";
      }
    } catch (e) {
      debugPrint("Could not fetch safe places context: $e");
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MessageData(text: text, isUser: true));
    });
    _controller.clear();
    _scrollToBottom();

    try {
      // Calling the backend which uses the ML model
      final response = await http.post(
        Uri.parse('http://192.168.1.8:5000/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text, 
          'userId': 'mobile_user',
          'safePlaces': _nearbySafePlacesContext,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        setState(() {
          _messages.add(MessageData(text: data['reply'] ?? '', isUser: false));
        });
        
        final action = data['action'] as String?;
        if (action == 'trigger_sos' && !_sosAlreadyFired) {
          setState(() => _sosAlreadyFired = true);
          _triggerSilentSos();
        } else if (action == 'share_location') {
          debugPrint('SILENT tracking: Activating location tracker covertly...');
        }
      } else {
        setState(() {
          _messages.add(MessageData(text: "Jarvis could not process the request.", isUser: false));
        });
      }
    } catch (e) {
      print("Sending message failed: $e");
      setState(() {
        _messages.add(MessageData(text: "Failed to connect to backend: Server unreachable.", isUser: false));
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Fires the silent SOS in the background.
  /// Covert by design — no loud UI, no alarming language visible on screen.
  Future<void> _triggerSilentSos() async {
    debugPrint('CRITICAL [JARVIS]: HIGH RISK DETECTED — firing silent SOS and live location dispatch.');

    // 1. Silently capture current GPS coordinates
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint(
        'CRITICAL [JARVIS]: Location captured — Lat: ' +
        position.latitude.toString() + ', Lng: ' +
        position.longitude.toString() +
        '. Dispatching to emergency contacts (stub).'
      );
      // TODO: replace with real dispatch:
      // await SmsService.sendEmergencySms(position);
      // await FirebaseFirestore.instance.collection('sos_events').add({ ... });
    } catch (e) {
      debugPrint('CRITICAL [JARVIS]: GPS capture failed for SOS — ' + e.toString());
    }

    // 2. Show a covert snackbar that looks like a normal chat notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Jarvis is with you',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Date Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'JARVIS SECURE CHAT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Messages
            Expanded(
              child: CustomPaint(
                painter: DotGridPainter(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    if (msg.isUser) {
                      return UserBubble(text: msg.text);
                    } else {
                      return SupportBubble(text: msg.text);
                    }
                  },
                ),
              ),
            ),
            // Input Area
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: ST.radiusMd,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: Colors.grey.shade400, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask Jarvis...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _listen,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.transparent,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : Colors.grey.shade400,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [ST.primary, ST.primaryContainer],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ST.outlineVariant.withOpacity(0.08)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.2;

    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawPoints(PointMode.points, [Offset(x, y)], paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
