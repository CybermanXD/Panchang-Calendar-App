import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/panchang_data.dart';

class PanchangRepository {
  PanchangRepository({http.Client? client, String? apiUrl})
      : _client = client ?? http.Client(),
        _apiUrl = apiUrl ?? const String.fromEnvironment('PANCHANG_API_URL', defaultValue: '');

  static const _cacheKey = 'panchangDatasetCache';
  final http.Client _client;
  final String _apiUrl;

  Future<PanchangDataset> loadDataset({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    if (_apiUrl.isNotEmpty && forceRefresh) {
      final fresh = await _fetchRemoteOrNull();
      if (fresh != null) {
        await prefs.setString(_cacheKey, jsonEncode(fresh.toJson()));
        return fresh;
      }
    }

    if (_apiUrl.isNotEmpty) {
      final fresh = await _fetchRemoteOrNull();
      if (fresh != null) {
        await prefs.setString(_cacheKey, jsonEncode(fresh.toJson()));
        return fresh;
      }
    }

    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        return PanchangDataset.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_cacheKey);
      }
    }

    final sample = PanchangDataset.sample();
    await prefs.setString(_cacheKey, jsonEncode(sample.toJson()));
    return sample;
  }

  Future<PanchangDataset?> _fetchRemoteOrNull() async {
    try {
      final response = await _client.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 12));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PanchangDataset.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
