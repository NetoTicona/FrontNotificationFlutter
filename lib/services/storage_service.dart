import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'dart:convert';

class StorageService extends ChangeNotifier {
  static const String _configKey = 'app_config';
  static const String _sequencesKey = 'user_sequences';

  Map<String, dynamic> _config = {};
  List<UserSequence> _savedSequences = [];

  Map<String, dynamic> get config => _config;
  List<UserSequence> get savedSequences => _savedSequences;

  static Future<StorageService> init() async {
    final instance = StorageService();
    await instance._loadData();
    return instance;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load config
    final configJson = prefs.getString(_configKey);
    if (configJson != null) {
      _config = json.decode(configJson);
    }

    // Load sequences
    final sequencesJson = prefs.getString(_sequencesKey);
    if (sequencesJson != null) {
      _savedSequences = (json.decode(sequencesJson) as List)
          .map((item) => UserSequence.fromJson(item))
          .toList();
    }
    
    notifyListeners();
  }

  Future<void> saveConfig(Map<String, dynamic> config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, json.encode(config));
    notifyListeners();
  }

  Future<void> saveSequence(UserSequence sequence) async {
    _savedSequences.add(sequence);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sequencesKey, json.encode(_savedSequences));
    notifyListeners();
  }
}