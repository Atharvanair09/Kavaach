import 'package:flutter/material.dart';
import 'timed_check_in.dart';
import 'my_circle.dart';
import 'fake_call.dart';
import 'shake_to_sos.dart';

class SafeTextHomeScreen extends StatelessWidget {
  const SafeTextHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: const Color(0xFFF6FAFE),
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'SafeText',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00C853), // Green for Live
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Live',
                    style: TextStyle(
                      color: Color(0xFF00C853),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Security Card
              Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                child: Column(
                  children: [
                    // Concentric circles with shield
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFEDF2FA), width: 1))),
                        Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: const Color(0xFFD6E3F9), width: 1))),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF3370FF),
                          ),
                          child: const Icon(Icons.shield,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Security protocol active',
                        style: TextStyle(
                            color: Color(0xFF8B95A5),
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    const Text('Current status: Secure',
                        style: TextStyle(
                            color: Color(0xFF0B1527),
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    // Score box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E9F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Area safety score',
                                  style: TextStyle(
                                      color: Color(0xFF8B95A5),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                              Text('8.4 / 10',
                                  style: TextStyle(
                                      color: Color(0xFF00C853),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 84,
                                child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF3370FF),
                                        borderRadius: BorderRadius.circular(3))),
                              ),
                              Expanded(
                                flex: 16,
                                child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFF0F4FA),
                                        borderRadius: BorderRadius.circular(3))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('Based on 127 reports near you',
                              style: TextStyle(
                                  color: Color(0xFF8B95A5), fontSize: 11)),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. SOS Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('SOS Emergency',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Hold 3 sec · alerts your circle',
                              style: TextStyle(
                                  color: Color(0xFFE0E7FF), fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                      child: const Center(
                        child: Icon(Icons.priority_high,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Journey Mode
              const _JourneyCard(),
              const SizedBox(height: 24),

              // 4. Quick Actions
              const Text('QUICK ACTIONS',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TimedCheckInScreen(),
                          ),
                        );
                      },
                      child: const _QuickActionCard(
                        icon: Icons.shield_outlined,
                        iconColor: Color(0xFF3B82F6),
                        iconBg: Color(0xFFEFF6FF),
                        title: 'Start check-in',
                        subtitle: 'Timed safety alert',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyCircleScreen(),
                          ),
                        );
                      },
                      child: _QuickActionCard(
                        icon: Icons.people_alt_outlined,
                        iconColor: const Color(0xFFD946EF),
                        iconBg: const Color(0xFFFDF4FF),
                        title: 'My circle',
                        subtitleWidget: Row(
                          children: [
                            _buildAvatars(),
                            const SizedBox(width: 6),
                            const Text('3 online',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FakeCallScreen(callerName: "Mom"),
                          ),
                        );
                      },
                      child: const _QuickActionCard(
                        icon: Icons.phone_in_talk_outlined,
                        iconColor: Color(0xFFF97316),
                        iconBg: Color(0xFFFFF7ED),
                        title: 'Fake call',
                        subtitle: 'Escape situation',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShakeToSosScreen(),
                          ),
                        );
                      },
                      child: _QuickActionCard(
                        icon: Icons.music_note_outlined,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFFECFDF5),
                        title: 'Shake to SOS',
                        subtitleWidget: Row(
                          children: [
                            Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF10B981),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('Armed',
                                style: TextStyle(
                                    color: Color(0xFF10B981), fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 5. Safe Tips
              const Text('SAFE TIPS',
                  style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  border: Border.all(color: const Color(0xFFFEF08A)),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAB308),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.priority_high,
                          size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('AI tip - 9:42 PM',
                              style: TextStyle(
                                  color: Color(0xFF854D0E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                              'Late night in your area — prefer well-lit main roads. 3 safe spots within 400m.',
                              style: TextStyle(
                                  color: Color(0xFFA16207),
                                  fontSize: 12,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
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

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.subtitle,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
    );
  }
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
          // Dark Blue Map Mockup
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A), // Dark blue
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                // Faint Grid pattern visually simulated via dividers
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
                // Heading "AI routing live"
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
                // "Home" label
                const Positioned(
                    top: 16,
                    right: 24,
                    child: Text('Home',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
                // Map Track
                Positioned(
                  top: 80,
                  left: 32,
                  right: 24,
                  child: Row(
                    children: [
                      // Blue node
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
                      // Active green line
                      Expanded(
                          flex: 60,
                          child: Container(
                              margin: const EdgeInsets.only(top: 26),
                              height: 4,
                              color: const Color(0xFF34D399))),
                      // Purple node (cafe)
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
                      // Dashed generic/inactive line simulated
                      Expanded(
                          flex: 40,
                          child: Container(
                              margin: const EdgeInsets.only(top: 26),
                              height: 2,
                              color: Colors.blueGrey.withOpacity(0.4))),
                      // Big green node (Home)
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
                // Avoid pill
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
                // Safe stop pill
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
                // Footer
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                              width: 10,
                              height: 4,
                              color: const Color(0xFF34D399)),
                          const SizedBox(width: 6),
                          const Text('Safe',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 10)),
                          const SizedBox(width: 16),
                          Container(
                              width: 10,
                              height: 2,
                              color: const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          const Text('Ahead',
                              style: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 10)),
                        ],
                      ),
                      const Text('400m total',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 3 Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.access_time,
                  iconColor: const Color(0xFF1D4ED8),
                  title: 'ETA\nhome',
                  value: '12',
                  unit: 'minutes',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFF15803D),
                  title: 'Safe\nstops',
                  value: '3',
                  unit: 'nearby',
                  borderColor: const Color(0xFFBBF7D0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricCard(
                  icon: Icons.shield,
                  iconColor: const Color(0xFF6B21A8),
                  title: 'Route\nrisk',
                  value: 'Low',
                  unit: 'AI assessed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Yellow tracking alert
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFCE8),
              border: Border.all(color: const Color(0xFFFEF08A)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high,
                      size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Riya is tracking your route',
                          style: TextStyle(
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      SizedBox(height: 2),
                      Text("She'll be notified if you go off-corridor",
                          style: TextStyle(
                              color: Color(0xFFB45309), fontSize: 11)),
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor ?? const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 11,
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                      height: 1.1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: iconColor)),
          const SizedBox(height: 2),
          Text(unit,
              style: TextStyle(
                  fontSize: 10, color: iconColor.withOpacity(0.6))),
        ],
      ),
    );
  }
}
