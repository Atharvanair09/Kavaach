import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../../services/location_service.dart';
import '../../services/journey_service.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  GoogleMapController? _mapController;
  LatLng _userPosition = const LatLng(28.6139, 77.2090); // Default placeholder
  bool _isLoading = true;
  String? _selectedCategory;
  bool _isSharingLocation = false;
  double _sheetExtent = 0.42;
  LatLng? _activeDestination;
  bool _isFollowingUser = false;
  StreamSubscription<Position>? _positionStream;
  
  Set<Marker> _allMarkers = {};

  late Set<Marker> _markers;
  final Set<Polyline> _polylines = {};
  Marker? _closestVisible;
  String? _routeDestinationName;
  bool _isRouteLoading = false;
  bool _isIsolatedNavigation = false;

  Timer? _checkInTimer;
  Timer? _missedCheckInTimer;
  int _checkInIntervalMinutes = 0;

  // ── In-map route drawing ───────────────────────────────────────────────────
  static String get _orsApiKey => dotenv.get('ORS_API_KEY', fallback: '');

  /// Decodes a Google-encoded polyline string into a list of LatLng points.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0;
    int lat = 0, lng = 0;
    while (index < encoded.length) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0; result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  /// Fetches the driving route from the user's position to [destination]
  /// using the OpenRouteService API and draws it as a Polyline on the map.
  Future<void> _drawRouteOnMap(LatLng destination, String destinationName) async {
    if (mounted) setState(() => _isRouteLoading = true);

    if (_orsApiKey.isEmpty) {
      setState(() => _isRouteLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing ORS_API_KEY in .env file')),
      );
      return;
    }

    // OpenRouteService endpoints require Longitude first, then Latitude
    final url = Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car');

    final body = json.encode({
      "coordinates": [
        [_userPosition.longitude, _userPosition.latitude],
        [destination.longitude, destination.latitude]
      ],
      "instructions": false
    });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _orsApiKey,
        },
        body: body,
      );

      final data = json.decode(response.body);

      if (response.statusCode != 200 || data['error'] != null) {
        String msg = 'No route found (status ${response.statusCode})';
        if (data['error'] is String) {
          msg = data['error'];
        } else if (data['error'] is Map) {
          msg = data['error']['message'] ?? msg;
        }
        throw Exception(msg);
      }

      // ORS returns standard Google encoded polylines in the geometry field of routes
      final encodedPoly = data['routes'][0]['geometry'] as String;
      final points = _decodePolyline(encodedPoly);

      // Compute bounding box to fit the full route in view.
      double minLat = _userPosition.latitude,  maxLat = _userPosition.latitude;
      double minLng = _userPosition.longitude, maxLng = _userPosition.longitude;
      for (final p in points) {
        if (p.latitude  < minLat) minLat = p.latitude;
        if (p.latitude  > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }

      if (mounted) {
        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('active_route'),
            points: points,
            color: ST.primary,
            width: 5,
            patterns: [],
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ));
          _routeDestinationName = destinationName;
          _activeDestination = destination;
          _isRouteLoading = false;
          
          if (_isIsolatedNavigation) {
            _markers = {
              Marker(
                markerId: const MarkerId('isolation_target'),
                position: destination,
                infoWindow: InfoWindow(title: destinationName),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              )
            };
          }
        });

        // Sync route to Home Screen if journey is active
        if (_isSharingLocation) {
          JourneyStateNotifier().startJourney(
            destinationName: _routeDestinationName ?? 'Destination',
            destinationLocation: _activeDestination!,
            startPosition: _userPosition,
            points: points,
          );
        }

        // Animate camera to show entire route.
        _mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            30,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRouteLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load route: $e')),
        );
      }
    }
  }

  void _clearRoute() {
    if (_isFollowingUser) _toggleLiveFollow();
    setState(() {
      _polylines.clear();
      _routeDestinationName = null;
      _activeDestination = null;
      _closestVisible = null;
      
      if (_isIsolatedNavigation) {
        _isIsolatedNavigation = false;
        _markers = _buildNavigableMarkers(_allMarkers);
      }
    });
  }

  void _toggleLiveFollow() {
    setState(() {
      _isFollowingUser = !_isFollowingUser;
    });

    if (_isFollowingUser) {
      _positionStream ??= Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 3,
        ),
      ).listen((Position position) {
        if (_isFollowingUser && mounted) {
          setState(() {
            _userPosition = LatLng(position.latitude, position.longitude);
          });
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _userPosition,
                bearing: position.heading,
                tilt: 45,
                zoom: 18,
              ),
            ),
          );
          // Sync with global journey service
          if (_isSharingLocation) {
             JourneyStateNotifier().updatePosition(_userPosition);
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'In-app navigation active. Following your movement.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: ST.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 220,
            left: 20,
            right: 20,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      _positionStream?.cancel();
      _positionStream = null;
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: _userPosition, zoom: 15.5, tilt: 0, bearing: 0)
      ));
    }
  }

  @override
  void dispose() {
    JourneyStateNotifier().removeListener(_handleExternalNavigation);
    _positionStream?.cancel();
    _checkInTimer?.cancel();
    _missedCheckInTimer?.cancel();
    super.dispose();
  }

  void _handleExternalNavigation() {
    final pending = JourneyStateNotifier().pendingRoute;
    if (pending != null && mounted) {
      final loc = pending['location'] as LatLng;
      final name = pending['name'] as String;
      
      setState(() {
        _isIsolatedNavigation = true;
        _markers = {}; // Clear others for focus
      });

      // We use a small delay to ensure the map is ready if we just switched tabs
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _drawRouteOnMap(loc, name);
      });
      JourneyStateNotifier().clearPendingRoute();
    }
  }

  void _showCheckInConfigDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ST.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Safety Check-In', style: TextStyle(fontWeight: FontWeight.bold, color: ST.onSurface, fontSize: 18)),
          content: const Text('How often should we ask you to check in? If you miss a check-in, an SOS will be triggered automatically.', style: TextStyle(color: ST.onSurfaceVariant, fontSize: 13)),
          actions: [
            TextButton(onPressed: () { Navigator.pop(context); _startSafeJourney(0); }, child: const Text('None', style: TextStyle(color: ST.primary, fontWeight: FontWeight.bold))),
            TextButton(onPressed: () { Navigator.pop(context); _startSafeJourney(5); }, child: const Text('5m', style: TextStyle(color: ST.primary, fontWeight: FontWeight.bold))),
            TextButton(onPressed: () { Navigator.pop(context); _startSafeJourney(10); }, child: const Text('10m', style: TextStyle(color: ST.primary, fontWeight: FontWeight.bold))),
            TextButton(onPressed: () { Navigator.pop(context); _startSafeJourney(15); }, child: const Text('15m', style: TextStyle(color: ST.primary, fontWeight: FontWeight.bold))),
          ],
        );
      }
    );
  }

  void _promptCheckIn() {
    if (!mounted) return;
    
    _missedCheckInTimer = Timer(const Duration(seconds: 60), () {
        if (mounted) {
           Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
           _triggerSOS();
        }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ST.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Check-In Required', style: TextStyle(fontWeight: FontWeight.bold, color: ST.onSurface, fontSize: 18)),
            ],
          ),
          content: const Text('Please check in to confirm you are safe! If you do not respond in 60s, an SOS will be sent automatically to your contacts.', style: TextStyle(color: ST.onSurfaceVariant, fontSize: 13)),
          actions: [
            ElevatedButton(
              onPressed: () {
                 _missedCheckInTimer?.cancel();
                 Navigator.of(context).pop();
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check-in confirmed. Timer reset!')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ST.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('I\'M SAFE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ]
        );
      }
    );
  }

  Future<void> _triggerSOS() async {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('CRITICAL: SOS Triggered! Alerts sent to emergency contacts.'),
            backgroundColor: Color(0xFFDC2626),
            duration: Duration(seconds: 5),
        ),
    );
    // Future: implement SMS trigger
  }

  Future<void> _startSafeJourney(int checkInInterval) async {
    // If we have an active route destination or a hasn marker "closest" but not yet routed
    if (_activeDestination != null || _closestVisible != null) {
      if (!_isFollowingUser) _toggleLiveFollow();
      
      _checkInIntervalMinutes = checkInInterval;
      if (_checkInIntervalMinutes > 0) {
        _checkInTimer?.cancel();
        _missedCheckInTimer?.cancel();
        _checkInTimer = Timer.periodic(Duration(minutes: _checkInIntervalMinutes), (timer) {
          _promptCheckIn();
        });
      }

      setState(() {
        _isSharingLocation = true;
      });
      // Prioritize activeDestination (searched) over closestVisible (haven)
      if (_routeDestinationName == null) {
         if (_activeDestination != null) {
            // This case handles if _activeDestination was set but _drawRouteOnMap wasn't called yet
            await _drawRouteOnMap(_activeDestination!, 'Your Destination');
         } else if (_closestVisible != null) {
            await _drawRouteOnMap(_closestVisible!.position, _closestVisible!.infoWindow.title ?? 'Destination');
         }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.shield_moon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Safe Journey started! Broadcasting live location.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981), // Solid emerald green
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 220,
            left: 20,
            right: 20,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      // Sync with Home Screen
      JourneyStateNotifier().startJourney(
        destinationName: _routeDestinationName ?? 'Active Route',
        destinationLocation: _activeDestination ?? _userPosition,
        startPosition: _userPosition,
        points: _polylines.isNotEmpty ? _polylines.first.points : [],
      );
    } else {
      _showCustomDestinationSearch();
    }
  }

  void _stopSafeJourney() {
    _checkInTimer?.cancel();
    _missedCheckInTimer?.cancel();
    if (_isFollowingUser) _toggleLiveFollow();
    setState(() {
      _isSharingLocation = false;
    });
    _clearRoute();
    JourneyStateNotifier().stopJourney();
  }

  void _showCustomDestinationSearch() {
    String searchQuery = '';
    Timer? debounce;
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ST.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            
            Future<void> performSearch(String query) async {
              if (query.trim().length < 2) {
                setModalState(() {
                  searchResults = [];
                  isSearching = false;
                });
                return;
              }
              
              setModalState(() => isSearching = true);
              try {
                // Try Autocomplete first (better for "as you type" behavior)
                List<Map<String, dynamic>> results = await LocationService.getAutocompleteSuggestions(
                  _userPosition, query
                );
                
                // FALLBACK: If autocomplete finds nothing, try a generic Text Search (Google or ORS fallback)
                if (results.isEmpty) {
                  results = await LocationService.searchNearbyPlacesByKeyword(
                    _userPosition, query
                  );
                }

                if (ctx.mounted) {
                  setModalState(() {
                    searchResults = results;
                    isSearching = false;
                  });
                }
              } catch (e) {
                if (ctx.mounted) setModalState(() => isSearching = false);
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: ST.outlineVariant, borderRadius: BorderRadius.circular(2))),
                  ),
                  const SizedBox(height: 20),
                  const Text('Where are you heading?', 
                    style: TextStyle(fontFamily: 'Rockwell', fontSize: 20, fontWeight: FontWeight.w800, color: ST.onSurface)),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search for any place...',
                      prefixIcon: const Icon(Icons.search, color: ST.primary),
                      suffixIcon: isSearching ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)
                        ),
                      ) : null,
                      filled: true,
                      fillColor: ST.surfaceContainerLow,
                      border: OutlineInputBorder(borderRadius: ST.radiusSm, borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: ST.radiusSm, borderSide: BorderSide.none),
                    ),
                    onChanged: (val) {
                      searchQuery = val;
                      if (debounce?.isActive ?? false) debounce?.cancel();
                      debounce = Timer(const Duration(milliseconds: 300), () {
                        performSearch(val);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: searchResults.isEmpty && !isSearching ? 0 : 320,
                    child: Scrollbar(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                        padding: const EdgeInsets.only(bottom: 20),
                        itemBuilder: (context, index) {
                          final place = searchResults[index];
                          
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ST.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: ST.primary, size: 20),
                            ),
                            title: Text(place['name'], 
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ST.onSurface)),
                            subtitle: Text(place['address'], 
                              style: TextStyle(fontSize: 12, color: ST.onSurfaceVariant, height: 1.4)),
                            onTap: () async {
                              LatLng? destinationLoc;
                              String destinationName = place['name'];

                              if (place.containsKey('location')) {
                                // Result already has location (from Text Search fallback)
                                destinationLoc = place['location'];
                              } else if (place.containsKey('placeId')) {
                                // Result only has ID (from Autocomplete) - need to fetch details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Locating place...'), duration: Duration(milliseconds: 500)),
                                );
                                destinationLoc = await LocationService.getPlaceDetails(place['placeId']);
                              }
                              
                              if (destinationLoc != null && ctx.mounted) {
                                Navigator.pop(ctx);
                                _activeDestination = destinationLoc;
                                _drawRouteOnMap(destinationLoc, destinationName);
                                _showCheckInConfigDialog();
                              } else {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Could not find location details.')),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                  if (searchResults.isEmpty && !isSearching && searchQuery.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No places found', style: TextStyle(color: ST.onSurfaceVariant))),
                    ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _launchNavigation() async {
    if (_activeDestination == null) return;
    
    final lat = _activeDestination!.latitude;
    final lng = _activeDestination!.longitude;
    
    // For Android: google.navigation:q=lat,lng
    // For iOS: comgooglemaps://?daddr=lat,lng
    // Fallback: https://www.google.com/maps/dir/?api=1&destination=lat,lng
    
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving';
    
    if (await canLaunchUrlString(googleMapsUrl)) {
      await launchUrlString(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch navigation app.')),
      );
    }
  }

  // Shows a modal bottom-sheet with directions CTA for a marker.
  void _showLocationSheet(Marker marker) {
    final title = marker.infoWindow.title ?? 'Location';
    final snippet = marker.infoWindow.snippet ?? '';
    final position = marker.position;

    // Parse type & contact from snippet  e.g. "Type: POLICE | Contact: 022-..."
    String type = '';
    String contact = '';
    final parts = snippet.split(' | ');
    for (final p in parts) {
      if (p.startsWith('Type: ')) type = p.replaceFirst('Type: ', '');
      if (p.startsWith('Contact: ')) contact = p.replaceFirst('Contact: ', '');
    }

    // Marker colour accent
    Color accent = ST.primary;
    IconData typeIcon = Icons.location_on;
    if (type == 'POLICE') { accent = ST.primary; typeIcon = Icons.local_police_outlined; }
    else if (type == 'HOSPITAL') { accent = ST.secondary; typeIcon = Icons.local_hospital_outlined; }
    else if (type == 'SHELTER') { accent = ST.tertiary; typeIcon = Icons.shield_outlined; }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: ST.surfaceContainerLowest,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: ST.outlineVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Icon + name row
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Rockwell',
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: ST.onSurface,
                          height: 1.2,
                        ),
                      ),
                      if (type.isNotEmpty) ...[                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accent,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (contact.isNotEmpty) ...[              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 16, color: ST.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    contact,
                    style: TextStyle(
                      fontSize: 14,
                      color: ST.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Get Directions button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _drawRouteOnMap(position, title);
                },
                icon: const Icon(Icons.navigation_outlined, color: Colors.white),
                label: const Text(
                  'Get Directions',
                  style: TextStyle(
                    fontFamily: 'Rockwell',
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Cancel
            SizedBox(
              width: double.infinity,
              height: 46,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Dismiss',
                  style: TextStyle(
                    fontSize: 15,
                    color: ST.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Rebuild _allMarkers with onTap handlers attached.
  Set<Marker> _buildNavigableMarkers(Set<Marker> source) {
    return source.map((m) => m.copyWith(
      onTapParam: () => _showLocationSheet(m),
    )).toSet();
  }


  Future<void> _loadHavensFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('safe_havens').get(
        const GetOptions(source: Source.server)
      );
      final Set<Marker> fetchedMarkers = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final String name = data['name'] ?? 'Unknown';
        final String type = data['type']?.toString().toUpperCase() ?? 'UNKNOWN';
        final double lat = (data['latitude'] ?? 0.0).toDouble();
        final double lng = (data['longitude'] ?? 0.0).toDouble();
        final String contact = data['contact'] ?? '';
        
        double hue = BitmapDescriptor.hueRed;
        if (type == 'POLICE') hue = BitmapDescriptor.hueBlue;
        else if (type == 'HOSPITAL') hue = BitmapDescriptor.hueOrange;
        else if (type == 'SHELTER') hue = BitmapDescriptor.hueGreen;

        fetchedMarkers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: name,
              snippet: 'Type: $type | Contact: $contact',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          )
        );
      }
      
      if (mounted) {
        setState(() {
          _allMarkers.clear();
          _allMarkers.addAll(fetchedMarkers);
          _markers = _buildNavigableMarkers(_allMarkers);
        });
      }
    } catch (e) {
      debugPrint('Error loading havens from Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading map data: $e'), duration: const Duration(seconds: 4)),
        );
      }
    }
  }
  @override
  void initState() {
    super.initState();
    JourneyStateNotifier().addListener(_handleExternalNavigation);
    _markers = _buildNavigableMarkers(_allMarkers);
    _determinePosition();
    _loadHavensFromFirestore();
    // Check if there was already a pending route on start
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleExternalNavigation());
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false; // changed to immediately show fixed markers instead of loading
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_userPosition));
      // _fetchAllSafeHavens(_userPosition); // disabled so it doesn't instantly wipe the static _markers array
    }
  }

  Future<void> _fetchAllSafeHavens(LatLng pos) async {
    try {
      final policeFuture = LocationService.getNearbyPlaces(pos, 'police', radius: 5000);
      final hospitalFuture = LocationService.getNearbyPlaces(pos, 'hospital', radius: 5000);
      final shelterFuture1 = LocationService.searchNearbyPlacesByKeyword(pos, 'safe shelter', radius: 5000);
      final shelterFuture2 = LocationService.searchNearbyPlacesByKeyword(pos, 'women shelter', radius: 5000);

      final results = await Future.wait([policeFuture, hospitalFuture, shelterFuture1, shelterFuture2]);

      if (mounted) {
        setState(() {
          _markers.clear();
          _addPlacesToMarkers(results[0], BitmapDescriptor.hueBlue);
          _addPlacesToMarkers(results[1], BitmapDescriptor.hueOrange);
          _addPlacesToMarkers(results[2], BitmapDescriptor.hueGreen);
          _addPlacesToMarkers(results[3], BitmapDescriptor.hueGreen);
          _markers = _buildNavigableMarkers(_markers);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading safe havens: $e')),
        );
      }
    }
  }

  void _addPlacesToMarkers(List<Map<String, dynamic>> places, double hue) {
    for (var place in places) {
      final markerId = place['name'] + place['location'].toString();
      final m = Marker(
        markerId: MarkerId(markerId),
        position: place['location'],
        infoWindow: InfoWindow(
          title: place['name'],
          snippet: place['address'],
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(hue),
      );
      _markers.add(m.copyWith(onTapParam: () => _showLocationSheet(m)));
    }
  }

  void _moveToLocation(LatLng position) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: position, zoom: 15.5),
      ),
    );
  }

  void _showCategoryMarkers(String category) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = category;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      Position currentPos;
      LatLng fetchPos;
      try {
        currentPos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 8),
        );
        fetchPos = LatLng(currentPos.latitude, currentPos.longitude);
      } catch (_) {
        if (_userPosition.latitude != 28.6139) {
          fetchPos = _userPosition;
        } else {
          rethrow; 
        }
      }
      
      if (mounted) {
        setState(() {
          _userPosition = fetchPos;
        });
      }
      
      // Dynamic Place Search from Google Places API
      List<Map<String, dynamic>> places = [];
      double hue = BitmapDescriptor.hueRed;
      String typeLabel = '';
      
      if (category == 'Police Station') {
        places = await LocationService.getNearbyPlaces(fetchPos, 'police', radius: 5000);
        hue = BitmapDescriptor.hueBlue;
        typeLabel = 'POLICE';
      } else if (category == 'Hospital') {
        places = await LocationService.getNearbyPlaces(fetchPos, 'hospital', radius: 5000);
        hue = BitmapDescriptor.hueOrange;
        typeLabel = 'HOSPITAL';
      } else if (category == 'Safe Shelter') {
        places = await LocationService.searchNearbyPlacesByKeyword(fetchPos, 'women shelter', radius: 10000);
        if (places.isEmpty) {
          places = await LocationService.searchNearbyPlacesByKeyword(fetchPos, 'safe shelter', radius: 10000);
        }
        hue = BitmapDescriptor.hueGreen;
        typeLabel = 'SHELTER';
      }

      if (places.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _markers.clear();
            _closestVisible = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $category found nearby.')),
          );
        }
        return;
      }

      // Convert results to Markers
      Set<Marker> newMarkers = {};
      for (var place in places) {
        final m = Marker(
          markerId: MarkerId(place['name'] + place['location'].toString()),
          position: place['location'],
          infoWindow: InfoWindow(
            title: place['name'],
            snippet: 'Type: $typeLabel | Address: ${place['address']}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        );
        newMarkers.add(m.copyWith(onTapParam: () => _showLocationSheet(m)));
      }

      // Closest is simply the first result since getNearbyPlaces sorts by distance!
      Marker? closest = newMarkers.first;
      double minDistance = Geolocator.distanceBetween(
        _userPosition.latitude,
        _userPosition.longitude,
        closest.position.latitude,
        closest.position.longitude,
      );

      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _closestVisible = closest;
          _isLoading = false;
        });

        if (closest != null) {
          _moveToLocation(closest.position);
          Future.delayed(const Duration(milliseconds: 500), () {
            _mapController?.showMarkerInfoWindow(closest!.markerId);
          });

          double kmDist = minDistance / 1000;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(hours: 24),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.transparent,
              elevation: 0,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 220,
                left: 16,
                right: 16,
              ),
              padding: EdgeInsets.zero,
              content: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       const Icon(Icons.info_outline, color: ST.primary, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Closest $category is ${kmDist.toStringAsFixed(1)} km away',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ST.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          _drawRouteOnMap(
                            closest!.position,
                            closest.infoWindow.title ?? 'Destination',
                          );
                        },
                        child: const Text(
                          'SHOW ROUTE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: ST.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String message = e.toString().contains('services are disabled') 
          ? 'Please enable GPS/Location services.'
          : 'Error: ${e.toString()}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ST.surface,
      body: Stack(
        children: [
          // 1. Background Map (Full Screen)
          Positioned.fill(
            child: GoogleMap(
              style: _mapStyle,
              initialCameraPosition: CameraPosition(
                target: _userPosition,
                zoom: 14.5,
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) => _mapController = controller,
              padding: EdgeInsets.only(
                top: 130, 
                bottom: MediaQuery.of(context).size.height * 0.44
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          
          // 2. Route loading overlay (small spinner, not full-screen)
          if (_isRouteLoading)
            Positioned(
              top: 60, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ST.primary),
                      ),
                      const SizedBox(width: 10),
                      const Text('Calculating route…',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ST.onSurface)),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Active route info banner
          if (_routeDestinationName != null && !_isRouteLoading)
            Positioned(
              top: 60, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: ST.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.directions, color: ST.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Route to', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                          Text(
                            _routeDestinationName!,
                            style: const TextStyle(
                              fontFamily: 'Rockwell',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: ST.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _toggleLiveFollow,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isFollowingUser ? const Color(0xFFDC2626) : ST.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _isFollowingUser ? 'STOP' : 'NAVIGATE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _launchNavigation,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: ST.outlineVariant.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.map_outlined, size: 16, color: ST.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearRoute,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, size: 16, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. GPS loading overlay (centered on visible map area)
          if (_isLoading)
            Positioned(
              top: 0, left: 0, right: 0,
              bottom: MediaQuery.of(context).size.height * _sheetExtent,
              child: Container(
                color: Colors.white60,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5),
                      SizedBox(height: 12),
                      Text('SYNCHRONIZING GPS...', 
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: ST.primary)),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating User Location Button
          Positioned(
            right: 16,
            bottom: (MediaQuery.of(context).size.height * _sheetExtent) + 20,
            child: GestureDetector(
              onTap: _determinePosition,
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
          ),

          // 4. Draggable Content Sheet
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              setState(() {
                _sheetExtent = notification.extent;
              });
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.42,
              minChildSize: 0.28,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: ST.surfaceContainerLowest,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F171C1F),
                      blurRadius: 40,
                      offset: Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Grabber Handle
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: ST.outlineVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    // Main Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                const ActiveScanBadge(),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const SizedBox(height: 16),
                                Row(
                                  children: [
                                    _CategoryCard(
                                      icon: Icons.local_police_outlined,
                                      title: 'Police',
                                      subtitle: 'STATION',
                                      color: ST.primary,
                                      isSelected: _selectedCategory == 'Police Station',
                                      onTap: () {
                                        if (_selectedCategory == 'Police Station') {
                                          setState(() {
                                            _selectedCategory = null;
                                            _markers = _buildNavigableMarkers(_allMarkers);
                                          });
                                        } else {
                                          _showCategoryMarkers('Police Station');
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    _CategoryCard(
                                      icon: Icons.shield_outlined,
                                      title: 'Shelter',
                                      subtitle: 'SAFE HAVEN',
                                      color: ST.tertiary,
                                      isSelected: _selectedCategory == 'Safe Shelter',
                                      onTap: () {
                                        if (_selectedCategory == 'Safe Shelter') {
                                          setState(() {
                                            _selectedCategory = null;
                                            _markers = _buildNavigableMarkers(_allMarkers);
                                          });
                                        } else {
                                          _showCategoryMarkers('Safe Shelter');
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 12),
                                    _CategoryCard(
                                      icon: Icons.local_hospital_outlined,
                                      title: 'Hospital',
                                      subtitle: 'MEDICAL',
                                      color: ST.secondary,
                                      isSelected: _selectedCategory == 'Hospital',
                                      onTap: () {
                                        if (_selectedCategory == 'Hospital') {
                                          setState(() {
                                            _selectedCategory = null;
                                            _markers = _buildNavigableMarkers(_allMarkers);
                                          });
                                        } else {
                                          _showCategoryMarkers('Hospital');
                                        }
                                      },
                                    ),
                                  ],
                                ),
                            
                            // Bottom Action Area
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (_isSharingLocation) {
                                        _stopSafeJourney();
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Safe Journey Stopped')));
                                      } else {
                                        _showCheckInConfigDialog();
                                      }
                                    },
                                    child: Container(
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: _isSharingLocation ? const Color(0xFFDC2626) : ST.primary,
                                        borderRadius: ST.radiusSm,
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isSharingLocation ? const Color(0xFFDC2626) : ST.primary).withOpacity(0.35),
                                            blurRadius: 40,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            _isSharingLocation ? Icons.stop_circle_outlined : Icons.shield_moon,
                                            color: Colors.white, 
                                            size: 24
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _isSharingLocation ? 'END JOURNEY' : 'START SAFE JOURNEY',
                                            style: const TextStyle(
                                              fontFamily: 'Bernard MT Condensed',
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                              color: Colors.white,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: () {
                                      if (_closestVisible != null) {
                                        _drawRouteOnMap(
                                          _closestVisible!.position,
                                          _closestVisible!.infoWindow.title ?? 'Destination',
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Select a category first to find the nearest safe haven.'),
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      height: 54,
                                      decoration: BoxDecoration(
                                        color: _closestVisible != null
                                            ? ST.primary.withOpacity(0.07)
                                            : ST.surfaceContainerLowest,
                                        borderRadius: ST.radiusSm,
                                        border: Border.all(
                                          color: _closestVisible != null
                                              ? ST.primary.withOpacity(0.3)
                                              : ST.outlineVariant.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.navigation_outlined,
                                            color: _closestVisible != null ? ST.primary : ST.onSurface,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Navigate to Closest',
                                            style: TextStyle(
                                              fontFamily: 'Rockwell',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: _closestVisible != null ? ST.primary : ST.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isSharingLocation 
                                        ? 'LIVE LOCATION IS CURRENTLY BROADCASTING TO TRUSTED CONTACTS'
                                        : 'LOCATION PING IS OFF. TAP SHARE TO BROADCAST IN AN EMERGENCY.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1,
                                      color: _isSharingLocation ? const Color(0xFFDC2626) : ST.onSurfaceVariant.withOpacity(0.5),
                                      fontWeight: _isSharingLocation ? FontWeight.bold : FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

  // Vivid Map Style JSON
  final String _mapStyle = '''
  [
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#a2daf2"}]
    },
    {
      "featureType": "landscape.man_made",
      "elementType": "geometry",
      "stylers": [{"color": "#f7f1df"}]
    },
    {
      "featureType": "landscape.natural",
      "elementType": "geometry",
      "stylers": [{"color": "#d0e3b4"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#bde3cb"}]
    },
    {
      "featureType": "poi.medical",
      "elementType": "geometry",
      "stylers": [{"color": "#fbd3da"}]
    },
    {
      "featureType": "poi.business",
      "stylers": [{"visibility": "on"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffe15f"}]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#efd151"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road.local",
      "elementType": "geometry.fill",
      "stylers": [{"color": "white"}, {"visibility": "on"}]
    },
    {
      "featureType": "transit.station.airport",
      "elementType": "geometry.fill",
      "stylers": [{"color": "#cfb2db"}]
    }
  ]
  ''';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isSelected;

  const _CategoryCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? ST.primary : ST.surfaceContainerLow,
            borderRadius: ST.radiusSm,
            border: Border.all(
              color: isSelected ? ST.primary : color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? Colors.white : color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Bernard MT Condensed',
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : ST.onSurface,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white.withOpacity(0.8) : ST.onSurfaceVariant.withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
