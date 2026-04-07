import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locations = [
      (Icons.local_police_outlined, 'Police Station', '1.2km • Central District',
      ST.primary, ST.primaryFixed),
      (Icons.shield_outlined, 'Safe Shelter', '2.5km • North Center',
      ST.tertiary, ST.tertiaryFixed),
      (Icons.local_hospital_outlined, 'Hospital', '4.0km • General Medical',
      ST.secondary, ST.secondaryFixed),
    ];

    return Scaffold(
      backgroundColor: ST.surface,
      body: Column(
        children: [
          // Map section
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.38,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: ST.surfaceContainer),
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDh_Zv0VmuSrO8v6wu2PCmldbcP0n7xR4dL4fXmZ1_RF1SeDzkwUIyWckVLFILaTAEkfsBEMAHkV9eKfIo56jKxzDjcgSvKNCrgUBnK8VH4ty6F9zJW3gv4OLJxL7Oqt6_R6fZNHAZu_8aLWa4BCv5uPrUUULC06j5ncoKmZdbbA5YJHXmoi6HM8kCZtw9yGYh-2UtnBCAvuRm_qCdMzLvwGBBizwYWCc85yC4a-Jts3h4Z2VBJJgd8fdZs4imIEENCEIXBsdCpm2g',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  color: ST.surfaceContainer.withOpacity(0.5),
                  colorBlendMode: BlendMode.multiply,
                  errorBuilder: (_, __, ___) => Container(
                    color: ST.surfaceContainerHigh,
                    child: CustomPaint(painter: MapGridPainter()),
                  ),
                ),
                // Map pins
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.10,
                  left: MediaQuery.of(context).size.width * 0.33,
                  child: const MapPin(color: ST.tertiary, pulsing: true),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height * 0.15,
                  right: MediaQuery.of(context).size.width * 0.25,
                  child: const MapPin(color: ST.tertiary),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.08,
                  left: MediaQuery.of(context).size.width * 0.48,
                  child: const MapPin(color: ST.tertiary),
                ),
                // My location button
                Positioned(
                  right: 16,
                  bottom: 52,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.my_location,
                        color: ST.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),
          // Content card
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -32),
              child: Container(
                decoration: const BoxDecoration(
                  color: ST.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0F171C1F),
                      blurRadius: 32,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Scrollable list content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Safe Havens Nearby',
                                      style: TextStyle(
                                        fontFamily: 'Rockwell',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 26,
                                        color: ST.onSurface,
                                        height: 1.1,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Verifying secure locations\nwithin your radius',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: ST.onSurfaceVariant,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                                ActiveScanBadge(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ...locations.map((loc) => _LocationRow(
                              icon: loc.$1,
                              title: loc.$2,
                              subtitle: loc.$3,
                              iconColor: loc.$4,
                              iconBg: loc.$5,
                            )),
                          ],
                        ),
                      ),
                    ),
                    // CTA pinned at bottom
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: 64,
                              decoration: BoxDecoration(
                                color: ST.primary,
                                borderRadius: ST.radiusSm,
                                boxShadow: [
                                  BoxShadow(
                                    color: ST.primary.withOpacity(0.35),
                                    blurRadius: 40,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_car,
                                      color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Request Ride',
                                    style: TextStyle(
                                      fontFamily: 'Bernard MT Condensed',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'YOUR CURRENT COORDINATES ARE SHARED WITH TRUSTED CONTACTS',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: ST.onSurfaceVariant.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ST.outlineVariant.withOpacity(0.4)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class MapPin extends StatefulWidget {
  final Color color;
  final bool pulsing;
  const MapPin({super.key, required this.color, this.pulsing = false});

  @override
  State<MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<MapPin> with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    if (widget.pulsing) _ac.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.pulsing)
          AnimatedBuilder(
            animation: _ac,
            builder: (_, __) => Container(
              width: 32 * _ac.value + 8,
              height: 32 * _ac.value + 8,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.2 * (1 - _ac.value)),
                shape: BoxShape.circle,
              ),
            ),
          ),
        Icon(Icons.location_on, color: widget.color, size: 32),
      ],
    );
  }
}

class ActiveScanBadge extends StatefulWidget {
  const ActiveScanBadge({super.key});

  @override
  State<ActiveScanBadge> createState() => _ActiveScanBadgeState();
}

class _ActiveScanBadgeState extends State<ActiveScanBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: ST.radiusFull,
        border: Border.all(color: const Color(0xFFBFD7FF), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _ac,
            builder: (_, __) => Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color.lerp(const Color(0xFF2563EB),
                    const Color(0xFF60A5FA), _ac.value),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'ACTIVE SCAN',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D4ED8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBg;
  const _LocationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: ST.radiusSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    color: ST.onSurface,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ST.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Show Map',
              style: TextStyle(
                color: ST.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
