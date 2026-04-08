import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContact {
  final String name;
  final String phone;

  const EmergencyContact({required this.name, required this.phone});

  Map<String, dynamic> toMap() => {'name': name, 'phone': phone};

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EmergencyContact && other.name == name && other.phone == phone;

  @override
  int get hashCode => name.hashCode ^ phone.hashCode;
}

class EmergencyContactService {
  static const int maxContacts = 5;
  static const String _localKey = 'emergency_contacts_local';

  // ─── Local Storage (SharedPreferences) ──────────────────────────────────────

  /// Adds a contact locally in SharedPreferences.
  static Future<void> addContact(EmergencyContact contact) async {
    final contacts = await fetchContacts();
    contacts.add(contact);
    await _saveAll(contacts);
  }

  /// Removes a contact from local storage.
  static Future<void> removeContact(EmergencyContact contact) async {
    final contacts = await fetchContacts();
    contacts.removeWhere((c) => c == contact);
    await _saveAll(contacts);
  }

  /// Fetches all emergency contacts from local storage.
  static Future<List<EmergencyContact>> fetchContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => EmergencyContact.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Saves the full contacts list to SharedPreferences.
  static Future<void> _saveAll(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localKey, jsonEncode(contacts.map((c) => c.toMap()).toList()));
  }

  // ─── Validation ─────────────────────────────────────────────────────────────

  /// Returns an error string, or null if valid.
  static String? validate({
    required String name,
    required String phone,
    required List<EmergencyContact> existing,
  }) {
    if (name.trim().isEmpty) return 'Name cannot be empty';
    if (phone.trim().isEmpty) return 'Phone number cannot be empty';
    if (!phone.startsWith('+')) {
      return 'Phone must start with country code (e.g., +91XXXXXXXXXX)';
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Phone number is too short';
    if (existing.length >= maxContacts) {
      return 'Maximum $maxContacts contacts allowed';
    }
    if (existing.any((c) => c.phone == phone)) {
      return 'This phone number is already added';
    }
    return null;
  }

  // ─── SOS API ────────────────────────────────────────────────────────────────

  /// Sends SOS to the backend with location + locally stored contacts.
  static Future<Map<String, dynamic>> sendSOS({
    required double lat,
    required double lng,
    String message = 'Emergency! I need help.',
  }) async {
    final contacts = await fetchContacts();
    
    // Use localhost for web, Android emulator IP otherwise
    final baseUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

    final res = await http.post(
      Uri.parse('$baseUrl/sos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'location': {'lat': lat, 'lng': lng},
        'message': message,
        'contacts': contacts.map((c) => c.toMap()).toList(),
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('SOS failed: ${res.body}');
    }
  }
}
