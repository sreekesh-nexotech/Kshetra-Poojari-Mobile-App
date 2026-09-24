import '../../domain/entities/booking.dart';
import '../../domain/entities/pooja_category.dart';
import '../../domain/entities/pooja_order.dart';
import '../../domain/entities/status_update.dart';
import '../../domain/repositories/pooja_repository.dart';
import '../data_sources/remote/pooja_api.dart';

class PoojaRepositoryImpl implements PoojaRepository {
  const PoojaRepositoryImpl(this._api);

  final PoojaApi _api;

  @override
  Future<List<PoojaCategory>> gods() async {
    final assigned = await _assignedGods();
    // Empty means every god, not none (poojari-app.md §3) — only then does
    // the picker fall back to the full temple catalogue. A poojari with real
    // shrine assignments must never be offered one they don't serve: asking
    // for it is now a 403 (POOJARI_APP_API.md §1).
    final gods = assigned.isNotEmpty ? assigned : await _allCategories();
    return _sorted(gods);
  }

  /// `GET /api/poojari/gods/`. Degrades to an empty list — same as "serves
  /// every god" — on any failure, rather than blocking the picker.
  Future<List<PoojaCategory>> _assignedGods() async {
    try {
      final body = await _api.assignedGods();
      final rows = (body['gods'] as List?) ?? const [];
      return rows
          .cast<Map<String, dynamic>>()
          .map((r) => PoojaCategory.fromJson(r['god'] as Map<String, dynamic>))
          .where((g) => g.isActive)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<PoojaCategory>> _allCategories() async {
    final body = await _api.categories();
    final rows = (body['results'] as List?) ?? const [];
    return rows
        .cast<Map<String, dynamic>>()
        .map(PoojaCategory.fromJson)
        .where((g) => g.isActive)
        .toList();
  }

  // sort_order is the order the back office dragged the shrines into. It is
  // null on the poojari endpoints, so fall back to id for stability.
  List<PoojaCategory> _sorted(List<PoojaCategory> gods) {
    gods.sort((a, b) {
      final byOrder = (a.sortOrder ?? 1 << 30).compareTo(
        b.sortOrder ?? 1 << 30,
      );
      return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
    });
    return gods;
  }

  @override
  Future<TodaysWork> todaysWork(int categoryId) async =>
      TodaysWork.fromJson(await _api.todaysWork(categoryId));

  @override
  Future<StatusUpdateResult> markBookings({
    required int orderId,
    required List<int> bookingIds,
    required PoojaStatus status,
  }) async {
    if (bookingIds.isEmpty) {
      throw ArgumentError.value(
        bookingIds,
        'bookingIds',
        'Refusing to PATCH with no order_line_ids: the server would move '
            'every booking on order $orderId.',
      );
    }

    return StatusUpdateResult.fromJson(
      await _api.markBookings(
        orderId: orderId,
        bookingIds: bookingIds,
        status: status,
      ),
    );
  }
}
