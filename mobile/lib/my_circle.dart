import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'services/emergency_contact_service.dart';

class MyCircleScreen extends StatefulWidget {
  const MyCircleScreen({Key? key}) : super(key: key);

  @override
  State<MyCircleScreen> createState() => _MyCircleScreenState();
}

class _MyCircleScreenState extends State<MyCircleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _loadCircle();
  }

  Future<void> _loadCircle() async {
    try {
      final contacts = await EmergencyContactService.fetchContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deepest midnight blue
      body: Stack(
        children: [
          // 1. Radar Background (Centered)
          Center(
            child: AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(double.infinity, double.infinity),
                  painter: TacticalRadarPainter(_radarController.value),
                );
              },
            ),
          ),

          // 2. Contact Nodes (Live data from circle)
          if (!_isLoading) ..._buildContactNodes(),

          // 3. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  // Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        // Left Accent Bar
                        Container(
                          width: 3,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CIRCLE AWARENESS',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF3B82F6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _contacts.isEmpty ? 'Scanning Circle' : 'Circle Active',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _contacts.isEmpty 
                                  ? 'Searching for trusted contacts...' 
                                  : '${_contacts.length} members are watching over you.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),

                  // Bottom Action Grid
                  Row(
                    children: [
                      // Silent Alert Button
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.cell_tower_rounded,
                          label: 'SILENT ALERT',
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Emergency Contact Button
                      Expanded(
                        child: _buildActionBtn(
                          icon: Icons.person_add_disabled_rounded,
                          label: 'NOTIFY CIRCLE',
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),

                  // Route to Closest FAB-style button
                  Container(
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(32),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Secure My Perimeter',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          
          // Center User Node
          Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.8), blurRadius: 15, spreadRadius: 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color}) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContactNodes() {
    return [
      // Trusted Circle Contacts (Blue Nodes)
      ..._contacts.asMap().entries.map((entry) {
        int idx = entry.key;
        final offsets = [
          {'r': 140.0, 'a': 3.5},   // Ring 2, Mid Leftish
          {'r': 220.0, 'a': 1.5},   // Ring 3, Bottomish
        ];
        final pos = offsets[idx % offsets.length];
        return _positionedContactNode(pos['r']!, pos['a']!, entry.value);
      }),

      // Safe Havens (Color coded as requested)
      _positionedHavenNode(80.0, -0.5, const Color(0xFF22C55E), 'Police'),   // Green
      _positionedHavenNode(160.0, 0.8, const Color(0xFFA855F7), 'Hospital'), // Purple
      _positionedHavenNode(210.0, 4.8, const Color(0xFFF97316), 'Shelter'),  // Orange
    ];
  }

  Widget _positionedContactNode(double radius, double angle, EmergencyContact contact) {
    return Center(
      child: Transform.translate(
        offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.5), blurRadius: 10, spreadRadius: 2),
                ],
              ),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF1E293B),
                child: Text(
                  contact.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              contact.name.split(' ')[0],
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.6),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionedHavenNode(double radius, double angle, Color color, String label) {
    return Center(
      child: Transform.translate(
        offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.6), blurRadius: 8, spreadRadius: 2),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.4),
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TacticalRadarPainter extends CustomPainter {
  final double animationValue;
  TacticalRadarPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw Static Concentric Circles
    final radii = [80.0, 140.0, 220.0];
    for (var r in radii) {
      canvas.drawCircle(center, r, paint);
    }

    // Draw animated pulse
    final pulsePaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(1.0 - animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    canvas.drawCircle(center, 220.0 * animationValue, pulsePaint);
  }

  @override
  bool shouldRepaint(TacticalRadarPainter oldDelegate) => true;
}
