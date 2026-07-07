import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/panchang_data.dart';

class PanchangRepository {
  PanchangRepository({http.Client? client, String? apiUrl})
      : _client = client ?? http.Client(),
        _apiUrl = apiUrl ??
            const String.fromEnvironment(
              'PANCHANG_API_URL',
              defaultValue: 'https://raw.githubusercontent.com/CybermanXD/Panchang-Calendar-App/main/api/panchang-data.json',
            );

  static const _cacheKey = 'panchangDatasetCache';
  static const _cacheVersionKey = 'panchangDatasetCacheVersion';
  static const _cacheVersion = 3;
  final http.Client _client;
  final String _apiUrl;

  Future<PanchangDataset> loadDataset({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheVersion = prefs.getInt(_cacheVersionKey) ?? 0;
    final cached = prefs.getString(_cacheKey);

    if (_apiUrl.isNotEmpty && forceRefresh) {
      final fresh = await _fetchRemoteOrNull();
      if (fresh != null) {
        await _saveCache(prefs, fresh);
        return fresh;
      }
    }

    if (_apiUrl.isNotEmpty && cached == null) {
      final fresh = await _fetchRemoteOrNull();
      if (fresh != null) {
        await _saveCache(prefs, fresh);
        return fresh;
      }
    }

    if (cached != null && cacheVersion == _cacheVersion) {
      try {
        return PanchangDataset.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_cacheKey);
      }
    }

    throw const PanchangDataException('Panchang data is unavailable. Connect to internet once to sync data.');
  }

  Future<void> _saveCache(SharedPreferences prefs, PanchangDataset dataset) async {
    await prefs.setInt(_cacheVersionKey, _cacheVersion);
    await prefs.setString(_cacheKey, jsonEncode(dataset.toJson()));
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

class PanchangDataException implements Exception {
  const PanchangDataException(this.message);

  final String message;

  @override
  String toString() => message;
}
