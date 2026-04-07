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
  
  final Set<Marker> _allMarkers = {
    Marker(
      markerId: const MarkerId('colaba_police_station'),
      position: const LatLng(18.9067, 72.8147),
      infoWindow: const InfoWindow(
        title: 'Colaba Police Station',
        snippet: 'Type: POLICE | Contact: 022-22151493',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('azad_maidan_police_station'),
      position: const LatLng(18.9388, 72.8333),
      infoWindow: const InfoWindow(
        title: 'Azad Maidan Police Station',
        snippet: 'Type: POLICE | Contact: 022-22620697',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('agripada_police_station'),
      position: const LatLng(18.962, 72.8191),
      infoWindow: const InfoWindow(
        title: 'Agripada Police Station',
        snippet: 'Type: POLICE | Contact: 022-23078213',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('byculla_police_station'),
      position: const LatLng(18.9726, 72.8368),
      infoWindow: const InfoWindow(
        title: 'Byculla Police Station',
        snippet: 'Type: POLICE | Contact: 022-23027917',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('dadar_police_station'),
      position: const LatLng(19.0178, 72.8478),
      infoWindow: const InfoWindow(
        title: 'Dadar Police Station',
        snippet: 'Type: POLICE | Contact: 022-24323044',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('dharavi_police_station'),
      position: const LatLng(19.0387, 72.8536),
      infoWindow: const InfoWindow(
        title: 'Dharavi Police Station',
        snippet: 'Type: POLICE | Contact: 022-24015767',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('bandra_police_station'),
      position: const LatLng(19.054, 72.8393),
      infoWindow: const InfoWindow(
        title: 'Bandra Police Station',
        snippet: 'Type: POLICE | Contact: 022-26423021',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('andheri__east__police_station'),
      position: const LatLng(19.1136, 72.8697),
      infoWindow: const InfoWindow(
        title: 'Andheri (East) Police Station',
        snippet: 'Type: POLICE | Contact: 022-26831562',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('juhu_police_station'),
      position: const LatLng(19.1075, 72.8263),
      infoWindow: const InfoWindow(
        title: 'Juhu Police Station',
        snippet: 'Type: POLICE | Contact: 022-26715000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('malad__west__police_station'),
      position: const LatLng(19.1874, 72.8484),
      infoWindow: const InfoWindow(
        title: 'Malad (West) Police Station',
        snippet: 'Type: POLICE | Contact: 022-28821482',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('kandivali__west__police_station'),
      position: const LatLng(19.205, 72.8457),
      infoWindow: const InfoWindow(
        title: 'Kandivali (West) Police Station',
        snippet: 'Type: POLICE | Contact: 022-28012331',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('borivali_police_station'),
      position: const LatLng(19.2286, 72.8567),
      infoWindow: const InfoWindow(
        title: 'Borivali Police Station',
        snippet: 'Type: POLICE | Contact: 022-28092331',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('dahisar_police_station'),
      position: const LatLng(19.2183, 72.8697),
      infoWindow: const InfoWindow(
        title: 'Dahisar Police Station',
        snippet: 'Type: POLICE | Contact: 022-28284024',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('ghatkopar_police_station'),
      position: const LatLng(19.0863, 72.9076),
      infoWindow: const InfoWindow(
        title: 'Ghatkopar Police Station',
        snippet: 'Type: POLICE | Contact: 022-25012333',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('kurla_police_station'),
      position: const LatLng(19.0653, 72.8807),
      infoWindow: const InfoWindow(
        title: 'Kurla Police Station',
        snippet: 'Type: POLICE | Contact: 022-25237000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('worli_police_station'),
      position: const LatLng(19.0069, 72.8181),
      infoWindow: const InfoWindow(
        title: 'Worli Police Station',
        snippet: 'Type: POLICE | Contact: 022-24955626',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('cuffe_parade_police_station'),
      position: const LatLng(18.904, 72.8191),
      infoWindow: const InfoWindow(
        title: 'Cuffe Parade Police Station',
        snippet: 'Type: POLICE | Contact: 022-22163200',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('sion_police_station'),
      position: const LatLng(19.0416, 72.8615),
      infoWindow: const InfoWindow(
        title: 'Sion Police Station',
        snippet: 'Type: POLICE | Contact: 022-24074575',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('chembur_police_station'),
      position: const LatLng(19.0522, 72.9005),
      infoWindow: const InfoWindow(
        title: 'Chembur Police Station',
        snippet: 'Type: POLICE | Contact: 022-25229345',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('powai_police_station'),
      position: const LatLng(19.1197, 72.905),
      infoWindow: const InfoWindow(
        title: 'Powai Police Station',
        snippet: 'Type: POLICE | Contact: 022-25702690',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('women_s_helpline_control_room'),
      position: const LatLng(18.9388, 72.8351),
      infoWindow: const InfoWindow(
        title: 'Women\'s Helpline Control Room',
        snippet: 'Type: POLICE | Contact: 103',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ),
    Marker(
      markerId: const MarkerId('kem_hospital__parel_'),
      position: const LatLng(19.0013, 72.8413),
      infoWindow: const InfoWindow(
        title: 'KEM Hospital (Parel)',
        snippet: 'Type: HOSPITAL | Contact: 022-24107000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('sir_j_j__hospital__byculla_'),
      position: const LatLng(18.9627, 72.835),
      infoWindow: const InfoWindow(
        title: 'Sir J.J. Hospital (Byculla)',
        snippet: 'Type: HOSPITAL | Contact: 022-23735555',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('byl_nair_hospital__mumbai_central_'),
      position: const LatLng(18.9699, 72.8196),
      infoWindow: const InfoWindow(
        title: 'BYL Nair Hospital (Mumbai Central)',
        snippet: 'Type: HOSPITAL | Contact: 022-23027600',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('sion_hospital___ltmg__sion_'),
      position: const LatLng(19.0407, 72.8617),
      infoWindow: const InfoWindow(
        title: 'Sion Hospital - LTMG (Sion)',
        snippet: 'Type: HOSPITAL | Contact: 022-24076381',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('cooper_hospital__vile_parle_'),
      position: const LatLng(19.1075, 72.8381),
      infoWindow: const InfoWindow(
        title: 'Cooper Hospital (Vile Parle)',
        snippet: 'Type: HOSPITAL | Contact: 022-26207254',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('kasturba_hospital__chinchpokli_'),
      position: const LatLng(18.9726, 72.8305),
      infoWindow: const InfoWindow(
        title: 'Kasturba Hospital (Chinchpokli)',
        snippet: 'Type: HOSPITAL | Contact: 022-23081500',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('rajawadi_hospital__ghatkopar_east_'),
      position: const LatLng(19.0761, 72.912),
      infoWindow: const InfoWindow(
        title: 'Rajawadi Hospital (Ghatkopar East)',
        snippet: 'Type: HOSPITAL | Contact: 022-25018000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('bhabha_hospital__bandra_west_'),
      position: const LatLng(19.0607, 72.8362),
      infoWindow: const InfoWindow(
        title: 'Bhabha Hospital (Bandra West)',
        snippet: 'Type: HOSPITAL | Contact: 022-26402273',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('bhagwati_hospital__borivali_west_'),
      position: const LatLng(19.2313, 72.8503),
      infoWindow: const InfoWindow(
        title: 'Bhagwati Hospital (Borivali West)',
        snippet: 'Type: HOSPITAL | Contact: 022-28954747',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('gt_hospital__fort_'),
      position: const LatLng(18.9366, 72.8349),
      infoWindow: const InfoWindow(
        title: 'GT Hospital (Fort)',
        snippet: 'Type: HOSPITAL | Contact: 022-22621427',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('tata_memorial_hospital__parel_'),
      position: const LatLng(19.0041, 72.843),
      infoWindow: const InfoWindow(
        title: 'Tata Memorial Hospital (Parel)',
        snippet: 'Type: HOSPITAL | Contact: 022-24177000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('v_n__desai_hospital__santacruz_east_'),
      position: const LatLng(19.0822, 72.8559),
      infoWindow: const InfoWindow(
        title: 'V.N. Desai Hospital (Santacruz East)',
        snippet: 'Type: HOSPITAL | Contact: 022-26188080',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('trauma_care_centre___jogeshwari'),
      position: const LatLng(19.1378, 72.8494),
      infoWindow: const InfoWindow(
        title: 'Trauma Care Centre - Jogeshwari',
        snippet: 'Type: HOSPITAL | Contact: 022-26781234',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    ),
    Marker(
      markerId: const MarkerId('sneha_crisis_centre__santa_cruz_west_'),
      position: const LatLng(19.0822, 72.8386),
      infoWindow: const InfoWindow(
        title: 'SNEHA Crisis Centre (Santa Cruz West)',
        snippet: 'Type: SHELTER | Contact: 9892278287',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('shantighar_shelter_for_women__andheri_east_'),
      position: const LatLng(19.1162, 72.8727),
      infoWindow: const InfoWindow(
        title: 'Shantighar Shelter for Women (Andheri East)',
        snippet: 'Type: SHELTER | Contact: 022-28348400',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('urja_trust___shelter_for_homeless_women__dadar_east_'),
      position: const LatLng(19.0194, 72.8505),
      infoWindow: const InfoWindow(
        title: 'Urja Trust - Shelter for Homeless Women (Dadar East)',
        snippet: 'Type: SHELTER | Contact: 022-24125678',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('bapnu_ghar___women_in_distress__worli_'),
      position: const LatLng(19.0069, 72.8191),
      infoWindow: const InfoWindow(
        title: 'Bapnu Ghar - Women in Distress (Worli)',
        snippet: 'Type: SHELTER | Contact: 022-24950000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('apne_aap___women_empowerment__grant_road_'),
      position: const LatLng(18.964, 72.8178),
      infoWindow: const InfoWindow(
        title: 'Apne Aap - Women Empowerment (Grant Road)',
        snippet: 'Type: SHELTER | Contact: 022-23800000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('daya_sadan___society_of_helpers_of_mary__dharavi_'),
      position: const LatLng(19.0387, 72.8536),
      infoWindow: const InfoWindow(
        title: 'Daya Sadan - Society of Helpers of Mary (Dharavi)',
        snippet: 'Type: SHELTER | Contact: 022-24016780',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('kranti___girls_from_difficult_circumstances__kurla_east_'),
      position: const LatLng(19.0653, 72.8807),
      infoWindow: const InfoWindow(
        title: 'Kranti - Girls from Difficult Circumstances (Kurla East)',
        snippet: 'Type: SHELTER | Contact: 022-25236789',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('sparc_shelter__byculla_'),
      position: const LatLng(18.9726, 72.8368),
      infoWindow: const InfoWindow(
        title: 'SPARC Shelter (Byculla)',
        snippet: 'Type: SHELTER | Contact: 022-23026000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
    Marker(
      markerId: const MarkerId('salvation_army___bombay_central'),
      position: const LatLng(18.9699, 72.8225),
      infoWindow: const InfoWindow(
        title: 'Salvation Army - Bombay Central',
        snippet: 'Type: SHELTER | Contact: 022-23096000',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    ),
  };

  late Set<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _markers = Set.from(_allMarkers);
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

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
          if (_userPosition.latitude != 28.6139) {
            fetchPos = _userPosition;
          } else {
            rethrow; 
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _userPosition = fetchPos;
        });
      }
      
      // Map category to marker type keyword
      String matchType = '';
      if (category == 'Police Station') matchType = 'POLICE';
      else if (category == 'Hospital') matchType = 'HOSPITAL';
      else if (category == 'Safe Shelter') matchType = 'SHELTER';

      // Filter all curated markers by type
      List<Marker> filtered = _allMarkers.where((m) {
        return m.infoWindow.snippet?.contains('Type: $matchType') == true;
      }).toList();

      if (filtered.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _markers.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No $category found in local database.')),
          );
        }
        return;
      }

      // Calculate distances using Geolocator
      Marker? closest;
      double minDistance = double.infinity;

      for (var marker in filtered) {
        double dist = Geolocator.distanceBetween(
          fetchPos.latitude, 
          fetchPos.longitude, 
          marker.position.latitude, 
          marker.position.longitude
        );
        if (dist < minDistance) {
          minDistance = dist;
          closest = marker;
        }
      }

      if (mounted) {
        setState(() {
          _markers = Set.from(filtered);
          _isLoading = false;
        });

        if (closest != null) {
          _moveToLocation(closest.position);
          Future.delayed(const Duration(milliseconds: 500), () {
            _mapController?.showMarkerInfoWindow(closest!.markerId);
          });
          
          double kmDist = minDistance / 1000;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Closest $category is ${kmDist.toStringAsFixed(1)} km away')),
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
