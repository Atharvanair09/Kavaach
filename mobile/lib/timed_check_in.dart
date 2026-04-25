import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'services/emergency_contact_service.dart';
import 'auth_service.dart';

// ─── Notification plugin (top-level singleton) ────────────────────────────────
final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await _notificationsPlugin.initialize(initSettings);
  
  final androidPlugin = _notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  // Request standard notifications permission (Android 13+)
  await androidPlugin?.requestNotificationsPermission();
  
  // Request exact alarm permission (Android 14+)
  // Note: For Android 14+, users often need to grant this in system settings.
  // This call will help trigger the necessary system dialogue if possible.
  try {
     await androidPlugin?.requestExactAlarmsPermission();
  } catch (e) {
     debugPrint("Exact alarm request error: $e");
  }
}

Future<void> _scheduleCycleNotifications(DateTime endTime) async {
  // Clear previous ones
  await cancelCheckinNotifications();

  final milestones = [
    {'id': 101, 'offset': const Duration(minutes: 5), 'body': '⏳ 5 minutes until your next check-in!'},
    {'id': 102, 'offset': const Duration(minutes: 2), 'body': '⚠️ Confirm you\'re safe — 2 minutes left!'},
    {'id': 103, 'offset': const Duration(minutes: 1), 'body': '🚨 1 minute left! Open the app now.'},
    {'id': 104, 'offset': const Duration(seconds: 30), 'body': '‼️ 30 seconds! SOS fires if you don\'t respond.'},
  ];

  for (final m in milestones) {
    final scheduledDate = endTime.subtract(m['offset'] as Duration);
    
    // Safety: Only schedule if the milestone is at least 2 seconds in the future
    // to avoid "instant" notifications when the timer is already past or near the mark.
    if (scheduledDate.isBefore(DateTime.now().add(const Duration(seconds: 2)))) continue;

    try {
      await _notificationsPlugin.zonedSchedule(
        m['id'] as int,
        'Kavaach – Check-In',
        m['body'] as String,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'checkin_channel',
            'Check-In Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Fallback for devices where EXACT_ALARM is not permitted
      await _notificationsPlugin.zonedSchedule(
        m['id'] as int,
        'Kavaach – Check-In',
        m['body'] as String,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'checkin_channel',
            'Check-In Reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Final SOS Notification (at 0:00)
  if (endTime.isAfter(DateTime.now())) {
    try {
      await _notificationsPlugin.zonedSchedule(
        105,
        'Kavaach – Check-In Missed',
        'ℹ️ Your check-in window closed. Sending a missed alert to your circle.',
        tz.TZDateTime.from(endTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sos_channel',
            'Check-In Status',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            color: Color(0xFF10B981),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      await _notificationsPlugin.zonedSchedule(
        105,
        'Kavaach – Check-In Missed',
        'ℹ️ Your check-in window closed. Sending a missed alert to your circle.',
        tz.TZDateTime.from(endTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sos_channel',
            'Check-In Status',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            color: Color(0xFF10B981),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexact,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }
}

Future<void> cancelCheckinNotifications() async {
  for (int id in [101, 102, 103, 104, 105]) {
    await _notificationsPlugin.cancel(id);
  }
}

// ─── SharedPreferences Keys ───────────────────────────────────────────────────
class _Keys {
  static const cycleEndMs         = 'ci_cycle_end_ms';
  static const cycleTotalSeconds  = 'ci_cycle_total_seconds';
  static const isLooping          = 'ci_is_looping';
  static const confirmedThisCycle = 'ci_confirmed_this_cycle';
  // notification sentinels (track which milestones already fired this cycle)
  static const notif5m  = 'ci_notif_5m';
  static const notif2m  = 'ci_notif_2m';
  static const notif1m  = 'ci_notif_1m';
  static const notif30s = 'ci_notif_30s';
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class TimedCheckInScreen extends StatefulWidget {
  const TimedCheckInScreen({Key? key}) : super(key: key);

  @override
  State<TimedCheckInScreen> createState() => _TimedCheckInScreenState();
}

class _TimedCheckInScreenState extends State<TimedCheckInScreen>
    with WidgetsBindingObserver {
  static const int _confirmWindowSeconds = 120; // last 2 minutes

  Timer? _ticker;

  // Reactive state
  bool  _isLooping          = false;
  bool  _confirmedThisCycle = false;
  int   _remainingSeconds   = 0;
  int   _totalSeconds       = 1800; // default 30 minutes
  bool  _isSosFiring        = false;

  // SOS Press State
  bool _isSosPressing = false;
  double _sosProgress = 0.0;
  Timer? _sosPressTimer;

  // Location State
  bool _showMap = false;
  Position? _currentPosition;
  String _currentAddress = 'Fetching nearby location...';
  GoogleMapController? _mapController;

  // Derived
  bool get _isInConfirmWindow => _remainingSeconds <= _confirmWindowSeconds && _remainingSeconds > 0;
  bool get _canConfirm        => _isInConfirmWindow && !_confirmedThisCycle;
  double get _progress => _totalSeconds > 0 ? (_remainingSeconds / _totalSeconds).clamp(0.0, 1.0) : 0.0;
  String get _formattedRemaining {
    final duration = Duration(seconds: _remainingSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initNotifications();
    _restore();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      // 1. Check/Request Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      // 2. Get Last Known (Instant)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        setState(() => _currentPosition = lastPos);
        _updateAddress(lastPos);
      } else {
        // 2b. Try Lowest accuracy if no last known (very fast)
        final fastPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.lowest,
        );
        if (mounted) {
          setState(() => _currentPosition = fastPos);
          _updateAddress(fastPos);
        }
      }

      // 3. Get Current (Background Refinement)
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).then((pos) {
        if (mounted) {
          setState(() => _currentPosition = pos);
          _updateAddress(pos);
        }
      });
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _updateAddress(Position pos) async {
    try {
      // Use a timeout to prevent hanging on weak connections
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude, pos.longitude
      ).timeout(const Duration(seconds: 10));

      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        
        final name = p.name ?? ''; // Often building name
        final street = p.street ?? ''; 
        final road = p.thoroughfare ?? '';
        final area = p.subLocality ?? '';
        
        // Strategy: Try to get "Building/Name, Road/Area"
        String main = name.isNotEmpty ? name : street;
        String secondary = road.isNotEmpty ? road : area;
        
        String addr = '';
        if (main.isNotEmpty && secondary.isNotEmpty && main != secondary) {
          addr = '$main, $secondary';
        } else {
          addr = main.isNotEmpty ? main : (secondary.isNotEmpty ? secondary : 'Current Location');
        }
        
        setState(() => _currentAddress = addr);
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _sosPressTimer?.cancel();
    super.dispose();
  }

  // ─── SOS Press Logic ────────────────────────────────────────────────────────

  void _onSosLongPressStart(LongPressStartDetails details) {
    if (_isSosFiring) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isSosPressing = true;
      _sosProgress = 0.0;
    });

    _sosPressTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted) return;
      setState(() {
        _sosProgress += 0.01; // Exactly 3 seconds for full fill (100 ticks * 30ms)
      });

      if ((_sosProgress * 100).toInt() % 10 == 0) {
        HapticFeedback.selectionClick();
      }

      if (_sosProgress >= 1.0) {
        _cancelSosPress();
        _ticker?.cancel();
        _fireSOS();
      }
    });
  }

  void _onSosLongPressEnd(LongPressEndDetails details) {
    _cancelSosPress();
  }

  void _cancelSosPress() {
    _sosPressTimer?.cancel();
    if (mounted) {
      setState(() {
        _isSosPressing = false;
        _sosProgress = 0.0;
      });
    }
  }

  // ─── Persistence helpers ────────────────────────────────────────────────────

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> _restore() async {
    final prefs = await _prefs;
    final looping = prefs.getBool(_Keys.isLooping) ?? false;
    // Read configured duration from settings (default 30 min)
    final configuredTotal = prefs.getInt(_Keys.cycleTotalSeconds) ?? 1800;

    if (!looping) {
      if (mounted) setState(() { _isLooping = false; _totalSeconds = configuredTotal; });
      return;
    }

    final endMs    = prefs.getInt(_Keys.cycleEndMs) ?? 0;
    final total    = prefs.getInt(_Keys.cycleTotalSeconds) ?? configuredTotal;
    final confirmed = prefs.getBool(_Keys.confirmedThisCycle) ?? false;
    final remaining = DateTime.fromMillisecondsSinceEpoch(endMs)
        .difference(DateTime.now())
        .inSeconds;

    if (remaining <= 0) {
      // Cycle expired while app was closed
      await _onCycleExpired(prefs, confirmedSafe: confirmed, autoRestart: true);
    } else {
      if (mounted) {
        setState(() {
          _isLooping          = true;
          _totalSeconds       = total;
          _remainingSeconds   = remaining;
          _confirmedThisCycle = confirmed;
        });
      }
      _startTicker();
    }
  }

  Future<void> _refresh() async {
    if (!_isLooping) return;
    final prefs = await _prefs;
    final endMs  = prefs.getInt(_Keys.cycleEndMs) ?? 0;
    final remaining = DateTime.fromMillisecondsSinceEpoch(endMs)
        .difference(DateTime.now())
        .inSeconds;
    if (remaining <= 0) {
      _ticker?.cancel();
      final confirmed = prefs.getBool(_Keys.confirmedThisCycle) ?? false;
      await _onCycleExpired(prefs, confirmedSafe: confirmed, autoRestart: true);
    } else {
      if (mounted) setState(() => _remainingSeconds = remaining);
    }
  }

  Future<void> _saveCycle(DateTime endTime, int totalSeconds, bool looping) async {
    final prefs = await _prefs;
    await prefs.setInt(_Keys.cycleEndMs, endTime.millisecondsSinceEpoch);
    await prefs.setInt(_Keys.cycleTotalSeconds, totalSeconds);
    await prefs.setBool(_Keys.isLooping, looping);
    await prefs.setBool(_Keys.confirmedThisCycle, false);
    // Reset notification sentinels
    await prefs.setBool(_Keys.notif5m,  false);
    await prefs.setBool(_Keys.notif2m,  false);
    await prefs.setBool(_Keys.notif1m,  false);
    await prefs.setBool(_Keys.notif30s, false);
    
    // Schedule native notifications
    await _scheduleCycleNotifications(endTime);
  }

  Future<void> _clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_Keys.cycleEndMs);
    // DO NOT remove cycleTotalSeconds — we want to persist the user's preferred duration
    await prefs.setBool(_Keys.isLooping, false);
    await prefs.remove(_Keys.confirmedThisCycle);
    await prefs.remove(_Keys.notif5m);
    await prefs.remove(_Keys.notif2m);
    await prefs.remove(_Keys.notif1m);
    await prefs.remove(_Keys.notif30s);
  }

  // ─── Ticker ─────────────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (!mounted) return;
    final prefs = await _prefs;
    final endMs = prefs.getInt(_Keys.cycleEndMs) ?? 0;
    final remaining = DateTime.fromMillisecondsSinceEpoch(endMs)
        .difference(DateTime.now())
        .inSeconds;
    final confirmed = prefs.getBool(_Keys.confirmedThisCycle) ?? false;

    if (remaining <= 0) {
      _ticker?.cancel();
      final confirmed = prefs.getBool(_Keys.confirmedThisCycle) ?? false;
      await _onCycleExpired(prefs, confirmedSafe: confirmed, autoRestart: true);
      return;
    }

    if (mounted) {
      setState(() {
        _remainingSeconds   = remaining;
        _confirmedThisCycle = confirmed;
      });
    }
  }

  // ─── Cycle management ───────────────────────────────────────────────────────

  Future<void> _onCycleExpired(
    SharedPreferences prefs, {
    required bool confirmedSafe,
    required bool autoRestart,
  }) async {
    if (!confirmedSafe) {
      // User did not confirm — notify of missed check-in
      await _notificationsPlugin.show(
        105,
        'Kavaach – Check-In Missed',
        'ℹ️ Your check-in window closed. Sending a missed alert to your circle.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'sos_channel',
            'Check-In Status',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            color: Color(0xFF10B981), // Green color for missed check-in
          ),
        ),
      );
      _fireMissedCheckIn(); // Log as missed check-in (not full SOS)
    }

    if (autoRestart) {
      final total = prefs.getInt(_Keys.cycleTotalSeconds) ?? _totalSeconds;
      final newEnd = DateTime.now().add(Duration(seconds: total));
      await _saveCycle(newEnd, total, true);
      // _saveCycle handles notification scheduling

      if (mounted) {
        setState(() {
          _remainingSeconds   = total;
          _totalSeconds       = total;
          _confirmedThisCycle = false;
        });
      }
      _startTicker();
    }
  }

  void _startLoop(int durationSeconds) async {
    // Safety check for duration
    if (durationSeconds < 30) durationSeconds = 1800; // Default to 30m if invalid (too small)

    try {
      final endTime = DateTime.now().add(Duration(seconds: durationSeconds));
      await _saveCycle(endTime, durationSeconds, true);

      if (mounted) {
        setState(() {
          _isLooping          = true;
          _totalSeconds       = durationSeconds;
          _remainingSeconds   = durationSeconds;
          _confirmedThisCycle = false;
        });
      }
      _startTicker();
    } catch (e) {
      debugPrint("Loop start error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start timer: $e')),
        );
      }
    }
  }

  Future<void> _startLoopFromSettings() async {
    final prefs = await _prefs;
    final configured = prefs.getInt(_Keys.cycleTotalSeconds) ?? 1800;
    _startLoop(configured);
  }

  void _stopLoop() async {
    _ticker?.cancel();
    await _clearAll();
    await cancelCheckinNotifications();
    if (mounted) {
      setState(() {
        _isLooping          = false;
        _remainingSeconds   = 0;
        _confirmedThisCycle = false;
      });
      Navigator.pop(context);
    }
  }

  Future<void> _confirmSafe() async {
    if (!_canConfirm) return;
    final prefs = await _prefs;
    await prefs.setBool(_Keys.confirmedThisCycle, true);
    if (mounted) setState(() => _confirmedThisCycle = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Safety confirmed for this cycle!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ─── SOS ────────────────────────────────────────────────────────────────────

  Future<void> _fireSOS() async {
    if (_isSosFiring) return;
    if (mounted) setState(() => _isSosFiring = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      await EmergencyContactService.sendSOS(
        lat: position.latitude,
        lng: position.longitude,
        message: 'SOS ALERT: High priority help requested from the device.',
        type: 'emergency', // Red on dashboard
      );
      if (mounted) _showSosDialog('Emergency contacts alerted with your live location.');
    } catch (_) {
      if (mounted) {
        _showSosDialog('SOS trigger failed. Call 100 immediately if you are in danger.');
      }
    } finally {
      if (mounted) setState(() => _isSosFiring = false);
    }
  }

  Future<void> _fireMissedCheckIn() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      await EmergencyContactService.sendSOS(
        lat: position.latitude,
        lng: position.longitude,
        message: 'Timed Check-In MISSED: User did not confirm safety at the scheduled interval.',
        type: 'missed_checkin', // Green on dashboard
      );
    } catch (e) {
      debugPrint("Missed check-in log failed: $e");
    }
  }

  void _showSosDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('SOS TRIGGERED',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CLOSE',
                style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // ─── Duration picker ────────────────────────────────────────────────────────

  void _showDurationPicker() {
    int selectedMinutes = 60;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text('Set Cycle Duration',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A))),
              const SizedBox(height: 6),
              Text('Timer loops automatically. Confirm your safety\nduring the last 2 minutes of each cycle.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13, color: const Color(0xFF64748B))),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12, runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [15, 30, 60, 90, 120].map((mins) {
                  final sel = selectedMinutes == mins;
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedMinutes = mins),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: sel ? const Color(0xFF1D4ED8) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text('$mins min',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15, fontWeight: FontWeight.w700,
                            color: sel ? Colors.white : const Color(0xFF475569))),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () { Navigator.pop(ctx); _startLoop(selectedMinutes * 60); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D4ED8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withOpacity(0.3),
                        blurRadius: 16, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Center(
                    child: Text('Start Looping Timer',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF6FF), Colors.white],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                _buildHeader(),
                const SizedBox(height: 24),
                Text('Are you safe?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 40, fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A), letterSpacing: -1)),
                const SizedBox(height: 12),
                Text('Checking in on your evening walk',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600)),
                const SizedBox(height: 40),

                // ── "I Need Help" row ──
                GestureDetector(
                  onLongPressStart: _onSosLongPressStart,
                  onLongPressEnd: _onSosLongPressEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE2E8F0).withOpacity(0.5),
                          blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Stack(
                        children: [
                          // Red fill sweeping left → right while pressing
                          if (_isSosPressing)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: _sosProgress.clamp(0.0, 1.0),
                                  child: Container(
                                    color: const Color(0xFF991B1B).withOpacity(0.3),
                                  ),
                                ),
                              ),
                            ),
                          Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFEE2E2), shape: BoxShape.circle),
                                child: const Center(child: Icon(Icons.emergency,
                                    color: Color(0xFFE11D48), size: 24)),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Text('I Need Help',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFE11D48),
                                      fontSize: 18, fontWeight: FontWeight.w800)),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  color: Color(0xFFFDA4AF), size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Primary action button ──
                _buildPrimaryButton(),

                const SizedBox(height: 52),

                // ── Timer ring ──
                _buildTimerRing(),

                const SizedBox(height: 16),
                Text(
                  _isLooping
                      ? (_isInConfirmWindow
                          ? 'CONFIRM WINDOW OPEN'
                          : 'TIME UNTIL NEXT CHECK-IN')
                      : 'NO ACTIVE TIMER',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: _isInConfirmWindow ? const Color(0xFF10B981) : const Color(0xFF64748B),
                    letterSpacing: 1.5),
                ),

                const SizedBox(height: 40), 
                _buildBottomRow(),
                const SizedBox(height: 16),
                _buildLocationCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getUser(),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        final name = userData?['name']?.split(' ').first ?? 'User';
        final photo = userData?['picture'] ?? userData?['profile_photo'] ?? userData?['photoURL'];

        String greeting = 'Good Day';
        final hour = DateTime.now().hour;
        if (hour < 12) greeting = 'Good Morning';
        else if (hour < 17) greeting = 'Good Afternoon';
        else greeting = 'Good Evening';

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500)),
                Text(name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A), letterSpacing: -1)),
              ],
            ),
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE2E8F0), 
                    blurRadius: 10, offset: const Offset(0, 4)
                  )
                ],
              ),
              child: CircleAvatar(
                backgroundImage: photo != null ? NetworkImage(photo) : null,
                backgroundColor: const Color(0xFFEFF6FF),
                child: photo == null 
                  ? const Icon(Icons.person, color: Color(0xFF2563EB)) 
                  : null,
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildPrimaryButton() {
    if (!_isLooping) {
      // Start state — reads duration from settings
      return GestureDetector(
        onTap: _startLoopFromSettings,
        child: _styledButton(
          color: const Color(0xFF1D4ED8),
          label: 'Start Check-In Loop',
          subLabel: 'Duration set in Settings',
        ),
      );
    }

    if (_confirmedThisCycle) {
      // Already confirmed this cycle — show "Stop" only
      return GestureDetector(
        onTap: _stopLoop,
        child: _styledButton(
          color: const Color(0xFF475569),
          label: 'Stop Monitoring',
          subLabel: '✅ Safety confirmed this cycle',
        ),
      );
    }

    if (_isInConfirmWindow) {
      // Window is open — show "I'm Safe"
      return Column(
        children: [
          GestureDetector(
            onTap: _confirmSafe,
            child: _styledButton(
              color: const Color(0xFF10B981),
              label: "I'm Safe",
              subLabel: 'Tap to confirm safety',
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _stopLoop,
            child: Text(
              'Stop Check-In Loop',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }

    // Window not yet open — disabled "Safe" button but active "Stop"
    return Column(
      children: [
        Opacity(
          opacity: 0.45,
          child: AbsorbPointer(
            child: _styledButton(
              color: const Color(0xFF1D4ED8),
              label: "I'm Safe",
              subLabel: 'Available in the last 2 minutes',
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _stopLoop,
          child: Text(
            'Stop Check-In Loop',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFFEF4444),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _styledButton({
    required Color color,
    required String label,
    required String subLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(subLabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white.withOpacity(0.85),
                fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTimerRing() {
    final ringColor = _remainingSeconds <= 30 && _isLooping
        ? const Color(0xFFEF4444)
        : _isInConfirmWindow
            ? const Color(0xFF10B981)
            : const Color(0xFF2563EB);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120, height: 120,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(ringColor),
            ),
          ),
          Text(
            _isLooping ? _formattedRemaining : '--:--:--',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22, fontWeight: FontWeight.w800, color: ringColor,
              letterSpacing: -0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D4ED8), 
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withOpacity(0.3), 
            blurRadius: 16, offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        children: [
          Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.navigation, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Current Location',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(_currentAddress,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showMap = !_showMap),
                  child: Text(_showMap ? 'Hide Map' : 'View Map',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.fastOutSlowIn,
              child: _showMap
                  ? Column(
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white12,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: _currentPosition == null
                                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                : GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      zoom: 15,
                                    ),
                                    onMapCreated: (ctrl) => _mapController = ctrl,
                                    markers: {
                                      Marker(
                                        markerId: const MarkerId('current'),
                                        position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                      ),
                                    },
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    liteModeEnabled: true,
                                  ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        // Guardian Status
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFFF1F5F9), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Guardian Status',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Row(children: [
                CircleAvatar(radius: 12, backgroundColor: Colors.grey[200],
                    backgroundImage: const NetworkImage('https://ui-avatars.com/api/?name=A&background=0D8ABC&color=fff')),
                Transform.translate(offset: const Offset(-8, 0),
                  child: CircleAvatar(radius: 12, backgroundColor: Colors.grey[300],
                      backgroundImage: const NetworkImage('https://ui-avatars.com/api/?name=S&background=DF2935&color=fff'))),
                Transform.translate(offset: const Offset(-16, 0),
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                    child: Center(child: Text('+2',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF475569)))))),
              ]),
              const SizedBox(height: 10),
              Text(
                _isLooping ? 'Notified if no response\nin $_formattedRemaining' : 'No timer active',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF94A3B8), fontSize: 11, height: 1.4)),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        // Signal & Battery
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFFF1F5F9), blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Signal & Battery',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              const Row(children: [
                Icon(Icons.signal_cellular_alt, color: Color(0xFF10B981), size: 20),
                SizedBox(width: 8),
                Icon(Icons.battery_full, color: Color(0xFF2563EB), size: 20),
              ]),
              const SizedBox(height: 10),
              Text('Encrypted\nConnection',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF94A3B8), fontSize: 11, height: 1.4)),
            ]),
          ),
        ),
      ],
    );
  }
}
