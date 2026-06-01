import 'package:dio/dio.dart';

/// Fetches a real photo URL for a facility using the Google Places API
/// (Text Search → photo reference → photo URL).
///
/// Uses a dedicated plain Dio — no baseUrl, no JWT interceptor —
/// same pattern as the Directions API fix.
///
/// Results are in-memory cached so each facility is only fetched once
/// per app session.
class FacilityPhotoService {
  final String apiKey;

  FacilityPhotoService({required this.apiKey});

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// Facility id → resolved photo URL (or null if not found)
  final Map<String, String?> _cache = {};

  /// Returns a photo URL for [facilityName] + [address], or null on failure.
  ///
  /// Flow:
  ///   1. POST Places API Text Search → get place_id + first photo_reference
  ///   2. Build the Place Photo URL (no extra call needed — URL is static)
  Future<String?> fetchPhotoUrl({
    required String facilityId,
    required String facilityName,
    required String address,
  }) async {
    // Return cached result (including null — don't retry known failures)
    if (_cache.containsKey(facilityId)) return _cache[facilityId];

    try {
      // ── Step 1: Text Search to find the place ────────────────────
      final searchResp = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/place/textsearch/json',
        queryParameters: {
          'query': '$facilityName $address',
          'key': apiKey,
          'language': 'id',
        },
      );

      final results =
      searchResp.data?['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) {
        _cache[facilityId] = null;
        return null;
      }

      final place = results.first as Map<String, dynamic>;
      final photos = place['photos'] as List<dynamic>?;
      if (photos == null || photos.isEmpty) {
        _cache[facilityId] = null;
        return null;
      }

      final photoRef =
      (photos.first as Map<String, dynamic>)['photo_reference']
      as String?;
      if (photoRef == null) {
        _cache[facilityId] = null;
        return null;
      }

      // ── Step 2: Build static Place Photo URL ─────────────────────
      // This URL loads directly in Image.network — no extra API call.
      final photoUrl = 'https://maps.googleapis.com/maps/api/place/photo'
          '?maxwidth=600'
          '&photo_reference=$photoRef'
          '&key=$apiKey';

      _cache[facilityId] = photoUrl;
      return photoUrl;
    } catch (_) {
      _cache[facilityId] = null;
      return null;
    }
  }
}
