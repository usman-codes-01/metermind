import 'package:equatable/equatable.dart';

/// A single meter reading as stored by the backend. Holds only the raw fields;
/// the derived numbers (unitsUsed / daysGap / perDay) are produced by
/// [ReadingCalculator] so they always reflect the latest manual overrides.
class Reading extends Equatable {
  const Reading({
    required this.id,
    required this.meterReading,
    required this.date,
    this.manualUnits,
    this.note = '',
    this.createdAt,
  });

  /// Server id (MongoDB `_id`).
  final String id;

  /// The cumulative TOTAL shown on the meter.
  final int meterReading;

  /// The calendar day the reading was taken (time component ignored).
  final DateTime date;

  /// Optional manual override for units used. Null = derive automatically.
  final int? manualUnits;

  /// Optional free-text note.
  final String note;

  /// When the record was saved (server timestamp).
  final DateTime? createdAt;

  /// "YYYY-MM-DD" — how the backend stores/expects the date.
  String get dateKey =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Reading copyWith({
    int? meterReading,
    DateTime? date,
    Object? manualUnits = _unset,
    String? note,
  }) {
    return Reading(
      id: id,
      meterReading: meterReading ?? this.meterReading,
      date: date ?? this.date,
      manualUnits:
          manualUnits == _unset ? this.manualUnits : manualUnits as int?,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  static const Object _unset = Object();

  @override
  List<Object?> get props => [id, meterReading, date, manualUnits, note];
}

/// A [Reading] paired with everything derived from the chain of readings.
/// For the very first reading (by date) the derived values are null (baseline).
class ComputedReading extends Equatable {
  const ComputedReading({
    required this.reading,
    required this.unitsUsed,
    required this.daysGap,
    required this.perDay,
    required this.cumulativeUsed,
    required this.invalid,
  });

  final Reading reading;

  /// Units consumed since the previous reading. Null for the first reading.
  final int? unitsUsed;

  /// Whole days since the previous reading (minimum 1). Null for the first.
  final int? daysGap;

  /// unitsUsed / daysGap. Null for the first reading.
  final double? perDay;

  /// Running total of units used from the first reading up to (and including)
  /// this one. 0 for the baseline.
  final int cumulativeUsed;

  /// True when the meter went DOWN and there is no manual override to fix it.
  final bool invalid;

  bool get isBaseline => unitsUsed == null;
  bool get isManual => reading.manualUnits != null;

  @override
  List<Object?> get props =>
      [reading, unitsUsed, daysGap, perDay, cumulativeUsed, invalid];
}
