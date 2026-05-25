import 'dart:async';
import 'dart:math' show cos, sqrt, atan2, sin, pi;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class JourneyStateNotifier extends ChangeNotifier {
  static final JourneyStateNotifier _instance = JourneyStateNotifier._internal();
  factory JourneyStateNotifier() => _instance;
  JourneyStateNotifier._internal();

  bool _isActive = false;
  String? _destinationName;
  LatLng? _currentPosition;
  LatLng? _destinationLocation;
  List<LatLng> _points = [];
  double _progress = 0.0;
  int _minutesRemaining = 0;
  int _navIndex = 0;
  List<int> _navHistory = [0];
  Map<String, dynamic>? _pendingRoute;
  int _checkInRemainingSeconds = -1;
  bool _isShared = false;
  double _distanceRemaining = 0.0;
  bool _isSelf = true;
  String? _userName;
  StreamSubscription<Position>? _positionSubscription;

  bool get isActive => _isActive;
  bool get isShared => _isShared;
  bool get isSelf => _isSelf;
  String? get userName => _userName;
  String? get destinationName => _destinationName;
  LatLng? get currentPosition => _currentPosition;
  LatLng? get destinationLocation => _destinationLocation;
  List<LatLng> get points => _points;
  double get progress => _progress;
  int get minutesRemaining => _minutesRemaining;
  double get distanceRemaining => _distanceRemaining;
  int get navIndex => _navIndex;
  List<int> get navHistory => _navHistory;
  Map<String, dynamic>? get pendingRoute => _pendingRoute;
  int get checkInRemainingSeconds => _checkInRemainingSeconds;

  void updateCheckInRemaining(int seconds) {
    _checkInRemainingSeconds = seconds;
    notifyListeners();
  }

  void setNavIndex(int index) {
    if (_navHistory.isEmpty || _navHistory.last != index) {
      _navHistory.add(index);
    }
    _navIndex = index;
    notifyListeners();
  }

  bool popNav() {
    if (_navHistory.length > 1) {
      _navHistory.removeLast();
      _navIndex = _navHistory.last;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setPendingRoute(LatLng location, String name) {
    _pendingRoute = {'location': location, 'name': name};
    setNavIndex(2); // Auto-switch to Map tab (Index 2)
  }

  void clearPendingRoute() {
    _pendingRoute = null;
    notifyListeners();
  }

  void startJourney({
    required String destinationName,
    required LatLng destinationLocation,
    required LatLng startPosition,
    List<LatLng> points = const [],
    bool isSelf = true,
    String? userName,
  }) {
    _isActive = true;
    _isSelf = isSelf;
    _userName = userName;
    _destinationName = destinationName;
    _destinationLocation = destinationLocation;
    _currentPosition = startPosition;
    _points = points;
    
    _calculateMetrics();

    // Start background tracking for self
    if (_isSelf) {
      _startTracking();
    }
    
    notifyListeners();
  }

  void _startTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      updatePosition(LatLng(position.latitude, position.longitude));
    });
  }

  void updatePosition(LatLng position) {
    if (!_isActive) return;
    _currentPosition = position;
    _calculateMetrics();
    notifyListeners();
  }

  void _calculateMetrics() {
    if (_points.isEmpty || _currentPosition == null) {
       _progress = 0.05;
       _minutesRemaining = 15;
       return;
    }

    // Calculate total route distance
    double totalDist = 0;
    for (int i = 0; i < _points.length - 1; i++) {
      totalDist += _getDistance(_points[i], _points[i + 1]);
    }

    if (totalDist == 0) return;

    // Find the point on the polyline closest to the user
    double distTravelled = 0;
    double minDistToUser = double.infinity;
    double bestDistTravelled = 0;

    for (int i = 0; i < _points.length - 1; i++) {
      final p1 = _points[i];
      final p1Dist = _getDistance(p1, _currentPosition!);
      if (p1Dist < minDistToUser) {
        minDistToUser = p1Dist;
        bestDistTravelled = distTravelled;
      }
      distTravelled += _getDistance(p1, _points[i+1]);
    }

    _progress = (bestDistTravelled / totalDist).clamp(0.01, 0.99);
    
    // Simple ETA logic (avg driving speed 40km/h -> 1.5 mins per km)
    _distanceRemaining = (totalDist - bestDistTravelled).clamp(0, totalDist);
    _minutesRemaining = (_distanceRemaining * 1.5).ceil() + 1;

    // Check if arrived (within 100 meters)
    if (_destinationLocation != null) {
      double distToDest = _getDistance(_currentPosition!, _destinationLocation!);
      if (distToDest < 0.1) { // 100 meters
        debugPrint("Destination Reached! Stopping journey automatically.");
        stopJourney();
      }
    }
  }

  double _getDistance(LatLng p1, LatLng p2) {
    const double radius = 6371; // Earth radius in km
    final dLat = (p2.latitude - p1.latitude) * pi / 180;
    final dLon = (p2.longitude - p1.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1.latitude * pi / 180) * cos(p2.latitude * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c;
  }

  void setShared(bool value) {
    _isShared = value;
    notifyListeners();
  }

  void stopJourney() {
    _isActive = false;
    _isShared = false;
    _destinationName = null;
    _destinationLocation = null;
    _currentPosition = null;
    _points = [];
    _progress = 0.0;
    _minutesRemaining = 0;
    _distanceRemaining = 0.0;
    _checkInRemainingSeconds = -1;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    notifyListeners();
  }
}
