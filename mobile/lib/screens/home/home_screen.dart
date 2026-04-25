import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../chat/chat_screen.dart';
import '../location/location_screen.dart';
import '../fake_app/fake_app_screen.dart';
import '../settings/settings_screen.dart';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth_service.dart';
import '../../services/location_service.dart';
import '../../services/emergency_contact_service.dart';
import '../../timed_check_in.dart';
import '../../my_circle.dart';
import '../../fake_call.dart';
import '../../services/journey_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../shake_to_sos.dart';
import '../../widgets/sos_floating_button.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

  final List<Widget> _screens = [
    const _HomeContent(),
    const ChatScreen(),
    const LocationScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: JourneyStateNotifier(),
      builder: (context, _) {
        final journey = JourneyStateNotifier();
        return Scaffold(
          extendBody: true,
          backgroundColor: ST.surface,
          body: IndexedStack(
            index: journey.navIndex,
            children: _screens,
          ),
          bottomNavigationBar: STBottomNav(
            selected: journey.navIndex,
            onTap: (i) => journey.setNavIndex(i),
          ),
          floatingActionButton: journey.navIndex == 0 
            ? const Padding(
                padding: EdgeInsets.only(bottom: 0),
                child: SOSFloatingButton(),
              )
            : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );

      }
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _userName = "Member";
  Map<String, dynamic>? _user;
  List<Map<String, String>> _trustedContacts = [];
  Timer? _sosTimer;
  double _sosProgress = 0.0;
  bool _isSosActive = false;


  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _user = user;
        _userName = user['name']?.toString().split(" ")[0] ?? "Member";
      });
      _loadTrustedContacts();
    }
  }

  Future<void> _loadTrustedContacts() async {
    if (_user == null || _user!['email'] == null) return;
    final cleanEmail = _user!['email'].toString().trim().toLowerCase();

    // 1. Immediate Load from Local Storage
    try {
      final prefs = await SharedPreferences.getInstance();
      final localKey = 'emergency_contacts_local_$cleanEmail';
      final cached = prefs.getString(localKey);
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        if (mounted) {
          setState(() {
            _trustedContacts = decoded.map((e) => Map<String, String>.from(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Local load error: $e');
    }

    // 2. Sync from Firestore
    try {
      // Check for contacts in user document first
      DocumentSnapshot? userDoc;
      final userId = _user!['_id']?.toString() ?? _user!['id']?.toString();
      if (userId != null && userId.isNotEmpty && userId.length == 24) {
        userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      }
      if (userDoc == null || !userDoc.exists) {
        userDoc = await FirebaseFirestore.instance.collection('users').doc(cleanEmail).get();
      }

      List<dynamic>? fetchedContacts;
      if (userDoc.exists && userDoc.data() is Map) {
        final data = userDoc.data() as Map<String, dynamic>;
        fetchedContacts = data['emergencyContacts'];
      }

      // If not in user doc, check the dedicated emergency_contacts collection
      if (fetchedContacts == null || fetchedContacts.isEmpty) {
        final emergencyDoc = await FirebaseFirestore.instance.collection('emergency_contacts').doc(cleanEmail).get();
        if (emergencyDoc.exists && emergencyDoc.data() is Map) {
          final data = emergencyDoc.data() as Map<String, dynamic>;
          fetchedContacts = data['contacts'];
        }
      }

      if (fetchedContacts != null) {
        final typedContacts = fetchedContacts.map((e) => Map<String, String>.from(e)).toList();
        
        // Update state if different from cached
        if (mounted) {
          setState(() {
            _trustedContacts = typedContacts;
          });
        }

        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('emergency_contacts_local_$cleanEmail', jsonEncode(typedContacts));
      }
    } catch (e) {
      debugPrint('Firestore sync error: $e');
    }
  }

  Future<void> _saveContactsToFirebase() async {
    if (_user == null || _user!['email'] == null) return;
    final cleanEmail = _user!['email'].toString().trim().toLowerCase();
    try {
      await AuthService.updateContacts(
        email: cleanEmail,
        contacts: _trustedContacts,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('emergency_contacts_local_$cleanEmail', jsonEncode(_trustedContacts));
      // Removed success snackbar per user request
    } catch (e) {
      debugPrint('Error saving contacts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error updating contacts'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addContactFromPhoneBook() async {
    final status = await Permission.contacts.status;
    if (status.isGranted) {
      await _openPicker();
    } else if (status.isDenied) {
      final result = await Permission.contacts.request();
      if (result.isGranted) {
        await _openPicker();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contacts permission denied.')));
      }
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Contacts permission is disabled. Please enable it in App Settings.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  openAppSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _openPicker() async {
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null) {
      final fullContact = await FlutterContacts.getContact(contact.id, withPhoto: true, withThumbnail: false);
      if (fullContact != null && fullContact.phones.isNotEmpty) {
        final name = fullContact.displayName;
        final phone = fullContact.phones.first.number;
        
        String? photoBase64;
        if (fullContact.photoOrThumbnail != null) {
          photoBase64 = base64Encode(fullContact.photoOrThumbnail!);
        }
        
        if (!_trustedContacts.any((c) => c['phone'] == phone)) {
          setState(() {
            final Map<String, String> newContact = {
              'name': name,
              'phone': phone,
            };
            if (photoBase64 != null) {
              newContact['photo'] = photoBase64;
            }
            _trustedContacts.add(newContact);
          });
          _saveContactsToFirebase();
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact already exists.')));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected contact has no phone number.')));
      }
    }
  }

  void _showDeleteContactDialog(Map<String, String> contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact?'),
        content: Text('Remove ${contact['name']} from your emergency circle?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _trustedContacts.remove(contact);
              });
              _saveContactsToFirebase();
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _startSOSTimer() {
    setState(() {
      _sosProgress = 0.0;
      _isSosActive = true;
    });
    
    _sosTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _sosProgress += 0.01; // 50ms * 100 = 5000ms (5 seconds)
      });
      
      if (_sosProgress >= 1.0) {
        _stopSOSTimer();
        _triggerSOS();
      }
    });
  }

  void _stopSOSTimer() {
    _sosTimer?.cancel();
    if (mounted) {
      setState(() {
        _sosProgress = 0.0;
        _isSosActive = false;
      });
    }
  }

  Future<void> _triggerSOS() async {
    // Show immediate feedback
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
            Text("FETCHING LOCATION & ALERTING CONTACTS..."),
          ],
        ),
        backgroundColor: ST.tertiary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      debugPrint("SOS: Starting sequence...");
      final position = await LocationService.getCurrentLocation();
      final user = await AuthService.getUser();
      
      if (position != null) {
        debugPrint("SOS: Location found (${position.latitude}, ${position.longitude})");
        
        // Detailed feedback for user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("LOCATION CAPTURED. SYNCING TO CLOUD..."), duration: Duration(seconds: 1)),
          );
        }

        await EmergencyContactService.sendSOS(
          lat: position.latitude,
          lng: position.longitude,
          userId: user?['email'],
          message: "EMERGENCY! I need help. My current location is being shared with you.",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("SOS BROADCAST & PERSISTENT LOG SUCCESSFUL!"),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        throw Exception("Could not retrieve GPS coordinates.");
      }
    } catch (e) {
      debugPrint("SOS CRITICAL FAILURE: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SOS ERROR: $e"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = "Good Day";
    if (hour < 12) greeting = "Good Morning";
    else if (hour < 17) greeting = "Good Afternoon";
    else greeting = "Good Evening";

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          automaticallyImplyLeading: false,
          floating: true,
          pinned: true,
          backgroundColor: ST.surface.withOpacity(0.8),
          elevation: 0,
          scrolledUnderElevation: 0,
          expandedHeight: 80,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ST.onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 0.5,
                    )),
                Text(
                  _userName,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: ST.onSurface,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            const STProfileButton(),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Security Protocol Status Card
               ListenableBuilder(
                listenable: JourneyStateNotifier(),
                builder: (context, child) {
                  final journey = JourneyStateNotifier();
                  if (journey.isActive && journey.isShared) {
                    return const _JourneyCard();
                  }
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF2FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user,
                            color: Color(0xFF0052D3),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'SECURITY PROTOCOL',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current Status:',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Secure',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your connection is encrypted and\nyour circle is active.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              ),
              const SizedBox(height: 20),

              // 2. Start Check-in Card (Blue)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TimedCheckInScreen())),
                child: Container(
                  width: double.infinity,
                  height: 170,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0052D3),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0052D3).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: Icon(
                          Icons.location_on,
                          size: 160,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.near_me, color: Colors.white, size: 22),
                            ),
                            const Spacer(),
                            Text(
                              'Start Check-in',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Automated safety verification',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. Grid Row (Emergency Circle & Safe Routes)
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.group_add,
                      label: 'Emergency\nCircle',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCircleScreen())),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.map,
                      label: 'Safe Routes',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LocationScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 4. Safety Pulse Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Safety Pulse',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0052D3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Live Updates',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0052D3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _buildPulseCard(
                      badge: 'OPTIMAL ROUTE',
                      message: 'Safe Path Found: Broadway St. currently has maximum lighting.',
                      time: '2 mins away',
                      color: const Color(0xFF0052D3),
                      icon: Icons.wb_sunny_rounded,
                    ),
                    const SizedBox(width: 16),
                    _buildPulsePeekCard(),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildCircleActivitySection(),

              const SizedBox(height: 120),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: const Color(0xFFB91C1C), size: 26),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _powerAction({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: color.withOpacity(0.15)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: ST.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThreatAlertFeed() {
    return 
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Deep terminal dark
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _alertItem(Icons.warning_amber_rounded, "Harassment reported 0.3km away · 12 min ago", const Color(0xFFFBBF24)),
          const SizedBox(height: 12),
          _alertItem(Icons.circle, "Unsafe zone flagged near Dharavi · 1hr ago", const Color(0xFFEF4444)),
          const SizedBox(height: 12),
          _alertItem(Icons.check_box_rounded, "No incidents near you in last 2 hours", const Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _alertItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniStatus(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: ST.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildCircleActivitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Circle Activity',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._trustedContacts.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => _showDeleteContactDialog(c),
                      child: _circleMemberAvatar(
                        (c['name'] ?? '').split(' ').first,
                        c['photo'],
                        true,
                      ),
                    ),
                  );
                }),
                GestureDetector(
                  onTap: _addContactFromPhoneBook,
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.person_add_outlined, color: Color(0xFF64748B), size: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          _activityItem(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF0052D3),
            bgColor: const Color(0xFFEBF2FF),
            title: 'You checked-in successfully',
            subtitle: '12:30 PM • Home Office',
          ),
          const SizedBox(height: 1),
          _activityItem(
            avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
            title: 'Sarah arrived at destination',
            subtitle: '11:55 AM • Downtown Campus',
          ),
          const SizedBox(height: 1),
          _activityItem(
            icon: Icons.location_on_outlined,
            iconColor: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEBF2FF),
            title: 'Location shared with Circle',
            subtitle: '10:15 AM • Commute Started',
          ),
          
          const SizedBox(height: 12),
          
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                'View All Activity',
                style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF002766),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleMemberAvatar(String name, String? base64Photo, bool active) {
    ImageProvider avatarImage;
    if (base64Photo != null && base64Photo.isNotEmpty) {
      avatarImage = MemoryImage(base64Decode(base64Photo));
    } else {
      avatarImage = NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=E2E8F0');
    }

    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE2E8F0),
              backgroundImage: avatarImage,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _activityItem({
    IconData? icon, 
    Color? iconColor, 
    Color? bgColor, 
    String? avatarUrl, 
    required String title, 
    required String subtitle
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0052D3), // Deep Blue Background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0052D3).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (avatarUrl != null)
             CircleAvatar(
               radius: 18,
               backgroundColor: Colors.white.withOpacity(0.2),
               backgroundImage: NetworkImage(avatarUrl),
             )
          else
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF0052D3), size: 18),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 52, top: 16, bottom: 16),
      height: 1,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildPulseCard({
    required String badge,
    required String message,
    required String time,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0, // In image it's roughly top-right
            child: Icon(
              icon,
              size: 40,
              color: Colors.white.withOpacity(0.12),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.near_me, color: Colors.white, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPulsePeekCard() {
    return Container(
      width: 140, // Increased peek width
      height: 180, // Match main card height approx
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group, color: Color(0xFF0052D3), size: 28),
          ),
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF0052D3),
              borderRadius: BorderRadius.circular(2),
            ),
          )
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Coming Soon"),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bg;
  const _StatusPill({required this.icon, required this.text, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? subtitle;
  final Widget? subtitleWidget;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            subtitleWidget ??
                Text(subtitle ?? '',
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

void _showComingSoon(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Coming soon'),
      backgroundColor: ST.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 1),
    ),
  );
}

