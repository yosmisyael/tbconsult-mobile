import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:TBConsult/core/di/injection_container.dart' as di;
import 'package:TBConsult/features/auth/presentation/cubit/auth_cubit.dart';

/// Singleton Dio instance pre-configured with:
///   • Base URL from BACKEND_BASE_URL env var
///   • Automatic JWT acquisition + silent refresh on 401
///   • Android emulator localhost → 10.0.2.2 rewrite
///
/// IMPORTANT: This client is only for your backend.
/// Never pass it to repositories that call external APIs (e.g. Google Maps).
/// Those repositories should create their own plain Dio() instance.
class DioClient {
  DioClient._();

  static DioClient? _instance;
  static DioClient get instance => _instance ??= DioClient._();

  late final Dio dio;
  late final SharedPreferences _prefs;

  static const _uuid = Uuid();

  Future<void> initialize(SharedPreferences prefs) async {
    _prefs = prefs;

    dio = Dio(
      BaseOptions(
        baseUrl: _resolveBaseUrl(),
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  // ── Base URL ────────────────────────────────────────────────────────────

  String _resolveBaseUrl() {
    final base = dotenv.env['BACKEND_BASE_URL'] ?? 'http://localhost:8000/v1';
    var url = base;
    if (!kIsWeb && Platform.isAndroid) {
      url = base
          .replaceAll('localhost', '10.0.2.2')
          .replaceAll('127.0.0.1', '10.0.2.2');
    }
    // Strip trailing slash to prevent double slashes when concatenating paths
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  // ── Auth helpers ────────────────────────────────────────────────────────

  Future<String> _getToken() async {
    final cached = _prefs.getString('backend_jwt_token');
    if (cached != null) {
      return cached;
    }
    throw Exception('No authentication token found');
  }

  /// Sends a ping to the backend to refresh the JWT session.
  /// If successful, the new token is saved locally to extend the session.
  Future<void> pingAndRefreshToken() async {
    try {
      final response = await dio.post<Map<String, dynamic>>('/auth/ping');
      if (response.statusCode == 200) {
        final token = response.data!['access_token'] as String;
        await _prefs.setString('backend_jwt_token', token);
        debugPrint('DioClient: Token session successfully extended via ping.');
      }
    } catch (e) {
      debugPrint('DioClient: Ping session refresh failed: $e');
    }
  }

  // ── Interceptor callbacks ───────────────────────────────────────────────

  Future<void> _onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    try {
      final token = await _getToken();
      options.headers['Authorization'] = 'Bearer $token';
    } catch (_) {
      // Proceed without token; server will return 401 handled in _onError
    }
    handler.next(options);
  }

  Future<void> _onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final path = err.requestOptions.path;
    
    // Ignore 401 on login/register to prevent duplicate API retries and unwanted auto-logout
    if (path.contains('/auth/login') || path.contains('/auth/register')) {
      return handler.next(err);
    }

    if (err.response?.statusCode == 401) {
      // Trigger auto-logout when token expires or is invalid
      try {
        di.sl<AuthCubit>().logout();
      } catch (_) {}
      
      // Do not automatically retry the request on 401 to prevent duplicate API calls.
      // The user will be redirected to the login screen by the AuthCubit state change.
    }
    handler.next(err);
  }
}
