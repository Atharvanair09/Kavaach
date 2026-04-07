import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/st_style.dart';
import '../auth_service.dart';
import '../auth_gate.dart';

class STUserAvatar extends StatefulWidget {
  final double size;
  const STUserAvatar({super.key, this.size = 36});

  @override
  State<STUserAvatar> createState() => _STUserAvatarState();
}

class _STUserAvatarState extends State<STUserAvatar> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) {
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String initials = "";
    if (_user?['name'] != null) {
      List<String> names = _user!['name'].toString().trim().split(" ");
      if (names.isNotEmpty) {
        initials = names[0][0].toUpperCase();
        if (names.length > 1) {
          initials += names[1][0].toUpperCase();
        }
      }
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0E7FF), // Light blue from reference image
        border: Border.all(color: const Color(0xFFC7D2FE).withOpacity(0.5)),
      ),
      child: ClipOval(
        child: _user?['picture'] != null
            ? Image.network(
                _user!['picture'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildInitials(initials),
              )
            : _buildInitials(initials),
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Center(
      child: Text(
        initials.isNotEmpty ? initials : "?",
        style: TextStyle(
          color: const Color(0xFF1D4ED8), // Dark blue from reference image
          fontWeight: FontWeight.bold,
          fontSize: widget.size * 0.4,
        ),
      ),
    );
  }
}

class STProfileButton extends StatelessWidget {
  const STProfileButton({super.key});

  void _showProfile(BuildContext context, Map<String, dynamic>? user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user?['picture'] != null
                  ? NetworkImage(user!['picture'])
                  : null,
              child: user?['picture'] == null
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user?['name'] ?? 'User Name',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user?['email'] ?? 'user@example.com',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            STButton(
              label: 'Sign Out',
              onTap: () async {
                await AuthService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
              primary: false,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.getUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return GestureDetector(
          onTap: () => _showProfile(context, user),
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: STUserAvatar(size: 36),
          ),
        );
      }
    );
  }
}

class STButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;
  const STButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 56,
        decoration: BoxDecoration(
          gradient: primary
              ? const LinearGradient(
            colors: [ST.primary, ST.primaryContainer],
          )
              : null,
          color: primary ? null : ST.surfaceContainerHigh,
          borderRadius: ST.radiusFull,
          boxShadow: primary
              ? [
            BoxShadow(
              color: ST.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: primary ? ST.onPrimary : ST.onSurface,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, color: primary ? ST.onPrimary : ST.onSurface, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class PageDots extends StatelessWidget {
  final int current;
  final int count;
  const PageDots({super.key, required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 28 : 7,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: ST.radiusFull,
          ),
        );
      }),
    );
  }
}

class PageDotsBlue extends StatelessWidget {
  final int current;
  final int count;
  const PageDotsBlue({super.key, required this.current, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 28 : 7,
          height: 6,
          decoration: BoxDecoration(
            color: active ? ST.primary : ST.surfaceContainerHigh,
            borderRadius: ST.radiusFull,
          ),
        );
      }),
    );
  }
}


class STBottomNav extends StatelessWidget {
  final int selected;
  final Function(int) onTap;

  const STBottomNav({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.shield_outlined, Icons.shield, 'Status'),
      (Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat'),
      (Icons.map_outlined, Icons.map, 'Havens'),
      (Icons.settings_outlined, Icons.settings, 'Settings'),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, MediaQuery.of(context).padding.bottom + 10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: ST.primary.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final active = i == selected;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? ST.primary.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          active ? items[i].$2 : items[i].$1,
                          color: active ? ST.primary : Colors.grey.shade400,
                          size: 24,
                        ),
                        if (active) ...[
                          const SizedBox(height: 5),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: ST.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
