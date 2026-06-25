import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'reading.dart';
import 'reading_calculator.dart';
import 'readings_repository.dart';

part 'readings_state.dart';

/// Single source of truth for the whole app. Holds the raw readings and derives
/// the consumption numbers locally (via [ReadingCalculator]) so any change —
/// especially a manual override — is reflected instantly, then persisted to the
/// backend. The monthly target is stored on the backend too.
class ReadingsCubit extends Cubit<ReadingsState> {
  ReadingsCubit(this._repo) : super(const ReadingsState());

  final ReadingsRepository _repo;
  static const _calc = ReadingCalculator();

  /// Sets (or clears, with null) the monthly-units target. Updates the UI
  /// instantly, then persists to the backend; reverts on failure.
  Future<void> setMonthlyTarget(int? value) async {
    final normalised = (value == null || value <= 0) ? null : value;
    final previous = state.monthlyTarget;
    emit(normalised == null
        ? state.copyWith(clearMonthlyTarget: true)
        : state.copyWith(monthlyTarget: normalised));
    try {
      await _repo.setMonthlyTarget(normalised);
    } catch (_) {
      emit(previous == null
          ? state.copyWith(
              clearMonthlyTarget: true, actionError: 'Could not save the target.')
          : state.copyWith(
              monthlyTarget: previous, actionError: 'Could not save the target.'));
    }
  }

  /// Recomputes derived values + summary for the given raw list and emits.
  ReadingsState _withReadings(List<Reading> raw, {ReadingsState? base}) {
    final b = base ?? state;
    return b.copyWith(
      readings: raw,
      computed: _calc.compute(raw),
      summary: _calc.summarise(raw),
    );
  }

  Future<void> load() async {
    emit(state.copyWith(status: ReadingsStatus.loading, clearError: true));
    try {
      final raw = await _repo.getReadings();
      final target = await _repo.getMonthlyTarget();
      final next = _withReadings(raw, base: state)
          .copyWith(status: ReadingsStatus.loaded, clearError: true);
      emit(target == null
          ? next.copyWith(clearMonthlyTarget: true)
          : next.copyWith(monthlyTarget: target));
    } catch (_) {
      emit(state.copyWith(
        status: ReadingsStatus.error,
        errorMessage: 'Could not load your readings. Please try again.',
      ));
    }
  }

  Future<bool> addReading({
    required int meterReading,
    required DateTime date,
    String? note,
  }) async {
    final err = _validate(meterReading, date);
    if (err != null) {
      emit(state.copyWith(actionError: err));
      return false;
    }
    return _mutate(() async {
      final created = await _repo.addReading(
        meterReading: meterReading,
        date: _dateKey(date),
        note: note,
      );
      return [...state.readings, created];
    });
  }

  Future<bool> updateReading(Reading reading) async {
    final err = _validate(reading.meterReading, reading.date, editingId: reading.id);
    if (err != null) {
      emit(state.copyWith(actionError: err));
      return false;
    }
    return _mutate(() async {
      final updated = await _repo.updateReading(reading);
      return [
        for (final r in state.readings) r.id == updated.id ? updated : r,
      ];
    });
  }

  /// Validates a reading before saving, against its neighbours by date:
  /// non-negative, not future-dated, no duplicate date, and the meter only goes
  /// up (prev.value < value < next.value). Returns an error message, or null if OK.
  String? _validate(int value, DateTime date, {String? editingId}) {
    if (value < 0) return 'Reading must be 0 or more.';

    final today = DateTime.now();
    final key = DateTime(date.year, date.month, date.day);
    if (key.isAfter(DateTime(today.year, today.month, today.day))) {
      return 'Date cannot be in the future.';
    }

    final others = state.readings.where((r) => r.id != editingId).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    Reading? prev, next;
    for (final r in others) {
      final rKey = DateTime(r.date.year, r.date.month, r.date.day);
      if (rKey == key) return 'A reading already exists for that date.';
      if (rKey.isBefore(key)) {
        prev = r;
      } else {
        next ??= r;
      }
    }

    if (prev != null && value <= prev.meterReading) {
      return 'This reading must be higher than ${prev.meterReading} '
          '(the earlier day).';
    }
    if (next != null && value >= next.meterReading) {
      return 'This reading does not fit between the surrounding days.';
    }
    return null;
  }

  Future<bool> deleteReading(String id) async {
    return _mutate(() async {
      await _repo.deleteReading(id);
      return state.readings.where((r) => r.id != id).toList();
    });
  }

  /// Sets (or clears, with null) a manual override. Updates the UI instantly,
  /// then persists; reverts on failure.
  Future<void> setManualUnits(String id, int? manualUnits) async {
    final previous = state.readings;
    // Optimistic local update for instant recalculation.
    final optimistic = [
      for (final r in previous)
        r.id == id ? r.copyWith(manualUnits: manualUnits) : r,
    ];
    emit(_withReadings(optimistic, base: state.copyWith(busy: true)));

    try {
      final saved = await _repo.setManualUnits(id, manualUnits);
      final merged = [
        for (final r in state.readings) r.id == saved.id ? saved : r,
      ];
      emit(_withReadings(merged, base: state).copyWith(busy: false));
    } catch (_) {
      emit(_withReadings(previous, base: state)
          .copyWith(busy: false, actionError: 'Could not save the override.'));
    }
  }

  /// Runs a mutation that returns the new raw list; recomputes + emits, and
  /// surfaces errors via [ReadingsState.actionError]. Returns true on success.
  Future<bool> _mutate(Future<List<Reading>> Function() action) async {
    emit(state.copyWith(busy: true, clearActionError: true));
    try {
      final raw = await action();
      emit(_withReadings(raw, base: state).copyWith(busy: false));
      return true;
    } catch (_) {
      emit(state.copyWith(busy: false, actionError: 'Something went wrong.'));
      return false;
    }
  }

  void clearActionError() => emit(state.copyWith(clearActionError: true));

  /// Clears all data on sign-out so the next user doesn't see stale readings.
  void reset() => emit(const ReadingsState());

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
