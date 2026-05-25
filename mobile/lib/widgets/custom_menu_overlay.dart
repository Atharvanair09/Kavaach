import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/journey_service.dart';
import '../auth_service.dart';
import '../auth_gate.dart';

class CustomMenuOverlay extends StatelessWidget {
  const CustomMenuOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0052D3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Top row: Logo and Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo (sunburst-like)
                  Image.asset('assets/safetext_icon.png', width: 48, height: 48),
                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.menu_open_rounded, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Spacer(),
              // Menu Items
              _buildMenuItem(context, 'Home', 0),
              const SizedBox(height: 16),
              _buildMenuItem(context, 'Chat Now', 1),
              const SizedBox(height: 16),
              _buildMenuItem(context, 'Maps', 2),
              const SizedBox(height: 16),
              _buildMenuItem(context, 'Settings', 3),
              const Spacer(),
              _buildSignOutItem(context),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String title, int navIndex) {
    return GestureDetector(
      onTap: () {
        JourneyStateNotifier().setNavIndex(navIndex);
        Navigator.of(context).pop();
      },
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildSignOutItem(BuildContext context) {
    return FutureBuilder(
      future: AuthService.getUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (user != null)
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white24,
                    backgroundImage: user['picture'] != null 
                      ? NetworkImage(user['picture']) 
                      : null,
                    child: user['picture'] == null 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'] ?? 'User',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user['email'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              const SizedBox(),
            GestureDetector(
              onTap: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }
    );
  }
}
