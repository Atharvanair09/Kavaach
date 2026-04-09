import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'services/emergency_contact_service.dart';

class MyCircleScreen extends StatefulWidget {
  const MyCircleScreen({Key? key}) : super(key: key);

  @override
  State<MyCircleScreen> createState() => _MyCircleScreenState();
}

class _MyCircleScreenState extends State<MyCircleScreen> {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Soft blue-grey background
      appBar: AppBar(
        title: const Text('My Circle', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                const Text(
                  'CIRCLE AWARENESS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 48),

                // Radar Map Area
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Outer Dashed Orbit
                      CustomPaint(
                        size: const Size(220, 220),
                        painter: DashedCirclePainter(
                          color: const Color(0xFFBFDBFE),
                          strokeWidth: 1.5,
                          dashWidth: 6,
                          dashSpace: 4,
                        ),
                      ),
                      // Inner Dashed Orbit
                      CustomPaint(
                        size: const Size(140, 140),
                        painter: DashedCirclePainter(
                          color: const Color(0xFFBFDBFE),
                          strokeWidth: 1.5,
                          dashWidth: 6,
                          dashSpace: 4,
                        ),
                      ),

                      // Center Shield Profile
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 32),
                      ),

                      // Build nodes from actual contacts
                      ..._buildContactNodes(),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                // Status Text
                Text(
                  _contacts.isNotEmpty 
                      ? '${_contacts[0].name} is active' 
                      : 'No contacts in circle',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your circle is watching',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                  ),
                ),

                const SizedBox(height: 24),

                // Distance Pills Row
                if (_contacts.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _contacts.map((c) {
                      // Simulated distance for UI polish
                      final dist = (math.Random().nextDouble() * 15).toStringAsFixed(1);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildDistancePill('${c.name} · ${dist}km', const Color(0xFF166534), const Color(0xFFDCFCE7)),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 48),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live location broadcast started!')),
                    );
                  },
                  icon: const Icon(Icons.location_on, color: Colors.white),
                  label: const Text(
                    'Share Live Location', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Safe ping sent to your circle!')),
                    );
                  },
                  icon: const Icon(Icons.notifications_active, color: Color(0xFF3B82F6)),
                  label: const Text(
                    "Ping: I'm on my way", 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFFBFDBFE), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContactNodes() {
    if (_contacts.isEmpty) return [];

    // Pre-defined positions for radar nodes
    final positions = [
       {'top': 40.0, 'left': null, 'right': null}, // Center Top
       {'bottom': 30.0, 'left': 10.0, 'right': null}, // Bottom Left
       {'bottom': 30.0, 'right': 15.0, 'left': null}, // Bottom Right
       {'top': 45.0, 'right': 10.0, 'left': null}, // Top Right
    ];

    return _contacts.asMap().entries.map((entry) {
      int idx = entry.key;
      if (idx >= positions.length) return const SizedBox.shrink();
      
      final contact = entry.value;
      final pos = positions[idx];
      
      return Positioned(
        top: pos['top'] as double?,
        bottom: pos['bottom'] as double?,
        left: pos['left'] as double?,
        right: pos['right'] as double?,
        child: _buildAvatarNode(
          contact.name[0], 
          const Color(0xFF1D4ED8), 
          const Color(0xFFE0E7FF)
        ),
      );
    }).toList();
  }

  Widget _buildAvatarNode(String letter, Color textColor, Color bgColor, {double size = 36}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            spreadRadius: 4,
          )
        ]
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: textColor,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildDistancePill(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dashWidth = 5.0,
    this.dashSpace = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    var rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // Draw dashed path logic drawing arc segments
    double circumference = size.width * math.pi;
    int dashCount = (circumference / (dashWidth + dashSpace)).floor();
    double sweepAngle = (dashWidth / circumference) * 2 * math.pi;
    double spaceAngle = (dashSpace / circumference) * 2 * math.pi;

    for (int i = 0; i < dashCount; i++) {
      double startAngle = i * (sweepAngle + spaceAngle);
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
