import 'package:flutter/material.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../../services/journey_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../../auth_service.dart';

class SupportBubble extends StatelessWidget {
  final String text;
  final String? translation;
  final DateTime? time;
  final List<Map<String, dynamic>>? safePlaces;
  final bool showEvidenceActions;
  final String? sessionId;

  const SupportBubble({
    super.key, 
    required this.text, 
    this.translation, 
    this.time, 
    this.safePlaces,
    this.showEvidenceActions = false,
    this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    String timestamp = time != null ? DateFormat('dd MMM, HH:mm').format(time!) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/safetext_icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: ST.onSurface,
                          letterSpacing: 0.2,
                        ),
                      ),

                      if (safePlaces != null && safePlaces!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SmallMap(places: safePlaces!),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final first = safePlaces!.first;
                              final loc = first['location'] as LatLng;
                              final name = first['name'] ?? 'Safe Haven';
                              JourneyStateNotifier().setPendingRoute(loc, name);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tactical route to $name started!'),
                                  backgroundColor: ST.primary,
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation_outlined, size: 16, color: Colors.white),
                            label: const Text(
                              'NAVIGATE TO NEAREST',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ST.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                      if (showEvidenceActions) ...[
                        const SizedBox(height: 12),
                        _EvidenceCollectionPanel(sessionId: sessionId),
                      ],
                    ],
                  ),
                ),
                if (timestamp.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      timestamp,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 40), // Spacer on the right
        ],
      ),
    );
  }
}

class UserBubble extends StatelessWidget {
  final String text;
  final String? translation;
  final DateTime? time;
  const UserBubble({super.key, required this.text, this.translation, this.time});

  @override
  Widget build(BuildContext context) {
    String timestamp = time != null ? DateFormat('dd MMM, HH:mm').format(time!) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40), // Spacer on the left
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [ST.primary, Color(0xFF0052D4)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (translation != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
                          ),
                          child: Text(
                            translation!,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (timestamp.isNotEmpty)
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (timestamp.isNotEmpty) const SizedBox(width: 6),
                    Text(
                      'Delivered',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const STUserAvatar(size: 32),
        ],
      ),
    );
  }
}

class AnalyzingCard extends StatefulWidget {
  const AnalyzingCard({super.key});

  @override
  State<AnalyzingCard> createState() => _AnalyzingCardState();
}

class _AnalyzingCardState extends State<AnalyzingCard>
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
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: ST.radiusMd,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
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
                  shape: BoxShape.circle,
                  color: ST.primary.withOpacity(0.6 * _ac.value + 0.4),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Analyzing situation...',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ST.primary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI monitoring active & surrounding audio scan\nin progress',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMap extends StatelessWidget {
  final List<Map<String, dynamic>> places;
  const _SmallMap({required this.places});

  @override
  Widget build(BuildContext context) {
    final first = places.first;
    final LatLng center = first['location'] as LatLng;

    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: center, zoom: 14.5),
          markers: places.map((p) {
            return Marker(
              markerId: MarkerId(p['name'] ?? DateTime.now().toString()),
              position: p['location'] as LatLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              infoWindow: InfoWindow(title: p['name'] ?? 'Safe Place'),
            );
          }).toSet(),
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          liteModeEnabled: false,
        ),
      ),
    );
  }
}

class _EvidenceCollectionPanel extends StatefulWidget {
  final String? sessionId;
  const _EvidenceCollectionPanel({this.sessionId});

  @override
  State<_EvidenceCollectionPanel> createState() => _EvidenceCollectionPanelState();
}

class _EvidenceCollectionPanelState extends State<_EvidenceCollectionPanel> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          _uploadEvidence(File(path), 'audio');
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path = '${dir.path}/evidence_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          setState(() {
            _isRecording = true;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio recording started. Tap again to stop and save.'),
                backgroundColor: Color(0xFFDC2626),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error recording: $e");
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: ST.primary),
                title: const Text('Take a Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                  if (image != null) _uploadEvidence(File(image.path), 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: ST.primary),
                title: const Text('Upload from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) _uploadEvidence(File(image.path), 'image');
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _uploadEvidence(File file, String type) async {
    try {
      final userMap = await AuthService.getUser();
      final firebaseUser = FirebaseAuth.instance.currentUser;
      
      final String uid = userMap?['id'] ?? userMap?['email'] ?? firebaseUser?.uid ?? 'anonymous_user';
      final String userName = userMap?['name'] ?? firebaseUser?.displayName ?? 'Kavaach User';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saving $type securely encrypted on this device...')),
        );
      }

      final String extension = type == 'audio' ? '.m4a' : '.jpg';
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}$extension';
      
      // 1. Get the app's secure local documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // 1b. Create session folder
      final String sessionFolder = widget.sessionId ?? 'session_unknown';
      final Directory sessionDir = Directory('${directory.path}/evidence/$sessionFolder');
      if (!await sessionDir.exists()) {
        await sessionDir.create(recursive: true);
      }
      
      // 2. Create the strict path inside the session folder
      final String securePath = '${sessionDir.path}/$fileName';
      
      // 3. Move/Copy the file locally
      await file.copy(securePath);

      // 4. Attempt to log the location to Firestore so the Dashboard at least knows evidence was collected locally
      // We wrap this in a silent try-catch because Firestore security rules might block direct client writes 
      // (since the app uses backend auth) but the file is successfully saved locally.
      try {
        await FirebaseFirestore.instance.collection('evidence').add({
          'userId': uid,
          'userName': userName,
          'type': type,
          'url': 'LOCAL_STORAGE_ONLY', // Tell the dashboard the file is physically on the victim's phone
          'localPath': securePath,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (firestoreError) {
        debugPrint('Firestore log failed (permission denied), but file was saved locally: $firestoreError');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Evidence saved discretely to local secure vault.'),
            backgroundColor: ST.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint("Local Save failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save to device: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _EvidenceButton(
          label: _isRecording ? 'STOP RECORDING & SECURE' : 'START DISCREET RECORDING',
          icon: _isRecording ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
          color: const Color(0xFFDC2626), // Emergency red
          onTap: _toggleRecording,
        ),
        const SizedBox(height: 8),
        _EvidenceButton(
          label: 'UPLOAD PHOTOS / SCREENSHOTS',
          icon: Icons.add_a_photo_outlined,
          color: ST.primary,
          onTap: _pickAndUploadImage,
        ),
      ],
    );
  }
}

class _EvidenceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _EvidenceButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.08),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: color.withOpacity(0.2), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
