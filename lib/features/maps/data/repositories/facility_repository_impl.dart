import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:TBConsult/core/error/failures.dart';
import 'package:TBConsult/features/maps/data/data_sources/surabaya_facilities_data.dart';
import 'package:TBConsult/features/maps/domain/entities/facility_entity.dart';
import 'package:TBConsult/features/maps/domain/repositories/facility_repository.dart';

class FacilityRepositoryImpl implements FacilityRepository {
  FacilityRepositoryImpl();

  // ── Facilities ──────────────────────────────────────────────────────────────

  @override
  Future<List<FacilityEntity>> getFacilities({LatLng? userLocation}) async {
    final raw = SurabayaFacilitiesData.all;
    if (userLocation == null) return raw;

    return raw.map((f) {
      final km = _haversineKm(
        userLocation.latitude,
        userLocation.longitude,
        f.lat,
        f.lng,
      );
      return f.copyWith(distanceKm: km);
    }).toList()
      ..sort((a, b) =>
          (a.distanceKm ?? double.infinity)
              .compareTo(b.distanceKm ?? double.infinity));
  }

  // ── Route (Direct Google Directions call) ───────────────────────────────────

  final Dio _plainDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  @override
  Future<List<LatLng>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAP_API_KEY'] ?? dotenv.env['MAPS_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        throw const ServerFailure('Maps API Key is not configured on the client.');
      }

      final response = await _plainDio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: {
          'origin': '${origin.latitude.toStringAsFixed(6)},${origin.longitude.toStringAsFixed(6)}',
          'destination': '${destination.latitude.toStringAsFixed(6)},${destination.longitude.toStringAsFixed(6)}',
          'mode': 'driving',
          'key': apiKey,
        },
      );

      final data = response.data!;
      final status = data['status'] as String?;

      if (status != 'OK') {
        final errorMsg = data['error_message'] as String?;
        throw ServerFailure(
          errorMsg ?? 'Directions API status: $status',
        );
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) throw const ServerFailure('No route found');

      final overviewPolyline =
      routes[0]['overview_polyline']['points'] as String;
      return _decodePolyline(overviewPolyline);
    } on DioException catch (e) {
      throw ServerFailure(
        e.response?.data?.toString() ?? e.message ?? 'Network error',
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180);

  List<LatLng> _decodePolyline(String encoded) {
    final poly = <LatLng>[];
    int index = 0;
    final len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dLng;

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}
