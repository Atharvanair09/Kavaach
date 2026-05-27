import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../../widgets/custom_menu_overlay.dart';
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
  final String? translation;
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
    this.translation,
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
  String? _userName;
  String _nearbySafePlacesContext = "";
  List<Map<String, dynamic>> _nearbySafePlacesList = [];
  String? _sessionId;
  bool _sosAlreadyFired = false;
  bool _isTyping = false;

  // Change to your machine's LAN IP when testing on a physical device.
  static const String _backendUrl = APIConstants.chatUrl;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  double _soundLevel = 0.0;

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
        final fullName = user?['name']?.toString() ?? '';
        _userName = fullName.isNotEmpty ? fullName.split(' ')[0] : 'there';
      });
      _fetchInitialHistory();
    }
  }

  Future<void> _fetchInitialHistory() async {
    if (_currentUserId == null) return;
    try {
      final history = await ApiService.getChatHistory(_currentUserId!);
      if (mounted && history.isNotEmpty) {
        setState(() {
          _messages.clear();
          for (var item in history.reversed) {
            final msg = item as Map<String, dynamic>;
            final userText = msg['message'] as String? ?? '';
            final botText = msg['reply'] as String? ?? '';
            final time = DateTime.tryParse(msg['time']?.toString() ?? '') ?? DateTime.now();

            if (userText.isNotEmpty) {
              _messages.add(MessageData(
                id: "hist_u_${_messages.length}",
                userId: _currentUserId!,
                text: userText,
                translation: msg['messageEng'],
                isUser: true,
                time: time,
              ));
            }
            if (botText.isNotEmpty) {
              _messages.add(MessageData(
                id: "hist_b_${_messages.length}",
                userId: _currentUserId!,
                text: botText,
                translation: msg['replyEng'],
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
    } catch (e) {
      debugPrint("Error fetching history: $e");
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
              _soundLevel = 0.0;
            });
          }
        },
        onError: (errorNotification) {
          debugPrint('Error: $errorNotification');
          setState(() {
            _isListening = false;
            _soundLevel = 0.0;
          });
        }
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
          onSoundLevelChange: (level) {
            setState(() => _soundLevel = level);
          }
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Speech recognition is not available.')),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
      });
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
          translation: data['replyTranslation'],
          isUser: false,
          category: data['category'] ?? 'general',
          risk: data['risk'] ?? 'low',
          ui: data['ui'] ?? 'green',
          action: data['action'] ?? 'none',
        );

        if (data['userTranslation'] != null) {
          setState(() {
            final lastUserMsgIndex = _messages.lastIndexWhere((m) => m.isUser);
            if (lastUserMsgIndex != -1) {
              final old = _messages[lastUserMsgIndex];
              _messages[lastUserMsgIndex] = MessageData(
                id: old.id,
                userId: old.userId,
                text: old.text,
                translation: data['userTranslation'],
                isUser: true,
                time: old.time,
              );
            }
          });
        }

        setState(() {
          _messages.add(botMsg);
          _isTyping = false;
        });

        final action = data['action'] as String?;
        if (action == 'trigger_sos' && !_sosAlreadyFired) {
          setState(() => _sosAlreadyFired = true);
          _triggerSilentSos();
        } else if (action == 'notify_following') {
          _triggerFollowingAlert();
        } else if (action == 'collect_evidence' || botMsg.category == 'harassment') {
          _triggerUncomfortableAlert();
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
      debugPrint('Launching SMS: $smsLaunchUri');
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

  Future<void> _triggerSilentSos() async {
    debugPrint('CRITICAL [JARVIS]: HIGH RISK DETECTED — firing silent SOS and live location dispatch.');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('CRITICAL [JARVIS]: GPS capture failed for SOS — ' + e.toString());
    }

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

  Future<void> _triggerFollowingAlert() async {
    debugPrint('CRITICAL [JARVIS]: FOLLOWING DETECTED — notifying admin dashboard.');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await http.post(
        Uri.parse(APIConstants.sosUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUserId,
          'type': 'following',
          'message': 'User is being followed! High priority alert.',
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          }
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Jarvis has alerted the control room',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEAB308),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('CRITICAL [JARVIS]: Following notification failed — ' + e.toString());
    }
  }

  Future<void> _triggerUncomfortableAlert() async {
    debugPrint('CRITICAL [JARVIS]: UNCOMFORTABLE SCENARIO — notifying admin dashboard.');
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await http.post(
        Uri.parse(APIConstants.sosUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': _currentUserId,
          'type': 'uncomfortable',
          'message': 'User is feeling uncomfortable in a cab. Harassment scenario detected.',
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          }
        }),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.privacy_tip_outlined, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Jarvis has discreetly alerted the control room',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFF97316),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('CRITICAL [JARVIS]: Uncomfortable notification failed — ' + e.toString());
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
                      
                      List<Map<String, dynamic>> messages;
                      DateTime time;

                      if (data.containsKey('messages')) {
                        final rawList = data['messages'] as List? ?? [];
                        messages = rawList.cast<Map<String, dynamic>>();
                        time = DateTime.tryParse(data['time']?.toString() ?? '') ?? DateTime.now();
                      } else {
                        messages = [data];
                        time = DateTime.tryParse(data['time']?.toString() ?? '') ?? DateTime.now();
                      }

                      if (messages.isEmpty) return const SizedBox.shrink();
                      
                      messages.sort((a,b) => (DateTime.tryParse(b['time']?.toString() ?? '') ?? DateTime.now()).compareTo(DateTime.tryParse(a['time']?.toString() ?? '') ?? DateTime.now()));
                      
                      final lastMsg = messages.first;
                      
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _messages.clear();
                            _sessionId = data['sessionId'] ?? "session_${DateTime.now().millisecondsSinceEpoch}";
                            
                            final chronological = messages.reversed.toList();
                            for (var m in chronological) {
                               _messages.add(MessageData(
                                 id: m['id'] ?? "u_${m['time']}",
                                 userId: _currentUserId!,
                                 text: m['message'] ?? "",
                                 translation: m['messageEng'],
                                 isUser: true,
                                 time: DateTime.tryParse(m['time']?.toString() ?? '') ?? DateTime.now(),
                               ));
                               _messages.add(MessageData(
                                 id: "${m['id']}_bot",
                                 userId: "jarvis",
                                 text: m['reply'] ?? "",
                                 translation: m['replyEng'],
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

  Widget _buildInitialGreeting() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w500,
                fontFamily: 'Rockwell',
              ),
              children: [
                const TextSpan(
                  text: 'Hello, ',
                  style: TextStyle(color: Color(0xFF2B2C2E)),
                ),
                TextSpan(
                  text: _userName ?? 'there',
                  style: const TextStyle(color: Color(0xFF4285F4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'what would you like to talk about?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF2B2C2E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: ST.onSurface),
                    onPressed: _showHistoryDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu_open_rounded, color: ST.onSurface, size: 30),
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const CustomMenuOverlay(),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(0.0, -1.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOutCubic;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Messages
            Expanded(
              child: CustomPaint(
                painter: DotGridPainter(),
                child: _messages.isEmpty && !_isTyping
                    ? _buildInitialGreeting()
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _messages.length) return const _TypingIndicator();
                    final m = _messages[index];
                    
                    if (m.isUser) return UserBubble(text: m.text, translation: m.translation, time: m.time);
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SupportBubble(
                          text: m.text, 
                          translation: m.translation, 
                          time: m.time,
                          safePlaces: (m.action == 'show_safe_places' || 
                                       m.action == 'trigger_sos' || 
                                       m.action == 'notify_following' || 
                                       m.category == 'stalking' || 
                                       m.category == 'abuse' || 
                                       m.category == 'danger') ? _nearbySafePlacesList : null,
                          showEvidenceActions: (m.category == 'stalking' || 
                                               m.category == 'abuse' || 
                                               m.category == 'harassment' || 
                                               m.action == 'collect_evidence'),
                          sessionId: _sessionId,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Gemini-style Input Area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F9),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'Ask Jarvis',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.mic_none, color: Colors.grey.shade700),
                            onPressed: _listen,
                          ),
                          IconButton(
                            icon: Icon(Icons.camera_alt_outlined, color: Colors.grey.shade700),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F4F9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.auto_awesome, color: Color(0xFF4285F4), size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
          if (_isListening) _buildListeningOverlay(),
        ],
      ),
    );
  }

  Widget _buildListeningOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _listen,
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                _buildAudioVisualizer(),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _controller.text.isEmpty ? "Listening..." : _controller.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "Tap anywhere to stop",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioVisualizer() {
    final normalized = (_soundLevel > 0 ? _soundLevel : 0.0) / 10.0;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: normalized),
      duration: const Duration(milliseconds: 100),
      builder: (context, value, child) {
        final size = 180.0 + (value * 25.0);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFD946EF).withOpacity(0.6),
                const Color(0xFFD946EF).withOpacity(0.0),
              ],
              stops: const [0.4, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD946EF).withOpacity(0.5 + (value * 0.08).clamp(0.0, 0.5)),
                blurRadius: 50 + (value * 15),
                spreadRadius: 15 + (value * 8),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: size * 0.5,
              height: size * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15 + (value * 0.03).clamp(0.0, 0.4)),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD946EF).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
        );
      },
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
