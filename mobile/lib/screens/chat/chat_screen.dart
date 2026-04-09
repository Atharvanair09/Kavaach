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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../constants/api_constants.dart';
import '../../auth_service.dart';
import '../../services/journey_service.dart';

class MessageData {
  final String id;
  final String userId;
  final String text;
  final bool isUser;
  final String category;
  final String risk;
  final String ui;
  final String action;
  final DateTime time;

  MessageData({
    required this.id,
    required this.userId,
    required this.text, 
    required this.isUser,
    this.category = "general",
    this.risk = "low",
    this.ui = "green",
    this.action = "none",
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageData> _messages = [];
  String? _currentUserId;
  String _nearbySafePlacesContext = "";
  List<Map<String, dynamic>> _nearbySafePlacesList = [];
  String? _sessionId;
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
    _loadUser();
    _fetchNearbyPlaces();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _currentUserId = user?['id'] ?? user?['email'] ?? 'anonymous_user';
      });
    }
  }

  Future<void> _fetchInitialHistory() async {
    if (_currentUserId == null) return;
    final history = await ApiService.getChatHistory(_currentUserId!);
    if (mounted && history.isNotEmpty) {
      setState(() {
        _messages.clear();
        for (var item in history.reversed) { // Backend returns desc, we want asc for long list
          final msg = item as Map<String, dynamic>;
          final userText = msg['message'] as String? ?? '';
          final botText = msg['reply'] as String? ?? '';
          final time = DateTime.tryParse(msg['time']?.toString() ?? '') ?? DateTime.now();

          if (userText.isNotEmpty) {
            _messages.add(MessageData(
              id: "hist_u_${_messages.length}",
              userId: _currentUserId!,
              text: userText,
              isUser: true,
              time: time,
            ));
          }
          if (botText.isNotEmpty) {
            _messages.add(MessageData(
              id: "hist_b_${_messages.length}",
              userId: _currentUserId!,
              text: botText,
              isUser: false,
              category: msg['category'] ?? 'general',
              risk: msg['risk'] ?? 'low',
              ui: msg['ui'] ?? 'green',
              action: msg['action'] ?? 'none',
              time: time,
            ));
          }
        }
      });
      _scrollToBottom();
    }
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
        if (mounted) {
          setState(() {
            _nearbySafePlacesList = places.take(3).toList();
            final names = _nearbySafePlacesList.map((p) => p['name']).join(", ");
            _nearbySafePlacesContext = "USER LOCATION: Lat ${position.latitude}, Lng ${position.longitude}. NEARBY SAFE PLACES: $names";
          });
        }
      }
    } catch (e) {
      debugPrint("Could not fetch safe places context: $e");
    }
  }
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    final userMsg = MessageData(
      id: "u_${DateTime.now().millisecondsSinceEpoch}",
      userId: _currentUserId!,
      text: text,
      isUser: true,
    );

    setState(() {
      _messages.add(userMsg);
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
          'userId': _currentUserId,
          'sessionId': _sessionId,
          'safePlaces': _nearbySafePlacesContext,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // DEV DEBUG POPUP
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("DEV: RISK LEVEL = ${data['risk']?.toString().toUpperCase()}"),
              duration: const Duration(milliseconds: 1500),
              behavior: SnackBarBehavior.floating,
              backgroundColor: ST.onSurface,
            ),
          );
        }

        
        final botMsg = MessageData(
          id: "b_${DateTime.now().millisecondsSinceEpoch}",
          userId: _currentUserId!,
          text: data['reply'] ?? '',
          isUser: false,
          category: data['category'] ?? 'general',
          risk: data['risk'] ?? 'low',
          ui: data['ui'] ?? 'green',
          action: data['action'] ?? 'none',
        );

        setState(() {
          _messages.add(botMsg);
          _isTyping = false;
        });

        final action = data['action'] as String?;
        if (action == 'trigger_sos' && !_sosAlreadyFired) {
          setState(() => _sosAlreadyFired = true);
          _triggerSilentSos();
        }
      } else {
        setState(() => _isTyping = false);
      }
    } catch (e) {
      debugPrint("Sending message failed: $e");
      setState(() => _isTyping = false);
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

  void _showHistoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Safety Archives',
              style: TextStyle(fontFamily: 'Rockwell', fontSize: 22, fontWeight: FontWeight.w900, color: ST.onSurface),
            ),
            const SizedBox(height: 8),
            Text('Review your past safety interactions', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _messages.clear();
                    _sessionId = "session_${DateTime.now().millisecondsSinceEpoch}";
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: ST.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: ST.primary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text("START FRESH SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: ApiService.getChatHistory(_currentUserId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                    ));
                  }

                  final sessions = snapshot.data ?? [];
                  if (sessions.isEmpty) return const Center(child: Text('No history found'));

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final data = sessions[index] as Map<String, dynamic>;
                      
                      // Hybrid Support: Handle both new 'Session' objects and old 'Message' objects
                      List<Map<String, dynamic>> messages;
                      DateTime time;

                      if (data.containsKey('messages')) {
                        // New Session Format
                        final rawList = data['messages'] as List? ?? [];
                        messages = rawList.cast<Map<String, dynamic>>();
                        time = DateTime.tryParse(data['time']?.toString() ?? '') ?? DateTime.now();
                      } else {
                        // Legacy Message Format
                        messages = [data];
                        time = DateTime.tryParse(data['time']?.toString() ?? '') ?? DateTime.now();
                      }

                      if (messages.isEmpty) return const SizedBox.shrink();
                      
                      // Sort messages within session
                      messages.sort((a,b) => (DateTime.tryParse(b['time']?.toString() ?? '') ?? DateTime.now()).compareTo(DateTime.tryParse(a['time']?.toString() ?? '') ?? DateTime.now()));
                      
                      final lastMsg = messages.first;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _messages.clear();
                            _sessionId = data['sessionId'] ?? "session_${DateTime.now().millisecondsSinceEpoch}";
                            
                            // Re-add messages in chronological order (backend returns them sorted, but we want to display properly)
                            final chronological = messages.reversed.toList();
                            for (var m in chronological) {
                               // Add user part
                               _messages.add(MessageData(
                                 id: m['id'] ?? "u_${m['time']}",
                                 userId: _currentUserId!,
                                 text: m['message'] ?? "",
                                 isUser: true,
                                 time: DateTime.tryParse(m['time']?.toString() ?? '') ?? DateTime.now(),
                               ));
                               // Add bot part
                               _messages.add(MessageData(
                                 id: "${m['id']}_bot",
                                 userId: "jarvis",
                                 text: m['reply'] ?? "",
                                 isUser: false,
                                 action: m['action'] ?? 'none',
                                 time: (DateTime.tryParse(m['time']?.toString() ?? '') ?? DateTime.now()).add(const Duration(seconds: 1)),
                               ));
                            }
                          });
                          Navigator.pop(context);
                          _scrollToBottom();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade100),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("CONVERSATION SESSION", 
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400, letterSpacing: 1)),
                                  Text("${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}", 
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ST.primary.withOpacity(0.6))),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(lastMsg['message'] ?? '...', 
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: ST.onSurface)),
                              const SizedBox(height: 4),
                              Text(lastMsg['reply'] ?? '', 
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
                              if (messages.length > 1) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: ST.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                  child: Text("+ ${messages.length - 1} more interactions in this session", 
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: ST.primary)),
                                ),
                              ]
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'JARVIS',
                        style: TextStyle(
                          fontFamily: 'Rockwell',
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: ST.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'SECURE SAFETY ASSISTANT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showHistoryDialog,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ST.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.history_rounded, color: ST.primary, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 32, thickness: 0.5, indent: 24, endIndent: 24),
            // Messages
            Expanded(
              child: CustomPaint(
                painter: DotGridPainter(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0) + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const SupportBubble(
                        text: "I'm Jarvis, your personal safety assistant. I'm here with you. How are you feeling about your current surroundings?",
                      );
                    }
                    
                    final msgIndex = index - 1;
                    if (msgIndex < _messages.length) {
                      final m = _messages[msgIndex];
                      if (m.isUser) return UserBubble(text: m.text);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SupportBubble(text: m.text),
                          if (m.action == 'show_safe_places' && _nearbySafePlacesList.isNotEmpty)
                            _SafePlacesCard(places: _nearbySafePlacesList),
                        ],
                      );
                    }
                    
                    return const _TypingIndicator();
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

class _SafePlacesCard extends StatelessWidget {
  final List<Map<String, dynamic>> places;

  const _SafePlacesCard({required this.places});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 40, bottom: 24, right: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: ST.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: ST.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.map_outlined, color: ST.primary, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'CLOSEST SAFE HAVENS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ST.primary, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...places.map((place) => _buildPlaceItem(context, place)).toList(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Text(
              'Jarvis has identified these locations as the nearest reachable safe points. Tap any to start navigation.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.4, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem(BuildContext context, Map<String, dynamic> place) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final loc = place['location'] as LatLng;
          final name = place['name'] ?? 'Safe Haven';
          JourneyStateNotifier().setPendingRoute(loc, name);
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name'] ?? 'Safe Location',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ST.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Police Station • Approx. 600m away',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const Icon(Icons.navigation_rounded, color: ST.primary, size: 18),
          ],
        ),
      ),
    );
  }
}