Widget _buildAvatars() {
  return SizedBox(
    width: 44,
    height: 18,
    child: Stack(
      children: [
        Positioned(
          left: 0,
          child: _avatarCirc('A', const Color(0xFFE0E7FF), const Color(0xFF4338CA)),
        ),
        Positioned(
          left: 12,
          child: _avatarCirc('R', const Color(0xFFFCE7F3), const Color(0xFFBE185D)),
        ),
        Positioned(
          left: 24,
          child: _avatarCirc('S', const Color(0xFFE0E7FF), const Color(0xFF4338CA)),
        ),
      ],
    ),
  );
}

Widget _avatarCirc(String letter, Color bg, Color color) {
  return Container(
    width: 18,
    height: 18,
    decoration: BoxDecoration(
      color: bg,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 1.5),
    ),
    child: Center(
      child: Text(letter,
          style: TextStyle(
              color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    ),
  );
}

class _JourneyCard extends StatefulWidget {
  const _JourneyCard({Key? key}) : super(key: key);

  @override
  State<_JourneyCard> createState() => _JourneyCardState();
}

class _JourneyCardState extends State<_JourneyCard> {
  bool _isExpanded = false;
  GoogleMapController? _miniMapController;

  @override
  Widget build(BuildContext context) {
    final journey = JourneyStateNotifier();

    return AnimatedBuilder(
      animation: journey,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              children: [
                // 1. Full Bleed Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: journey.currentPosition ?? const LatLng(28.6139, 77.2090),
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _miniMapController = controller,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<OneSequenceGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  mapToolbarEnabled: false,
                  polylines: {
                    if (journey.points.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('mini_route'),
                        points: journey.points,
                        color: ST.primary,
                        width: 5,
                        startCap: Cap.roundCap,
                        endCap: Cap.roundCap,
                        jointType: JointType.round,
                      ),
                  },
                  markers: {
                    if (journey.destinationLocation != null)
                      Marker(
                        markerId: const MarkerId('dest'),
                        position: journey.destinationLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                      ),
                    if (!journey.isSelf && journey.currentPosition != null)
                      Marker(
                        markerId: const MarkerId('member_pos'),
                        position: journey.currentPosition!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        infoWindow: InfoWindow(title: journey.userName ?? 'Circle Member'),
                      ),
                  },
                ),

                // 2. Subtle Gradient Overlay for Text Readability
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.1),
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 3. Status Labels (Top Left)
                Positioned(
                  top: 20,
                  left: 20,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          'ETA: ${journey.minutesRemaining} MIN',
                          style: GoogleFonts.plusJakartaSans(
                            color: ST.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          'LEFT: ${journey.distanceRemaining.toStringAsFixed(1)} KM',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF166534),
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Live Tracking Text (Bottom Left)
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        journey.isSelf ? 'Live Tracking' : 'Tracking ${journey.userName ?? "User"}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        journey.destinationName ?? 'Safe Journey Active',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(_JourneyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pos = JourneyStateNotifier().currentPosition;
    if (pos != null) {
      _miniMapController?.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }
}
