import 'dart:async';

import 'package:kshetra_poojari/features/pooja/domain/entities/booking.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/pooja_category.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/pooja_order.dart';
import 'package:kshetra_poojari/features/pooja/domain/entities/status_update.dart';
import 'package:kshetra_poojari/features/pooja/domain/repositories/pooja_repository.dart';

/// A scriptable [PoojaRepository]: hand it what each call should return or
/// throw, and inspect what it was asked for.
class FakePoojaRepository implements PoojaRepository {
  FakePoojaRepository({
    this.godsResult = const [],
    this.godsError,
    this.workByCategory = const {},
    this.workError,
    this.markResults = const {},
    this.markErrors = const {},
    this.gate,
  });

  List<PoojaCategory> godsResult;
  Object? godsError;

  Map<int, TodaysWork> workByCategory;
  Object? workError;

  /// order id -> the result that PATCH should return.
  Map<int, StatusUpdateResult> markResults;

  /// order id -> the error that PATCH should throw instead.
  Map<int, Object> markErrors;

  /// Set to hold every call open until completed, so a test can observe the
  /// in-flight state deterministically instead of racing a timer.
  Completer<void>? gate;

  final List<int> godsCalls = [];
  final List<int> workCalls = [];
  final List<({int orderId, List<int> bookingIds, PoojaStatus status})>
  markCalls = [];

  Future<void> _wait() async {
    final g = gate;
    if (g != null) await g.future;
  }

  @override
  Future<List<PoojaCategory>> gods() async {
    godsCalls.add(godsCalls.length);
    await _wait();
    if (godsError != null) throw godsError!;
    // Honour the interface contract — the real impl returns them sorted, so a
    // fake that didn't would let a sort bug through.
    final sorted = [...godsResult]
      ..sort((a, b) {
        final byOrder = (a.sortOrder ?? 1 << 30).compareTo(
          b.sortOrder ?? 1 << 30,
        );
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    return sorted;
  }

  @override
  Future<TodaysWork> todaysWork(int categoryId) async {
    workCalls.add(categoryId);
    await _wait();
    if (workError != null) throw workError!;
    final work = workByCategory[categoryId];
    if (work == null) {
      return TodaysWork(
        category: PoojaCategory(id: categoryId, name: 'god $categoryId'),
        orders: const [],
      );
    }
    return work;
  }

  @override
  Future<StatusUpdateResult> markBookings({
    required int orderId,
    required List<int> bookingIds,
    required PoojaStatus status,
  }) async {
    markCalls.add((
      orderId: orderId,
      bookingIds: List.of(bookingIds),
      status: status,
    ));
    await _wait();
    final err = markErrors[orderId];
    if (err != null) throw err;

    final result = markResults[orderId];
    if (result != null) return result;

    // Default: the server accepted exactly what was asked.
    return StatusUpdateResult(
      message: 'Pooja status updated to ${status.name}',
      bookingsUpdated: bookingIds.length,
      orderPoojaStatus: status,
      orderStatus: 'confirmed',
      lineStatuses: {for (final id in bookingIds) id: status},
    );
  }
}
