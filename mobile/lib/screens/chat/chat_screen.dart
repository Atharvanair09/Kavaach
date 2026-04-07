import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import 'chat_bubbles.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
                'TODAY, 10:42 PM',
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: const [
                    SupportBubble(
                      text: "I'm here with you. How are you feeling about your current surroundings?",
                    ),
                    UserBubble(
                      text: "Someone has been following me for two blocks. I'm walking towards the main square now.",
                    ),
                    // AnalyzingCard(),
                    SupportBubble(
                      text: "Understood. I've locked your GPS coordinates. Keep your phone visible. Would you like me to alert your emergency contacts or play a fake phone call audio?",
                    ),
                  ],
                ),
              ),
            ),
            // Input Area
            _ChatInputSection(),
          ],
        ),
      ),
    );
  }
}

class _ChatInputSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.mic, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 12),
          Container(
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
        ],
      ),
    );
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
