import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';

/// Thin wrapper over the two home-screen HTTP calls. Parses nothing beyond
/// turning a non-2xx into an [ApiException]; entity construction happens one
/// layer up.
class DashboardApi {
  const DashboardApi(this._client);

  final ApiClient _client;

  Dio get _dio => _client.dio;

  /// `GET /api/poojari/panchangam/` (today, Asia/Kolkata — no `date` sent).
  Future<Map<String, dynamic>> panchangam() async {
    final res = await _dio.get<dynamic>(Endpoints.panchangam);
    return _body(res);
  }

  /// `GET /api/poojari/upcoming-pooja-counts/?days=N[&category_id=N]`
  Future<Map<String, dynamic>> upcomingPoojaCounts({
    int days = 3,
    int? categoryId,
  }) async {
    final res = await _dio.get<dynamic>(
      Endpoints.upcomingPoojaCounts,
      queryParameters: {'days': days, 'category_id': ?categoryId},
    );
    return _body(res);
  }

  /// `GET /api/poojari/attendance/location/` — the temple coordinates and
  /// radius the check-in slide pre-checks against (poojari-geofence.md §2).
  ///
  /// `{"location": null}` is a legitimate `200`: no site configured. The
  /// caller decides what that means; it is not an error here.
  Future<Map<String, dynamic>> attendanceLocation() async {
    final res = await _dio.get<dynamic>(Endpoints.attendanceLocation);
    return _body(res);
  }

  /// `POST /api/poojari/attendance/` — marks *today* present (server default
  /// date is Asia/Kolkata today). Idempotent: marking an already-present day
  /// again just replaces it (`201` first time, `200` on a repeat).
  ///
  /// [latitude]/[longitude] go out as **strings**, which is why they arrive as
  /// strings: a JSON float loses the 6th decimal place, and the 6th decimal
  /// place is roughly 10 cm of a 200 m radius argument. `date` is deliberately
  /// not sent — the server's own Asia/Kolkata day is more trustworthy than a
  /// device clock (poojari-geofence.md §5).
  ///
  /// Any distance the app measured is deliberately *not* sent: the server
  /// ignores a client-supplied `distance_meters` and computes its own.
  Future<void> markAttendance({
    required String latitude,
    required String longitude,
  }) async {
    final res = await _dio.post<dynamic>(
      Endpoints.attendance,
      data: {'status': 'present', 'latitude': latitude, 'longitude': longitude},
    );
    _body(res);
  }

  /// `GET /api/poojari/attendance/?period=weekly` — the raw rows for the
  /// current week (always includes today). Used only to look up today's own
  /// row; the profile screen's week strip re-fetches this same shape for its
  /// own window.
  Future<Map<String, dynamic>> attendanceWeek() async {
    final res = await _dio.get<dynamic>(
      Endpoints.attendance,
      queryParameters: {'period': 'weekly'},
    );
    return _body(res);
  }

  /// The client's `validateStatus` lets 4xx through so the body can be mapped
  /// here rather than lost inside a DioException.
  Map<String, dynamic> _body(Response<dynamic> res) {
    final code = res.statusCode ?? 0;
    final data = res.data;
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};

    if (code >= 200 && code < 300) return map;
    throw ApiException.fromResponse(code, map);
  }
}
