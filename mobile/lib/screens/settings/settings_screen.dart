import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/st_style.dart';
import '../../auth_service.dart';
import '../../services/emergency_contact_service.dart';
import '../home/home_screen.dart';
import '../auth/login_screen.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _decoyPin = false;
  bool _shakeToAlert = true;
  bool _disguiseMode = false;
  bool _silentAlerts = true;
  bool _checkinReminders = true;
  bool _enterPin = true;

  List<Map<String, String>> _trustedContacts = [
  ];

  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadDecoyPinStatus();
    _loadPinStatus();
  }

  Future<void> _loadPinStatus() async {
    final hasPin = await AuthService.hasAppPin();
    if (mounted) setState(() => _enterPin = hasPin);
  }

  Future<void> _loadDecoyPinStatus() async {
    final hasDecoy = await AuthService.hasDecoyPin();
    if (mounted) setState(() => _decoyPin = hasDecoy);
  }

  Future<void> _loadUser() async {
    // 1. Load from local storage first for instant UI response
    try {
      final localContacts = await EmergencyContactService.fetchContacts();
      if (mounted && localContacts.isNotEmpty) {
        setState(() {
          _trustedContacts = localContacts.map((c) => {
            'name': c.name,
            'phone': c.phone
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading local contacts: $e');
    }

    // 2. Load from Firebase for cloud sync
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
      if (user['email'] != null) {
        _loadFirebaseContacts(user['email']);
      }
    }
  }


  Future<void> _loadFirebaseContacts(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    debugPrint('🔍 LOADING CONTACTS FOR: $cleanEmail');
    try {
      // 1. Find the user document (it might be named by ID or by email)
      DocumentSnapshot? doc;
      
      // Try by ID first if we have it
      if (_user != null && _user!['id'] != null) {
        doc = await FirebaseFirestore.instance.collection('users').doc(_user!['id'].toString()).get();
      }
      
      // If not found or no ID, try by email as document ID
      if (doc == null || !doc.exists) {
        doc = await FirebaseFirestore.instance.collection('users').doc(cleanEmail).get();
      }
      
      // If still not found, search by email field
      if (!doc.exists) {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: cleanEmail)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          doc = query.docs.first;
        }
      }

      List<dynamic>? contacts;

      if (doc != null && doc.exists && doc.data() is Map) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('emergencyContacts')) {
          contacts = data['emergencyContacts'];
        }
      } 
      
      if (contacts == null) {
        // Fallback to old location for migration
        final oldDoc = await FirebaseFirestore.instance.collection('emergency_contacts').doc(cleanEmail).get();
        if (oldDoc.exists && oldDoc.data()!.containsKey('contacts')) {
          contacts = oldDoc.data()!['contacts'];
          debugPrint('📝 Found contacts in old collection, migrating...');
        }
      }

      if (contacts != null && contacts.isNotEmpty) {
        final typedContacts = contacts.map((e) => Map<String, String>.from(e)).toList();
        
        if (mounted) {
          setState(() {
            _trustedContacts = typedContacts;
          });
        }

        // Sync back to local storage
        final prefs = await SharedPreferences.getInstance();
        final localKey = 'emergency_contacts_local_${_user!['email']}';
        await prefs.setString(localKey, jsonEncode(typedContacts));
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }
  }


  Future<void> _saveContactsToFirebase() async {
    if (_user == null || _user!['email'] == null) return;
    final cleanEmail = _user!['email'].toString().trim().toLowerCase();
    try {
      await AuthService.updateContacts(
        email: cleanEmail,
        contacts: _trustedContacts,
      );
      
      // Also save locally
      final prefs = await SharedPreferences.getInstance();
      final localKey = 'emergency_contacts_local_${_user!['email']}';
      await prefs.setString(localKey, jsonEncode(_trustedContacts));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency contacts saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save contacts: $e')),
        );
      }
    }
  }



  Future<void> _showEditProfileDialog(BuildContext context) async {
    if (_user == null) return;
    
    final nameController = TextEditingController(text: _user!['name']?.toString());
    final phoneController = TextEditingController(text: _user!['phone']?.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile', style: TextStyle(fontFamily: 'Bernard MT Condensed')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
                onPressed: () async {
              final newName = nameController.text.trim();
              final newPhone = phoneController.text.trim();
              
              if (newName.isEmpty) return;
              
              Navigator.pop(context);
              
              try {
                final email = _user!['email'].toString().trim().toLowerCase();
                
                final result = await AuthService.updateProfile(
                  email: email,
                  name: newName,
                  phone: newPhone,
                );
                
                // Update local state from the response
                if (mounted) {
                  setState(() {
                    _user = result['user'];
                  });
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update profile: ${e.toString().replaceAll('Exception: ', '')}')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white.withOpacity(0.85),
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.06),
            title: const Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF1D4ED8),
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileCard(),
                _buildDivider(),
                _buildSectionHeader('Safety'),
                _buildNavRow(
                  icon: Icons.shield_outlined,
                  iconBg: const Color(0xFFDAE1FF),
                  iconColor: ST.primary,
                  label: 'Trusted Circle',
                  subtitle: '${_trustedContacts.length} contacts added',
                  onTap: () => _showTrustedCircleSetup(context),
                ),
                if (_trustedContacts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 72, bottom: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: -4,
                        children: _trustedContacts.take(3).map<Widget>((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ST.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ST.primary,
                            ),
                          ),
                        )).toList()..addAll([
                          if (_trustedContacts.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text('+${_trustedContacts.length - 3} more', style: const TextStyle(fontSize: 10, color: ST.onSurfaceVariant)),
                            )
                        ]),

                      ),
                    ),
                  ),

                _buildNavRow(
                  icon: Icons.timer_outlined,
                  iconBg: const Color(0xFFEAF3DE),
                  iconColor: const Color(0xFF3B6D11),
                  label: 'Check-in Timer',
                  subtitle: 'Default: 30 min',
                  onTap: () => _showCheckinTimerSheet(context),
                ),
                _buildNavRow(
                  icon: Icons.location_on_outlined,
                  iconBg: const Color(0xFFFFDADB),
                  iconColor: ST.tertiary,
                  label: 'Safe Zones',
                  subtitle: 'Home, Work added',
                  onTap: () => _showComingSoon(context),
                ),
                _buildNavRow(
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  label: _enterPin ? 'Update PIN' : 'Enter PIN',
                  subtitle: _enterPin ? 'PIN is securely active' : 'Secure your app using PIN',
                  onTap: () {
                    _showPinScreen(context);
                    Future.delayed(const Duration(seconds: 10), () => _loadPinStatus());
                  },
                ),
                _buildToggleRow(
                  icon: Icons.lock_outline,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  label: 'Decoy PIN',
                  subtitle: 'Triggers fake app screen',
                  value: _decoyPin,
                  onChanged: (v) {
                    if (v) {
                      _showDecoyPinSetup(context);
                    } else {
                      AuthService.clearDecoyPin();
                      setState(() => _decoyPin = false);
                    }
                  },
                ),
                _buildToggleRow(
                  icon: Icons.sensors,
                  iconBg: const Color(0xFFFBEAF0),
                  iconColor: const Color(0xFF993556),
                  label: 'Shake-to-Alert',
                  subtitle: 'Shake phone to send SOS',
                  value: _shakeToAlert,
                  onChanged: (v) => setState(() => _shakeToAlert = v),
                ),
                _buildDivider(),
                _buildSectionHeader('Privacy'),
                _buildToggleRow(
                  icon: Icons.visibility_off_outlined,
                  iconBg: const Color(0xFFDAE1FF),
                  iconColor: ST.primary,
                  label: 'Disguise Mode',
                  subtitle: 'App looks like a notes app',
                  value: _disguiseMode,
                  onChanged: (v) => setState(() => _disguiseMode = v),
                ),
                _buildNavRow(
                  icon: Icons.auto_delete_outlined,
                  iconBg: const Color(0xFFEEEDFE),
                  iconColor: const Color(0xFF534AB7),
                  label: 'Chat Auto-Delete',
                  subtitle: 'After 24 hours',
                  onTap: () => _showAutoDeleteSheet(context),
                ),
                _buildNavRow(
                  icon: Icons.history_toggle_off_outlined,
                  iconBg: const Color(0xFFEAF3DE),
                  iconColor: const Color(0xFF3B6D11),
                  label: 'Location History',
                  subtitle: 'Stored locally only',
                  onTap: () => _showComingSoon(context),
                ),
                _buildDivider(),
                _buildSectionHeader('Notifications'),
                _buildToggleRow(
                  icon: Icons.vibration,
                  iconBg: const Color(0xFFFAEEDA),
                  iconColor: const Color(0xFF854F0B),
                  label: 'Silent Alerts',
                  subtitle: 'Vibrate only in danger mode',
                  value: _silentAlerts,
                  onChanged: (v) => setState(() => _silentAlerts = v),
                ),
                _buildToggleRow(
                  icon: Icons.notifications_active_outlined,
                  iconBg: const Color(0xFFE1F5EE),
                  iconColor: const Color(0xFF0F6E56),
                  label: 'Check-in Reminders',
                  subtitle: '15 min before expiry',
                  value: _checkinReminders,
                  onChanged: (v) => setState(() => _checkinReminders = v),
                ),
                _buildDivider(),
                _buildSectionHeader('Account'),
                _buildNavRow(
                  icon: Icons.cloud_upload_outlined,
                  iconBg: const Color(0xFFF1EFE8),
                  iconColor: const Color(0xFF5F5E5A),
                  label: 'Backup & Restore',
                  subtitle: 'Encrypted cloud backup',
                  onTap: () => _showComingSoon(context),
                ),
                _buildNavRow(
                  icon: Icons.info_outline,
                  iconBg: const Color(0xFFF1EFE8),
                  iconColor: const Color(0xFF5F5E5A),
                  label: 'About & Legal',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showAboutSheet(context),
                ),
                _buildDivider(),
                _buildDeleteRow(context),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    if (_isLoading) return const SizedBox.shrink();
    if (_user == null) return const SizedBox.shrink();

    final name = _user!['name']?.toString() ?? 'Unknown User';
    final email = _user!['email']?.toString() ?? '';
    final nameParts = name.trim().split(RegExp(r'\s+'));
    String initials = '';
    if (nameParts.isNotEmpty) {
      initials += nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '';
      if (nameParts.length > 1) {
        initials += nameParts[1].isNotEmpty ? nameParts[1][0].toUpperCase() : '';
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: ST.surfaceContainerLowest,
        borderRadius: ST.radiusSm,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: ST.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontFamily: 'Bernard MT Condensed',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: ST.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: ST.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    color: ST.onSurfaceVariant,
                  ),
                ),
                if (_user!['phone'] != null && _user!['phone'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 12, color: ST.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _user!['phone'].toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: ST.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: ST.radiusFull,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B6D11),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Protected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3B6D11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: ST.onSurfaceVariant, size: 20),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: ST.surfaceContainer,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Haettenschweiler',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: ST.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildNavRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: ST.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: ST.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ST.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: ST.onSurfaceVariant, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: ST.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: ST.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ST.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: ST.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteRow(BuildContext context) {
    bool isLoggedIn = _user != null;
    return InkWell(
      onTap: () async {
        if (isLoggedIn) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          await AuthService.signOut();
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
      child: Container(
        color: ST.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isLoggedIn ? const Color(0xFFFFDADB) : ST.primaryFixed,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
              Icon(isLoggedIn ? Icons.logout : Icons.login, color: isLoggedIn ? ST.tertiary : ST.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(
              isLoggedIn ? 'LogOut' : 'LogIn',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isLoggedIn ? ST.tertiary : ST.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinScreen(BuildContext context) {
    final pinController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter PIN',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: ST.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Secure your app using PIN',
              style: TextStyle(
                fontSize: 14,
                color: ST.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'PIN',
                hintText: 'Enter a 4-digit PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  if (pin.length == 4) {
                    await AuthService.saveAppPin(pin);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN successfully saved!')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be 4 digits.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ST.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save PIN',
                  style: TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showDecoyPinSetup(BuildContext context) {
    final pinController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set Decoy PIN',
              style: TextStyle(
                fontFamily: 'Bernard MT Condensed',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: ST.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter a secondary PIN to open the fake app screen.',
              style: TextStyle(
                fontSize: 14,
                color: ST.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Decoy PIN',
                hintText: 'Enter a 4-digit PIN',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final pin = pinController.text.trim();
                  if (pin.length == 4) {
                    await AuthService.saveDecoyPin(pin);
                    if (mounted) setState(() => _decoyPin = true);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Decoy PIN saved!')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN must be 4 digits.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ST.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enable Decoy Mode',
                  style: TextStyle(
                    fontFamily: 'Bernard MT Condensed',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showTrustedCircleSetup(BuildContext context) {
    List<Map<String, String>>? cachedFirebaseUsers;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: ST.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trusted Circle',
                      style: TextStyle(
                        fontFamily: 'Bernard MT Condensed',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: ST.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add emergency contacts who will receive your live location and SOS alerts.',
                      style: TextStyle(fontSize: 14, color: ST.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    if (_trustedContacts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: Text('No contacts added yet.', style: TextStyle(color: ST.onSurfaceVariant, fontStyle: FontStyle.italic)),
                      )
                    else
                      Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: ST.surfaceContainerLow,
                          borderRadius: ST.radiusSm,
                          border: Border.all(color: ST.outlineVariant.withOpacity(0.5)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _trustedContacts.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: ST.outlineVariant.withOpacity(0.3)),
                          itemBuilder: (ctx, i) {
                            final contact = _trustedContacts[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: ST.primaryFixed,
                                child: const Icon(Icons.person, color: ST.primary, size: 20),
                              ),
                              title: Text(contact['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(contact['phone'] ?? '', style: const TextStyle(fontSize: 12)),
                                trailing: IconButton(
                                icon: const Icon(Icons.remove_circle, color: Color(0xFFDC2626), size: 20),
                                onPressed: () {
                                  setModalState(() => _trustedContacts.removeAt(i));
                                  setState(() {}); // Update main screen counter
                                  _saveContactsToFirebase();
                                },
                              ),

                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    const Text(
                      'QUICK ADD',
                      style: TextStyle(fontFamily: 'Bernard MT Condensed', fontSize: 13, color: ST.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _selectFromContacts(setModalState),
                        icon: const Icon(Icons.contact_phone_rounded, size: 20, color: Colors.white),
                        label: const Text(
                          'Import from Phone Contacts',
                          style: TextStyle(
                            fontFamily: 'Bernard MT Condensed',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ST.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _saveContactsToFirebase();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ST.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        child: const Text(
                          'SAVE CHANGES TO CLOUD',
                          style: TextStyle(
                            fontFamily: 'Bernard MT Condensed',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: ST.onSurfaceVariant.withOpacity(0.7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );

          },
        ),
      ),
    );
  }

  Future<void> _selectFromContacts(void Function(void Function()) setModalState) async {
    // Use permission_handler for reliable permission checking
    final status = await Permission.contacts.status;

    if (status.isGranted) {
      // Already granted — go straight to picker
      await _openPicker(setModalState);

    } else if (status.isDenied) {
      // Request it
      final result = await Permission.contacts.request();
      if (result.isGranted) {
        await _openPicker(setModalState);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contacts permission denied.')),
          );
        }
      }

    } else if (status.isPermanentlyDenied) {
      // User tapped "Don't ask again" — must send to settings
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Contacts permission is disabled. Please enable it in App Settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  openAppSettings(); // opens device settings directly
                  Navigator.pop(ctx);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }
  }

// Separated picker logic
  Future<void> _openPicker(void Function(void Function()) setModalState) async {
    final contact = await FlutterContacts.openExternalPick();
    if (contact != null) {
      final fullContact = await FlutterContacts.getContact(contact.id);
      if (fullContact != null && fullContact.phones.isNotEmpty) {
        final name  = fullContact.displayName;
        final phone = fullContact.phones.first.number;
        setModalState(() {
          if (!_trustedContacts.any((c) => c['phone'] == phone)) {
            _trustedContacts.add({'name': name, 'phone': phone});
          }
        });
        setState(() {});
        _saveContactsToFirebase();

      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected contact has no phone number.')),
          );
        }
      }
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming soon'),
        backgroundColor: ST.primary,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showCheckinTimerSheet(BuildContext context) {
    final options = ['15 min', '30 min', '1 hour', '2 hours', '4 hours'];
    String selected = '30 min';
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ST.outlineVariant,
                    borderRadius: ST.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Check-in Timer',
                style: TextStyle(
                  fontFamily: 'Rockwell',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: ST.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alert contacts if you don\'t check in within this time.',
                style: TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ...options.map((opt) => InkWell(
                onTap: () => setS(() => selected = opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? ST.primaryFixed
                        : ST.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == opt
                          ? ST.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontFamily: 'Bernard MT Condensed',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: selected == opt
                              ? ST.primary
                              : ST.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (selected == opt)
                        const Icon(Icons.check_circle,
                            color: ST.primary, size: 18),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ST.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: ST.radiusFull),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAutoDeleteSheet(BuildContext context) {
    final options = ['Off', 'After 1 hour', 'After 24 hours', 'After 7 days'];
    String selected = 'After 24 hours';
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ST.outlineVariant,
                    borderRadius: ST.radiusFull,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Chat Auto-Delete',
                style: TextStyle(
                  fontFamily: 'Rockwell',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: ST.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Messages will be permanently erased after the selected time.',
                style: TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              ...options.map((opt) => InkWell(
                onTap: () => setS(() => selected = opt),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected == opt
                        ? ST.primaryFixed
                        : ST.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == opt
                          ? ST.primary
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt,
                        style: TextStyle(
                          fontFamily: 'Bernard MT Condensed',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: selected == opt
                              ? ST.primary
                              : ST.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (selected == opt)
                        const Icon(Icons.check_circle,
                            color: ST.primary, size: 18),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ST.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: ST.radiusFull),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Bernard MT Condensed',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: ST.outlineVariant,
                borderRadius: ST.radiusFull,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: ST.primaryFixed,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.shield_outlined,
                  color: ST.primary, size: 28),
            ),
            const SizedBox(height: 12),
            const Text(
              'SafeText',
              style: TextStyle(
                fontFamily: 'Rockwell',
                fontWeight: FontWeight.w700,
                fontSize: 26,
                color: ST.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 1.0.0 • Build 100',
              style: TextStyle(fontSize: 13, color: ST.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            _aboutRow('Privacy Policy', Icons.privacy_tip_outlined),
            _aboutRow('Terms of Service', Icons.description_outlined),
            _aboutRow('Open Source Licenses', Icons.code_outlined),
            _aboutRow('Contact Support', Icons.mail_outline),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ST.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: ST.onSurfaceVariant, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Bernard MT Condensed',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: ST.onSurface,
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right,
              color: ST.onSurfaceVariant, size: 18),
        ],
      ),
    );
  }
}
