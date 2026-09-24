import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';

/// Thin wrapper over the account screen's HTTP calls. Parses nothing beyond
/// turning a non-2xx into an [ApiException]; entity construction happens one
/// layer up.
class ProfileApi {
  const ProfileApi(this._client);

  final ApiClient _client;

  Dio get _dio => _client.dio;

  /// `GET /api/poojari/gods/`
  Future<Map<String, dynamic>> gods() async {
    final res = await _dio.get<dynamic>(Endpoints.gods);
    return _body(res);
  }

  /// `GET /api/poojari/monthly-stats/` (current month, Asia/Kolkata).
  Future<Map<String, dynamic>> monthlyStats() async {
    final res = await _dio.get<dynamic>(Endpoints.monthlyStats);
    return _body(res);
  }

  /// `GET /api/poojari/attendance/report/?period=[&date_from=&date_to=]`
  Future<Map<String, dynamic>> attendanceReport({
    required String period,
    String? dateFrom,
    String? dateTo,
  }) async {
    final res = await _dio.get<dynamic>(
      Endpoints.attendanceReport,
      queryParameters: {
        'period': period,
        'date_from': ?dateFrom,
        'date_to': ?dateTo,
      },
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
