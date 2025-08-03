import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _configKey = 'app_config';
  static const String _sequencesKey = 'user_sequences';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<void> saveConfig(Map<String, dynamic> config) async {
    final prefs = await _prefs;
    await prefs.setString(_configKey, json.encode(config));
  }

  Future<Map<String, dynamic>?> getConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_configKey);
    return configJson != null ? json.decode(configJson) as Map<String, dynamic> : null;
  }

  Future<void> saveSequence(Map<String, dynamic> sequence) async {
    final prefs = await _prefs;
    final sequences = await getSequences();
    sequences.add(sequence);
    await prefs.setString(_sequencesKey, json.encode(sequences));
  }

  Future<List<Map<String, dynamic>>> getSequences() async {
    final prefs = await _prefs;
    final sequencesJson = prefs.getString(_sequencesKey);
    return sequencesJson != null
        ? (json.decode(sequencesJson) as List).cast<Map<String, dynamic>>()
        : [];
  }

  Future<void> clearData() async {
    final prefs = await _prefs;
    await prefs.remove(_configKey);
    await prefs.remove(_sequencesKey);
  }

  Future<void> clearSequences() async {
    final prefs = await _prefs;
    await prefs.remove(_sequencesKey);
  }
}