import 'reading.dart';

/// Pure consumption maths — mirrors the backend exactly so the UI can recompute
/// instantly (e.g. the moment a manual override changes) without a round trip.
class ReadingCalculator {
  const ReadingCalculator();

  /// Whole calendar days between two days (b - a), ignoring time of day.
  static int dayDiff(DateTime a, DateTime b) {
    final da = DateTime(a.year, a.month, a.day);
    final db = DateTime(b.year, b.month, b.day);
    return db.difference(da).inDays;
  }

  /// Sorts readings oldest → newest by date and derives, for every reading
  /// AFTER the first:
  ///   unitsUsed = manualUnits ?? (this.meter - previous.meter)
  ///   daysGap   = max(1, days between this.date and previous.date)
  ///   perDay    = unitsUsed / daysGap
  /// The first reading is the baseline (all derived values null).
  /// A downward meter jump with no manual override is flagged `invalid`.
  List<ComputedReading> compute(List<Reading> readings) {
    final ordered = [...readings]..sort(_byDate);
    final out = <ComputedReading>[];
    var cumulative = 0;
    for (var i = 0; i < ordered.length; i++) {
      final r = ordered[i];
      if (i == 0) {
        out.add(ComputedReading(
          reading: r,
          unitsUsed: null,
          daysGap: null,
          perDay: null,
          cumulativeUsed: 0,
          invalid: false,
        ));
        continue;
      }
      final prev = ordered[i - 1];
      final autoDiff = r.meterReading - prev.meterReading;
      final hasManual = r.manualUnits != null;
      final invalid = !hasManual && autoDiff < 0;
      final unitsUsed = hasManual ? r.manualUnits! : autoDiff;
      final daysGap = dayDiff(prev.date, r.date) < 1
          ? 1
          : dayDiff(prev.date, r.date);
      // A flagged (negative/rollover) interval is an error — don't let its wrong
      // units leak into the running total.
      if (!invalid) cumulative += unitsUsed;
      out.add(ComputedReading(
        reading: r,
        unitsUsed: unitsUsed,
        daysGap: daysGap,
        perDay: unitsUsed / daysGap,
        cumulativeUsed: cumulative,
        invalid: invalid,
      ));
    }
    return out;
  }

  /// totalUnitsUsed = sum of every unitsUsed; totalDays = days between first and
  /// last reading; avgPerDay = totalUnitsUsed / totalDays.
  ReadingSummary summarise(List<Reading> readings) {
    final computed = compute(readings);
    if (computed.isEmpty) {
      return const ReadingSummary(totalUnitsUsed: 0, totalDays: 0, avgPerDay: 0);
    }
    final total = computed
        .where((c) => c.unitsUsed != null && !c.invalid)
        .fold<int>(0, (sum, c) => sum + c.unitsUsed!);
    final days = dayDiff(
      computed.first.reading.date,
      computed.last.reading.date,
    );
    return ReadingSummary(
      totalUnitsUsed: total,
      totalDays: days,
      avgPerDay: days > 0 ? total / days : 0,
    );
  }

  int _byDate(Reading a, Reading b) {
    final byDay = a.date.compareTo(b.date);
    if (byDay != 0) return byDay;
    return a.id.compareTo(b.id); // stable tiebreak = insertion order
  }
}

class ReadingSummary {
  const ReadingSummary({
    required this.totalUnitsUsed,
    required this.totalDays,
    required this.avgPerDay,
  });

  final int totalUnitsUsed;
  final int totalDays;
  final double avgPerDay;
}
