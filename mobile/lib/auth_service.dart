import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'constants/api_constants.dart';
import 'services/emergency_contact_service.dart';

class AuthService {
  // Replace with your actual backend URL. For Android emulator, use 10.0.2.2.
  // For iOS simulator, use localhost. For physical device, use your machine's IP.
  static const String baseUrl = APIConstants.authUrl;
  
  static bool _initialized = false;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _appPinKey = 'app_pin';
  static const String _decoyPinKey = 'decoy_pin';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));
  }

  static Future<String> _scopedKey(String baseKey) async {
    final user = await getUser();
    if (user != null && user['email'] != null) {
      return '${baseKey}_${user['email']}';
    }
    return baseKey; // Fallback
  }

  static Future<void> saveAppPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _scopedKey(_appPinKey), pin);
  }

  static Future<String?> getAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(await _scopedKey(_appPinKey));
  }

  static Future<bool> hasAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(await _scopedKey(_appPinKey));
  }

  static Future<void> saveDecoyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _scopedKey(_decoyPinKey), pin);
  }

  static Future<String?> getDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(await _scopedKey(_decoyPinKey));
  }

  static Future<bool> hasDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(await _scopedKey(_decoyPinKey));
  }

  static Future<void> clearDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _scopedKey(_decoyPinKey));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return jsonDecode(userStr);
    }
    return null;
  }

  static Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_tokenKey);
  }

  static bool _googleInitialized = false;

  static Future<void> _initGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize();
      _googleInitialized = true;
    }
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // 1. Initialize for v7.x+
      await _initGoogle();
      
      // 2. Perform authentication (replaces signIn())
      final GoogleSignInAccount? account = await GoogleSignIn.instance.authenticate();
      
      if (account == null) {
        print("Google Sign-In canceled by user.");
        return null;
      }

      // 3. Retrieve ID Token
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve ID token from Google.");
      }

      print("Sending ID Token to Backend: $idToken");

      // 4. Send the ID token to our backend for verification
      final response = await http.post(
        Uri.parse("$baseUrl/google"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Backend login successful: ${data['token']}");
        await saveToken(data['token']);
        if (data['user'] != null) {
          await saveUser(data['user']);
        }
        return data; 
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception("Backend error: ${errorData['error']}");
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> signInWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Backend login successful: ${data['token']}");
        await saveToken(data['token']);
        if (data['user'] != null) {
          await saveUser(data['user']);
        }
        return data; 
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception("Backend error: ${errorData['error']}");
      }
    } catch (error) {
      print("Login Error: $error");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> signUpWithEmail(String name, String email, String number, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/signup"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'number': number, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("Backend signup successful: ${data['token']}");
        await saveToken(data['token']);
        if (data['user'] != null) {
          await saveUser(data['user']);
        }
        return data; 
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception("Backend error: ${errorData['error']}");
      }
    } catch (error) {
      print("Sign-Up Error: $error");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String email,
    required String name,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-profile"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          await saveUser(data['user']);
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Failed to update profile");
      }
    } catch (e) {
      print("Update Profile Error: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> updateContacts({
    required String email,
    required List<Map<String, String>> contacts,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-contacts"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'contacts': contacts,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['user'] != null) {
          await saveUser(data['user']);
        }
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? "Failed to update contacts");
      }
    } catch (e) {
      print("Update Contacts Error: $e");
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

class ApiService {
  static String get baseUrl => APIConstants.chatUrl;

  static Future<List<dynamic>> getChatHistory(String userId) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/history/$userId"));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return [];
    } catch (e) {
      debugPrint("History API Error: $e");
      return [];
    }
  }

  static Future<Map<String, dynamic>> sendMessage(String userId, String message) async {
    final res = await http.post(
      Uri.parse("$baseUrl"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "message": message}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to get response from backend");
    }
  }

  static Future<Map<String, dynamic>> sendSOS({
    required double lat,
    required double lng,
    String message = "Emergency! I need help.",
  }) async {
    // Delegate to EmergencyContactService which handles local storage + contacts
    return EmergencyContactService.sendSOS(
      lat: lat,
      lng: lng,
      message: message,
    );
  }
}
