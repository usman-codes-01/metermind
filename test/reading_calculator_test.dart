import 'package:flutter_test/flutter_test.dart';
import 'package:metermind/features/readings/reading.dart';
import 'package:metermind/features/readings/reading_calculator.dart';

void main() {
  const calc = ReadingCalculator();

  Reading r(String id, int meter, String date, {int? manual}) => Reading(
        id: id,
        meterReading: meter,
        date: DateTime.parse(date),
        manualUnits: manual,
      );

  group('ReadingCalculator', () {
    test('acceptance: 45000@06-15 then 45160@06-19', () {
      final out = calc.compute([
        r('a', 45000, '2026-06-15'),
        r('b', 45160, '2026-06-19'),
      ]);

      // First reading is the baseline.
      expect(out[0].isBaseline, isTrue);
      expect(out[0].unitsUsed, isNull);
      expect(out[0].cumulativeUsed, 0);

      // Second reading.
      expect(out[1].unitsUsed, 160);
      expect(out[1].daysGap, 4);
      expect(out[1].perDay, 40);
      expect(out[1].cumulativeUsed, 160);
    });

    test('manual override changes units + perDay', () {
      final out = calc.compute([
        r('a', 45000, '2026-06-15'),
        r('b', 45160, '2026-06-19', manual: 200),
      ]);
      expect(out[1].unitsUsed, 200);
      expect(out[1].perDay, 50);
      expect(out[1].isManual, isTrue);
    });

    test('negative diff (meter reset) is flagged invalid, no crash', () {
      final out = calc.compute([
        r('a', 45000, '2026-06-15'),
        r('b', 100, '2026-06-20'),
      ]);
      expect(out[1].invalid, isTrue);
    });

    test('invalid (negative) interval does not pollute totals/cumulative', () {
      final readings = [
        r('a', 30550, '2026-06-01'),
        r('b', 30560, '2026-06-02'), // +10
        r('c', 30500, '2026-06-03'), // drop -> invalid
      ];
      final out = calc.compute(readings);
      expect(out[2].invalid, isTrue);
      // Cumulative must not absorb the bad -60.
      expect(out[1].cumulativeUsed, 10);
      expect(out[2].cumulativeUsed, 10);
      // Summary total excludes the invalid interval.
      expect(calc.summarise(readings).totalUnitsUsed, 10);
    });

    test('sorts by date regardless of input order; gaps allowed', () {
      final out = calc.compute([
        r('b', 45160, '2026-06-19'),
        r('a', 45000, '2026-06-15'),
        r('c', 45200, '2026-06-20'),
      ]);
      expect(out.map((c) => c.reading.id).toList(), ['a', 'b', 'c']);
      expect(out[1].daysGap, 4); // 15 -> 19
      expect(out[2].daysGap, 1); // 19 -> 20
      expect(out[2].cumulativeUsed, 200); // 160 + 40
    });

    test('summary: total / span / average', () {
      final s = calc.summarise([
        r('a', 45000, '2026-06-15'),
        r('b', 45160, '2026-06-19'),
      ]);
      expect(s.totalUnitsUsed, 160);
      expect(s.totalDays, 4);
      expect(s.avgPerDay, 40);
    });

    test('empty + single reading are safe', () {
      expect(calc.compute([]), isEmpty);
      final one = calc.compute([r('a', 45000, '2026-06-15')]);
      expect(one.single.isBaseline, isTrue);
      final s = calc.summarise([r('a', 45000, '2026-06-15')]);
      expect(s.totalUnitsUsed, 0);
      expect(s.avgPerDay, 0);
    });
  });
}
