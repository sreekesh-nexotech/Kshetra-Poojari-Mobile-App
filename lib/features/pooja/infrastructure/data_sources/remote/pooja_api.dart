import 'package:dio/dio.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';
import '../../../../../core/network/network_exceptions.dart';
import '../../../domain/entities/booking.dart';

/// Thin wrapper over the four pooja HTTP calls. Parses nothing beyond turning
/// a non-2xx into an [ApiException]; entity construction happens one layer up.
class PoojaApi {
  const PoojaApi(this._client);

  final ApiClient _client;

  Dio get _dio => _client.dio;

  /// `GET /api/booking/poojacategory/?is_active=true`
  ///
  /// Unpaginated unless you ask — no `page`/`page_size` here, so every row
  /// comes back. Server-side cached with no timeout and invalidated on write,
  /// so it is safe to hold for the session.
  Future<Map<String, dynamic>> categories() async {
    final res = await _dio.get<dynamic>(
      Endpoints.poojaCategory,
      queryParameters: {'is_active': true},
    );
    return _body(res);
  }

  /// `GET /api/poojari/gods/` — the shrines *this* poojari actually keeps.
  /// An empty list means every god, not none (poojari-app.md §3) — the
  /// caller falls back to [categories] when this comes back empty.
  Future<Map<String, dynamic>> assignedGods() async {
    final res = await _dio.get<dynamic>(Endpoints.gods);
    return _body(res);
  }

  /// `GET /api/poojari/pooja-management/?category_id=N`
  Future<Map<String, dynamic>> todaysWork(int categoryId) async {
    final res = await _dio.get<dynamic>(
      Endpoints.poojaManagement,
      // Omitting category_id is a 400, not "all gods".
      queryParameters: {'category_id': categoryId},
    );
    return _body(res);
  }

  /// `PATCH /api/poojari/pooja-management/`
  Future<Map<String, dynamic>> markBookings({
    required int orderId,
    required List<int> bookingIds,
    required PoojaStatus status,
  }) async {
    // Omitting order_line_ids moves EVERY booking on the order — other
    // poojas, other dates, other people. A screen that shows booking rows
    // must always name the rows it is moving.
    assert(
      bookingIds.isNotEmpty,
      'Never send an empty list — the server default moves the whole order.',
    );

    final res = await _dio.patch<dynamic>(
      Endpoints.poojaManagement,
      data: {
        'order_id': orderId,
        'order_line_ids': bookingIds,
        'pooja_status': status.name,
      },
    );
    return _body(res);
  }

  /// Cheap change probe for cache invalidation on resume. Poll this, never the
  /// list endpoint — the throttle is 2000 req/hour per user.
  Future<Map<String, dynamic>> globalUpdate() async {
    final res = await _dio.get<dynamic>(Endpoints.globalUpdate);
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
