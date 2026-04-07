import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/st_style.dart';
import '../../widgets/st_widgets.dart';
import '../../services/location_service.dart';

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
  
  Set<Marker> _markers = {
Marker(
  markerId: const MarkerId('dahisar_ps_east'),
  position: const LatLng(19.2183, 72.8697), // S.V. Road, Near Union Bank, Dahisar East
  infoWindow: const InfoWindow(
    title: 'Dahisar Police Station (East)',
    snippet: 'S.V. Road, Near Union Bank, Dahisar East - 400068',
  ),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
),

// 2. M.H.B. Colony Police Station (West)
Marker(
  markerId: const MarkerId('mhb_colony_ps'),
  position: const LatLng(19.2201, 72.8582), // Dr. Vasudevak Shrungi Marg, Dahisar West
  infoWindow: const InfoWindow(
    title: 'M.H.B. Colony Police Station',
    snippet: 'Dr. Vasudevak Shrungi Marg, Dahisar West',
  ),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
),

// 3. ACP Office - Dahisar Division (within Dahisar PS compound)
Marker(
  markerId: const MarkerId('acp_dahisar_division'),
  position: const LatLng(19.2178, 72.8700), // 1st Floor, Dahisar PS Compound, S.V. Road
  infoWindow: const InfoWindow(
    title: 'ACP Office – Dahisar Division',
    snippet: '1st Floor, Dahisar Police Station Compound, S.V. Road',
  ),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
),

// 4. DCP Zone 12 Office (Shailendra Nagar, near Dahisar PS)
Marker(
  markerId: const MarkerId('dcp_zone_12'),
  position: const LatLng(19.2190, 72.8695), // Shailendra Nagar, SV Road, Dahisar East
  infoWindow: const InfoWindow(
    title: 'DCP Office – Zone 12',
    snippet: 'Shailendra Nagar, SV Road, Dahisar East - 400068',
  ),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
),

// 5. Borivali Police Station (closest neighboring station, ~2km south)
Marker(
  markerId: const MarkerId('borivali_ps'),
  position: const LatLng(19.2286, 72.8567), // Opp. Borivali Railway Station, S.V. Road
  infoWindow: const InfoWindow(
    title: 'Borivali Police Station',
    snippet: 'Opp. Borivali Railway Station, S.V. Road, Borivali West - 400092',
  ),
  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
),
  };

  @override
  void initState() {
    super.initState();
    _determinePosition();
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
        _isLoading = true;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(_userPosition));
      _fetchAllSafeHavens(_userPosition);
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
      _markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: place['location'],
          infoWindow: InfoWindow(
            title: place['name'],
            snippet: place['address'],
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
        ),
      );
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
      // 0. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      // 1. Position Fetch: Use last known first, then try fresh lock with longer timeout (8s)
      Position? currentPos = await Geolocator.getLastKnownPosition();
      LatLng fetchPos;

      if (currentPos != null) {
        fetchPos = LatLng(currentPos.latitude, currentPos.longitude);
      } else {
        try {
          currentPos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 8),
          );
          fetchPos = LatLng(currentPos.latitude, currentPos.longitude);
        } catch (_) {
          // If fresh fetch fails (e.g. timeout), fallback to existing state if it's not default Delhi
          if (_userPosition.latitude != 28.6139) {
            fetchPos = _userPosition;
          } else {
            rethrow; // Truly unable to get any location
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _userPosition = fetchPos;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLng(_userPosition));
      }
      
      // 2. Adaptive Radius Search: Start at 2km, then 5km, 10km, and finally 20km
      List<Map<String, dynamic>> places = [];
      List<int> radii = [2000, 5000, 10000, 20000];
      int finalRadius = 2000;

      for (int radius in radii) {
        finalRadius = radius;
        if (category == 'Police Station') {
          places = await LocationService.getNearbyPlaces(fetchPos, 'police', radius: radius);
        } else if (category == 'Hospital') {
          places = await LocationService.getNearbyPlaces(fetchPos, 'hospital', radius: radius);
        } else if (category == 'Safe Shelter') {
          places = await LocationService.searchNearbyPlacesByKeyword(fetchPos, 'safe shelter', radius: radius);
          if (places.isEmpty) {
            places = await LocationService.searchNearbyPlacesByKeyword(fetchPos, 'women shelter', radius: radius);
          }
        }
        
        if (places.isNotEmpty) break;
      }

      if (mounted) {
        setState(() {
          _markers.clear();
          String closestMarkerId = '';
          
          for (int i = 0; i < places.length; i++) {
            var place = places[i];
            double hue = BitmapDescriptor.hueRed;
            if (category == 'Police Station') hue = BitmapDescriptor.hueBlue;
            if (category == 'Safe Shelter') hue = BitmapDescriptor.hueGreen;

            final markerId = place['name'] + place['location'].toString();
            if (i == 0) closestMarkerId = markerId;

            _markers.add(
              Marker(
                markerId: MarkerId(markerId),
                position: place['location'],
                infoWindow: InfoWindow(
                  title: place['name'],
                  snippet: place['address'],
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(hue),
              ),
            );
          }
          _isLoading = false;
          
          if (places.isNotEmpty) {
            _moveToLocation(places.first['location']);
            // Show info window for closest location
            Future.delayed(const Duration(milliseconds: 500), () {
              _mapController?.showMarkerInfoWindow(MarkerId(closestMarkerId));
            });
            
            if (finalRadius > 2000) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No $category within 2km. Expanded search to ${finalRadius ~/ 1000}km.')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No $category found within 20km range.')),
            );
          }
        });
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
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          
          // 2. Loading Overlay
          if (_isLoading)
            Positioned.fill(
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
            bottom: MediaQuery.of(context).size.height * 0.45,
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
          DraggableScrollableSheet(
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
                                  onTap: () => _showCategoryMarkers('Police Station'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryCard(
                                  icon: Icons.shield_outlined,
                                  title: 'Shelter',
                                  subtitle: 'SAFE HAVEN',
                                  color: ST.tertiary,
                                  onTap: () => _showCategoryMarkers('Safe Shelter'),
                                ),
                                const SizedBox(width: 12),
                                _CategoryCard(
                                  icon: Icons.local_hospital_outlined,
                                  title: 'Hospital',
                                  subtitle: 'MEDICAL',
                                  color: ST.secondary,
                                  onTap: () => _showCategoryMarkers('Hospital'),
                                ),
                              ],
                            ),
                            
                            // Bottom Action Area
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
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
                                          const Text(
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
                                  const SizedBox(height: 14),
                                  Text(
                                    'YOUR CURRENT COORDINATES ARE SHARED WITH TRUSTED CONTACTS',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1,
                                      color: ST.onSurfaceVariant.withOpacity(0.5),
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
        ],
      ),
    );
  }

  // Silver Map Style JSON
  final String _mapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "elementType": "labels.icon",
      "stylers": [{"visibility": "off"}]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#616161"}]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [{"color": "#f5f5f5"}]
    },
    {
      "featureType": "administrative.land_parcel",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#bdbdbd"}]
    },
    {
      "featureType": "poi",
      "elementType": "geometry",
      "stylers": [{"color": "#eeeeee"}]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [{"color": "#e5e5e5"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [{"color": "#ffffff"}]
    },
    {
      "featureType": "road.arterial",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#757575"}]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [{"color": "#c9c9c9"}]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [{"color": "#9e9e9e"}]
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

  const _CategoryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: ST.surfaceContainerLow,
            borderRadius: ST.radiusSm,
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Bernard MT Condensed',
                  fontWeight: FontWeight.w800,
                  color: ST.onSurface,
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
                  color: ST.onSurfaceVariant.withOpacity(0.7),
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
