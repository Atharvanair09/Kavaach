import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Replace with your actual backend URL. For Android emulator, use 10.0.2.2.
  // For iOS simulator, use localhost. For physical device, use your machine's IP.
  static const String baseUrl = 'http://192.168.1.8:5000/auth';
  
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

  static Future<void> saveAppPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appPinKey, pin);
  }

  static Future<String?> getAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_appPinKey);
  }

  static Future<bool> hasAppPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_appPinKey);
  }

  static Future<void> saveDecoyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_decoyPinKey, pin);
  }

  static Future<String?> getDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_decoyPinKey);
  }

  static Future<bool> hasDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_decoyPinKey);
  }

  static Future<void> clearDecoyPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_decoyPinKey);
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

  static Future<void> _initGoogleSignIn() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        // Optional: Add clientId here if required for your platform
        // clientId: 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
      );
      _initialized = true;
    }
  }

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      await _initGoogleSignIn();
      
      // The modern GoogleSignIn 7.0+ API uses instance.authenticate()
      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // retrieve token
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception("Failed to retrieve ID token from Google.");
      }

      // Send the ID token to our backend for verification
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
        return data; // returns { "message": "...", "token": "...", "user": {...} }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception("Backend error: ${errorData['error']}");
      }
    } catch (error) {
      print("Google Sign-In Error: $error");
      // If the user canceled the login, it will throw an exception instead of returning null (in older versions).
      // We return null to silently abort the flow just like before
      if (error is GoogleSignInException && error.code == GoogleSignInExceptionCode.canceled) {
         return null; 
      }
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

  static Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_appPinKey);
    await prefs.remove(_decoyPinKey);
  }
}
