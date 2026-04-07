import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../chat/chat_screen.dart';
import '../location/location_screen.dart';
import '../fake_app/fake_app_screen.dart';
import '../settings/settings_screen.dart';
import '../../auth_service.dart';
import '../../timed_check_in.dart';
import '../../my_circle.dart';
import '../../fake_call.dart';
import '../../shake_to_sos.dart';

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
    return Scaffold(
      extendBody: true,
      backgroundColor: ST.surface,
      body: IndexedStack(
        index: _navIndex,
        children: _screens,
      ),
      bottomNavigationBar: STBottomNav(
        selected: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
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
              const SizedBox(height: 12),
              
              // 1. Safety Score Hero Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: ST.primary.withOpacity(0.04),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: 0.94,
                            strokeWidth: 12,
                            backgroundColor: ST.primary.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(ST.primary),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          children: [
                            const Text('94',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: ST.onSurface,
                                  height: 1,
                                )),
                            Text('SAFETY SCORE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: ST.onSurfaceVariant.withOpacity(0.5),
                                )),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your area is highly secure',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ST.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on 127 local reports & AI scanning',
                      style: TextStyle(
                        fontSize: 12,
                        color: ST.onSurfaceVariant.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: ST.outlineVariant.withAlpha(50),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStatus(Icons.wifi, "Network Sec: High", Colors.green),
                        _miniStatus(Icons.location_on, "Active Guard", ST.primary),
                      ],
                    ),
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
                onLongPress: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("SOS ALERT TRIGGERED!"),
                      backgroundColor: ST.tertiary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ST.primary, ST.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: ST.primary.withOpacity(0.4),
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
                        child: const Icon(Icons.emergency_share, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SOS EMERGENCY',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Hold for 3 seconds to alert circle',
                              style: TextStyle(
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
              ),
              const SizedBox(height: 20),

              // 4. Journey Mode
              const _JourneyCard(),
              const SizedBox(height: 28),

              // 5. Smart Tip (AI Insight)
              const Text('AI INSIGHT',
                  style: TextStyle(
                      color: ST.onSurfaceVariant,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: ST.primary.withOpacity(0.05)),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: ST.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: ST.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Night Shift Recommendation',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'It’s getting late. Enable "Stay on Route" for extra security.',
                            style: TextStyle(fontSize: 12, color: ST.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          border: Border.all(color: const Color(0xFFBBF7D0)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Journey mode - active',
                          style: TextStyle(
                              color: Color(0xFF166534),
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('Home → Phoenix Mall · 18 min left',
                          style: TextStyle(
                              color: Color(0xFF15803D), fontSize: 12)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Text('On track',
                        style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF16A34A),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 50,
                  child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(2))),
                ),
                Expanded(
                  flex: 50,
                  child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(2))),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: _buildExpandedContent(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
              alignment: Alignment.topCenter,
              sizeCurve: Curves.easeInOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(width: 1, color: Colors.white.withOpacity(0.05)),
                      Container(width: 1, color: Colors.white.withOpacity(0.05)),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(height: 1, color: Colors.white.withOpacity(0.05)),
                      Container(height: 1, color: Colors.white.withOpacity(0.05)),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Row(
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: Color(0xFF60A5FA),
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('AI routing live',
                          style: TextStyle(
                              color: Color(0xFF60A5FA),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
                const Positioned(
                    top: 16,
                    right: 24,
                    child: Text('Home',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                Positioned(
                  top: 80,
                  left: 32,
                  right: 24,
                  child: Row(
                    children: [
                      Column(
                        children: [
                          const Text('You',
                              style: TextStyle(
                                  color: Color(0xFFBFDBFE),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                          const SizedBox(height: 12),
                          Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF60A5FA),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3))),
                        ],
                      ),
                      Expanded(
                          flex: 60,
                          child: Container(
                              margin: const EdgeInsets.only(top: 26),
                              height: 4,
                              color: const Color(0xFF34D399))),
                      Column(
                        children: [
                          Container(
                              margin: const EdgeInsets.only(top: 26),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                  color: const Color(0xFFA78BFA),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2))),
                        ],
                      ),
                      Expanded(
                          flex: 40,
                          child: Container(
                              margin: const EdgeInsets.only(top: 26),
                              height: 2,
                              color: Colors.blueGrey.withOpacity(0.4))),
                      Column(
                        children: [
                          Container(
                              margin: const EdgeInsets.only(top: 26),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                  color: const Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3))),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 45,
                  left: 60,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF991B1B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFEF4444).withOpacity(0.5))),
                        child: const Text('Avoid - poorly lit',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                      Container(
                        width: 2,
                        height: 12,
                        color: const Color(0xFFEF4444).withOpacity(0.8),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 105,
                  left: 100,
                  child: Column(
                    children: [
                      Container(
                        width: 2,
                        height: 12,
                        color: const Color(0xFFFBBF24).withOpacity(0.8),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFFD97706),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFFFCD34D))),
                        child: const Text('Café - safe stop',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
