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
import '../../constants/api_constants.dart';

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
  bool _isTyping = false;

  // Change to your machine's LAN IP when testing on a physical device.
  static const String _backendUrl = APIConstants.chatUrl;

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
      _isTyping = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
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
          _isTyping = false;
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
          _isTyping = false;
          _messages.add(MessageData(text: "Jarvis could not process the request.", isUser: false));
        });
      }
    } catch (e) {
      debugPrint("Sending message failed: $e");
      setState(() {
        _isTyping = false;
        _messages.add(MessageData(
          text: "Unable to reach Jarvis. You can continue this chat via SMS if you are offline.",
          isUser: false,
        ));
      });
      _showOfflineSmsSuggestion(text);
    }
    _scrollToBottom();
  }

  void _showOfflineSmsSuggestion(String lastMessage) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Offline'),
        content: const Text('It seems you are offline. Would you like to send your message via SMS to continue receiving safety support?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _launchSms(lastMessage);
            },
            style: ElevatedButton.styleFrom(backgroundColor: ST.primary),
            child: const Text('Send SMS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _launchSms(String message) async {
    const textBeeNumber = "+917718937309";
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: textBeeNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );
    try {
      // Note: url_launcher would be needed here, or specialized SMS plugin.
      // For now, we use a generic method that the user can expand.
      debugPrint('Launching SMS: $smsLaunchUri');
      // await launchUrl(smsLaunchUri);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening SMS app...')),
      );
    } catch (e) {
      debugPrint('Could not launch SMS: $e');
    }
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
                  // +1 for the typing indicator slot
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show typing bubble at the end
                    if (_isTyping && index == _messages.length) {
                      return const _TypingIndicator();
                    }
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

// Animated "Jarvis is thinking…" bubble shown while awaiting backend reply.
class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late List<Animation<double>> _dots;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _dots = List.generate(3, (i) {
      final start = i * 0.2;
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(
          parent: _ac,
          curve: Interval(start, start + 0.4, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ST.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.security, color: ST.primary, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ac,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  return Transform.translate(
                    offset: Offset(0, _dots[i].value),
                    child: Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: ST.primary.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

