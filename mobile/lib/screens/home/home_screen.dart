import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../chat/chat_screen.dart';
import '../location/location_screen.dart';
import '../fake_app/fake_app_screen.dart';
import '../settings/settings_screen.dart';
import 'dart:async';
import '../../auth_service.dart';
import '../../services/location_service.dart';
import '../../services/emergency_contact_service.dart';
import '../../timed_check_in.dart';
import '../../my_circle.dart';
import '../../fake_call.dart';
import '../../shake_to_sos.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/journey_service.dart';


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
        _userName = user['name']?.toString().split(" ")[0] ?? "Member";
      });
    }
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
      final position = await LocationService.getCurrentLocation();
      final user = await AuthService.getUser();
      
      if (position != null) {
        await EmergencyContactService.sendSOS(
          lat: position.latitude,
          lng: position.longitude,
          userId: user?['email'],
          message: "EMERGENCY! I need help. My current location is being shared with you.",
        );


        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("SOS ALERTS SENT SUCCESSFULLY!"),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("SOS FAILED: $e"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          expandedHeight: 100,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ST.onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 0.5,
                    )),
                Text(
                  _userName,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([      
              // 1. Safety Score Hero Card
              Container(
                child: Column(
                  children: [
                    // const SizedBox(height: 24),
                    // _buildThreatAlertFeed(),
                    // const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. NEW: Quick Command Power Bar
              const Text('QUICK ACTIONS',
                  style: TextStyle(
                      color: ST.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 8),
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    _powerAction(
                        icon: Icons.shield_outlined,
                        label: "Check-in",
                        color: const Color(0xFF3B82F6),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TimedCheckInScreen()))),
                    _powerAction(
                        icon: Icons.people_alt_outlined,
                        label: "My Circle",
                        color: const Color(0xFFD946EF),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MyCircleScreen()))),
                    _powerAction(
                        icon: Icons.phone_in_talk_outlined,
                        label: "Fake Call",
                        color: const Color(0xFFF97316),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FakeCallScreen()))),
                    _powerAction(
                        icon: Icons.electric_bolt_outlined,
                        label: "Shake SOS",
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ShakeToSosScreen()))),
                    _powerAction(
                        icon: Icons.map_outlined,
                        label: "Havens",
                        color: const Color(0xFF6366F1),
                        onTap: () => _showComingSoon(context)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. SOS Critical Action
              GestureDetector(
                onLongPressStart: (_) => _startSOSTimer(),
                onLongPressEnd: (_) => _stopSOSTimer(),
                child: AnimatedScale(
                  scale: _isSosActive ? 0.96 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isSosActive 
                                ? [const Color(0xFFDC2626), const Color(0xFF991B1B)] 
                                : [ST.primary, ST.primaryContainer],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (_isSosActive ? const Color(0xFFDC2626) : ST.primary).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isSosActive ? Icons.priority_high : Icons.emergency_share, 
                                color: Colors.white, 
                                size: 28
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'SOS EMERGENCY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    _isSosActive ? 'Keep holding for 5 seconds...' : 'Hold for 5 seconds to alert circle',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                          ],
                        ),
                      ),
                      if (_isSosActive)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                            child: LinearProgressIndicator(
                              value: _sosProgress,
                              minHeight: 6,
                              backgroundColor: Colors.transparent,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white38),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

  
              // 4. Journey Mode
              ListenableBuilder(
                listenable: JourneyStateNotifier(),
                builder: (context, _) {
                  return JourneyStateNotifier().isActive 
                      ? const _JourneyCard() 
                      : const SizedBox.shrink();
                },
              ),
              ListenableBuilder(
                listenable: JourneyStateNotifier(),
                builder: (context, _) => SizedBox(height: JourneyStateNotifier().isActive ? 28 : 0),
              ),

              // 5. Smart Tip (AI Insight)
              // 5. Threat Alert Component
              const Text('NOTIFICATIONS',
                  style: TextStyle(
                      color: ST.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              _buildThreatAlertFeed(),
              const SizedBox(height: 120), // Bottom padding for floating nav
            ]),
          ),
        ),
      ],
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
        return GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF16A34A).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.navigation, color: Color(0xFF16A34A), size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ACTIVE JOURNEY',
                          style: TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 10,
                              height: 1.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800)),
                      Text(
                        'To: ${journey.destinationName ?? "Active Journey"}',
                        style: const TextStyle(
                            color: Color(0xFF14532D),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2),
                      ),
                      if (journey.checkInRemainingSeconds >= 0)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: Color(0xFFDC2626)),
                              const SizedBox(width: 4),
                              Text(
                                'Check-In: ${(journey.checkInRemainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(journey.checkInRemainingSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    '${journey.minutesRemaining} MIN',
                    style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 12,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Map Mini-view (follows user)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: journey.currentPosition ?? const LatLng(28.6139, 77.2090),
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _miniMapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  polylines: {
                    if (journey.points.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId('mini_route'),
                        points: journey.points,
                        color: ST.primary,
                        width: 4,
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
                      )
                  },
                ),
              ),
            ),
            
            // Progress Bar
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: (journey.progress * 100).toInt(),
                  child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(3))),
                ),
                Expanded(
                  flex: ((1.0 - journey.progress) * 100).toInt(),
                  child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(3))),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ON TRACK', 
                  style: TextStyle(color: Color(0xFF16A34A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                Text('${(journey.progress * 100).toInt()}% COMPLETED', 
                  style: const TextStyle(color: Color(0xFF15803D), fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
   });
  }

  @override
  void didUpdateWidget(covariant _JourneyCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pos = JourneyStateNotifier().currentPosition;
    if (pos != null) {
      _miniMapController?.animateCamera(CameraUpdate.newLatLng(pos));
    }
  }
}
