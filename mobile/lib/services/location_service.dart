import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

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

  static Future<List<Map<String, dynamic>>> getNearbyPlaces(
      LatLng location, String type, {int radius = 5000}) async {
    final String url = 'https://places.googleapis.com/v1/places:searchNearby';

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location',
    };

    final body = json.encode({
      "includedTypes": [type],
      "maxResultCount": 20,
      "locationRestriction": {
        "circle": {
          "center": {
            "latitude": location.latitude,
            "longitude": location.longitude
          },
          "radius": radius.toDouble()
        }
      }
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['places'] ?? [];
        
        List<Map<String, dynamic>> places = results.map((place) {
          final locObj = place['location'] ?? {};
          final lat = (locObj['latitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (locObj['longitude'] as num?)?.toDouble() ?? 0.0;
          final placeLoc = LatLng(lat, lng);
          
          final distance = Geolocator.distanceBetween(
            location.latitude, location.longitude, lat, lng
          );

          return {
            'name': place['displayName']?['text'] ?? '',
            'address': place['formattedAddress'] ?? '',
            'location': placeLoc,
            'distance': distance,
          };
        }).toList();

        places.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        return places;
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception fetching places: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> searchNearbyPlacesByKeyword(
      LatLng location, String keyword, {int radius = 5000}) async {
    final String url = 'https://places.googleapis.com/v1/places:searchText';

    final headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location',
    };

    final body = json.encode({
      "textQuery": keyword,
      "maxResultCount": 20,
      "locationBias": {
        "circle": {
          "center": {
            "latitude": location.latitude,
            "longitude": location.longitude
          },
          "radius": radius.toDouble()
        }
      }
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List results = data['places'] ?? [];
        
        List<Map<String, dynamic>> places = results.map((place) {
          final locObj = place['location'] ?? {};
          final lat = (locObj['latitude'] as num?)?.toDouble() ?? 0.0;
          final lng = (locObj['longitude'] as num?)?.toDouble() ?? 0.0;
          final placeLoc = LatLng(lat, lng);
          
          final distance = Geolocator.distanceBetween(
            location.latitude, location.longitude, lat, lng
          );

          return {
            'name': place['displayName']?['text'] ?? '',
            'address': place['formattedAddress'] ?? '',
            'location': placeLoc,
            'distance': distance,
          };
        }).toList();

        // Filter and sort by exact distance criteria manually
        places = places.where((p) => (p['distance'] as double) <= radius).toList();
        places.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
        return places;
      } else {
        throw Exception('HTTP Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception searching places: $e');
      rethrow;
    }
  }
}
