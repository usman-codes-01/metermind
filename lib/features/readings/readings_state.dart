part of 'readings_cubit.dart';

enum ReadingsStatus { initial, loading, loaded, error }

class ReadingsState extends Equatable {
  const ReadingsState({
    this.status = ReadingsStatus.initial,
    this.readings = const [],
    this.computed = const [],
    this.summary = const ReadingSummary(totalUnitsUsed: 0, totalDays: 0, avgPerDay: 0),
    this.monthlyTarget,
    this.errorMessage,
    this.busy = false,
    this.actionError,
  });

  /// User-set monthly units allowance (null = not set).
  final int? monthlyTarget;

  final ReadingsStatus status;

  /// Raw readings, date order (oldest → newest).
  final List<Reading> readings;

  /// Derived view, date order (oldest → newest).
  final List<ComputedReading> computed;

  final ReadingSummary summary;

  /// Set when the initial load fails (full-screen error).
  final String? errorMessage;

  /// True while a create/update/delete/override request is in flight.
  final bool busy;

  /// Transient error from a mutation (shown as a snackbar, then cleared).
  final String? actionError;

  bool get isLoading => status == ReadingsStatus.loading;
  bool get isEmpty => readings.isEmpty;

  /// Oldest first (old at top, latest at the bottom) — the list view order.
  List<ComputedReading> get oldestFirst => computed;

  /// Projected monthly usage = average per day × 30 (rounded).
  int get projectedMonthly => (summary.avgPerDay * 30).round();

  /// True when there's a target and projected monthly usage is above it.
  bool get exceedsTarget =>
      monthlyTarget != null && projectedMonthly > monthlyTarget!;

  ReadingsState copyWith({
    ReadingsStatus? status,
    List<Reading>? readings,
    List<ComputedReading>? computed,
    ReadingSummary? summary,
    int? monthlyTarget,
    bool clearMonthlyTarget = false,
    String? errorMessage,
    bool clearError = false,
    bool? busy,
    String? actionError,
    bool clearActionError = false,
  }) {
    return ReadingsState(
      status: status ?? this.status,
      readings: readings ?? this.readings,
      computed: computed ?? this.computed,
      summary: summary ?? this.summary,
      monthlyTarget:
          clearMonthlyTarget ? null : (monthlyTarget ?? this.monthlyTarget),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busy: busy ?? this.busy,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props =>
      [status, readings, monthlyTarget, errorMessage, busy, actionError];
}
