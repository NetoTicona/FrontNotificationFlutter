import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';

class DatabaseService extends ChangeNotifier {
  final String _apiUrl = "https://apinoti.thenett0.com";
  List<User> _availableUsers = [];
  bool _isLoading = false;

  List<User> get availableUsers => _availableUsers;
  bool get isLoading => _isLoading;

  Future<void> getActiveDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$_apiUrl/active-devices'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _availableUsers = (data['data'] as List)
            .map((user) => User.fromJson(user))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching devices: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendNotificationsData(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('https://apinoti.thenett0.com/sendNotificationsData'),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}