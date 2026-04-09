import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }


  static String get _apiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');

  static String get _orsApiKey => dotenv.get('ORS_API_KEY', fallback: '');

  static Future<List<Map<String, dynamic>>> getNearbyPlaces(
      LatLng location, String type, {int radius = 5000}) async {
    // 1. Try Google Legacy (Primary)
    final googleUrl = Uri.https('maps.googleapis.com', '/maps/api/place/nearbysearch/json', {
      'location': '${location.latitude},${location.longitude}',
      'radius': '$radius',
      'type': type,
      'key': _apiKey,
    });

    try {
      final response = await http.get(googleUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (results.isNotEmpty) {
          final mapped = results.map<Map<String, dynamic>>((place) => {
            'name': place['name'] ?? 'Unknown',
            'address': place['vicinity'] ?? '',
            'location': LatLng(place['geometry']['location']['lat'], place['geometry']['location']['lng']),
          }).toList();
          mapped.sort((a, b) {
            double distA = Geolocator.distanceBetween(location.latitude, location.longitude, a['location'].latitude, a['location'].longitude);
            double distB = Geolocator.distanceBetween(location.latitude, location.longitude, b['location'].latitude, b['location'].longitude);
            return distA.compareTo(distB);
          });
          return mapped;
        }
      }
    } catch (e) {
      debugPrint('Google Nearby failed: $e');
    }
    
    // 2. ORS Fallback for nearby (using POI API if needed, but for now we fallback to standard keyword search)
    return [];
  }

  static Future<List<Map<String, dynamic>>> searchNearbyPlacesByKeyword(
      LatLng location, String keyword, {int radius = 50000}) async {
    // 1. Try Google Legacy
    final googleUrl = Uri.https('maps.googleapis.com', '/maps/api/place/textsearch/json', {
      'query': keyword,
      'location': '${location.latitude},${location.longitude}',
      'radius': '$radius',
      'key': _apiKey,
    });

    try {
      final response = await http.get(googleUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['results'] ?? [];
        if (results.isNotEmpty) {
          final mapped = results.map<Map<String, dynamic>>((place) => {
            'id': place['place_id'],
            'name': place['name'] ?? '',
            'address': place['formatted_address'] ?? '',
            'location': LatLng(place['geometry']['location']['lat'], place['geometry']['location']['lng']),
          }).toList();
          mapped.sort((a, b) {
            double distA = Geolocator.distanceBetween(location.latitude, location.longitude, a['location'].latitude, a['location'].longitude);
            double distB = Geolocator.distanceBetween(location.latitude, location.longitude, b['location'].latitude, b['location'].longitude);
            return distA.compareTo(distB);
          });
          return mapped;
        }
      }
    } catch (e) {
      debugPrint('Google Search failed: $e');
    }

    // 2. ORS Geocode fallback
    if (_orsApiKey.isNotEmpty) {
      final orsUrl = Uri.https('api.openrouteservice.org', '/geocode/search', {
        'api_key': _orsApiKey,
        'text': keyword,
        'boundary.circle.lat': '${location.latitude}',
        'boundary.circle.lon': '${location.longitude}',
        'boundary.circle.radius': '50', // 50km
        'size': '10',
      });

      try {
        final response = await http.get(orsUrl);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List features = data['features'] ?? [];
          final mapped = features.map<Map<String, dynamic>>((f) {
            final coords = f['geometry']['coordinates'];
            return {
              'name': f['properties']['name'] ?? 'Place',
              'address': f['properties']['label'] ?? '',
              'location': LatLng(coords[1], coords[0]), // ORS is [lon, lat]
            };
          }).toList();
          mapped.sort((a, b) {
            double distA = Geolocator.distanceBetween(location.latitude, location.longitude, a['location'].latitude, a['location'].longitude);
            double distB = Geolocator.distanceBetween(location.latitude, location.longitude, b['location'].latitude, b['location'].longitude);
            return distA.compareTo(distB);
          });
          return mapped;
        }
      } catch (e) {
        debugPrint('ORS Search failed: $e');
      }
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> getAutocompleteSuggestions(
      LatLng location, String input) async {
    // 1. Try Google Legacy
    final googleUrl = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': input,
      'location': '${location.latitude},${location.longitude}',
      'radius': '50000',
      'key': _apiKey,
    });

    try {
      final response = await http.get(googleUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List predictions = data['predictions'] ?? [];
        if (predictions.isNotEmpty) {
          debugPrint('Google Autocomplete success: ${predictions.length} results');
          return predictions.map((p) => {
            'placeId': p['place_id'],
            'name': p['structured_formatting']?['main_text'] ?? p['description'],
            'address': p['structured_formatting']?['secondary_text'] ?? '',
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Google Autocomplete failed: $e');
    }

    // 2. ORS Autocomplete fallback
    if (_orsApiKey.isNotEmpty) {
      debugPrint('Triggering ORS Autocomplete fallback...');
      final orsUrl = Uri.https('api.openrouteservice.org', '/geocode/autocomplete', {
        'api_key': _orsApiKey,
        'text': input,
        'boundary.circle.lat': '${location.latitude}',
        'boundary.circle.lon': '${location.longitude}',
        'boundary.circle.radius': '50',
        'size': '10',
      });

      try {
        final response = await http.get(orsUrl);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List features = data['features'] ?? [];
          return features.map((f) {
            final coords = f['geometry']['coordinates'];
            return {
              'name': f['properties']['name'] ?? 'Place',
              'address': f['properties']['label'] ?? '',
              'location': LatLng(coords[1], coords[0]),
            };
          }).toList();
        }
      } catch (e) {
        debugPrint('ORS Autocomplete failed: $e');
      }
    }

    return [];
  }

  static Future<LatLng?> getPlaceDetails(String placeId) async {
    final googleUrl = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'geometry',
      'key': _apiKey,
    });

    try {
      final response = await http.get(googleUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc = data['result']?['geometry']?['location'];
        if (loc != null) {
          return LatLng(loc['lat'], loc['lng']);
        }
      }
    } catch (e) {
      debugPrint('Google Details failed: $e');
    }
    return null;
  }
}
