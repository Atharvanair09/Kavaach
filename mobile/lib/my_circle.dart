import 'package:flutter/material.dart';
import 'dart:math' as math;

class MyCircleScreen extends StatefulWidget {
  const MyCircleScreen({Key? key}) : super(key: key);

  @override
  State<MyCircleScreen> createState() => _MyCircleScreenState();
}

class _MyCircleScreenState extends State<MyCircleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Soft blue-grey background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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

                      // Node: R (Top, Inner Orbit)
                      Positioned(
                        top: 40,
                        child: _buildAvatarNode('R', const Color(0xFF1D4ED8), const Color(0xFFE0E7FF)),
                      ),

                      // Node: S (Bottom Left, Outer Orbit)
                      Positioned(
                        bottom: 30,
                        left: 10,
                        child: _buildAvatarNode('S', const Color(0xFF166534), const Color(0xFFDCFCE7)),
                      ),

                      // Node: A (Bottom Right, Outer Orbit)
                      Positioned(
                        bottom: 30,
                        right: 15,
                        child: _buildAvatarNode('A', const Color(0xFF9F1239), const Color(0xFFFCE7F3)),
                      ),

                      // Node: M (Top Right, slightly off outer)
                      Positioned(
                        top: 45,
                        right: 10,
                        child: _buildAvatarNode('M', const Color(0xFF92400E), const Color(0xFFFEF3C7), size: 28),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 56),

                // Status Text
                const Text(
                  'Riya is 1.2 km away',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDistancePill('Riya · 1.2km', const Color(0xFF166534), const Color(0xFFDCFCE7)),
                      const SizedBox(width: 8),
                      _buildDistancePill('Asha · 4.8km', const Color(0xFF312E81), const Color(0xFFE0E7FF)),
                      const SizedBox(width: 8),
                      _buildDistancePill('Sara · 12km', const Color(0xFF9F1239), const Color(0xFFFCE7F3)),
                    ],
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
