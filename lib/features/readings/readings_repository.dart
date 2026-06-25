import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'reading.dart';

/// Reads/writes readings + the monthly target directly in Cloud Firestore,
/// scoped to the signed-in user. No server: always-on and offline-cached.
///
/// Layout (per user):
///   users/{uid}/readings/{autoId}        { meterReading, date, manualUnits, note, createdAt }
///   users/{uid}/settings/monthlyTarget   { value: int }
class ReadingsRepository {
  ReadingsRepository(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // Safe because every repository call happens behind the auth gate (logged in).
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_auth.currentUser!.uid);

  CollectionReference<Map<String, dynamic>> get _readings =>
      _userDoc.collection('readings');
  DocumentReference<Map<String, dynamic>> get _targetDoc =>
      _userDoc.collection('settings').doc('monthlyTarget');

  Future<List<Reading>> getReadings() async {
    final snap = await _readings.get();
    return snap.docs.map((d) => _toReading(d.id, d.data())).toList();
  }

  Future<Reading> addReading({
    required int meterReading,
    required String date,
    String? note,
  }) async {
    final doc = await _readings.add({
      'meterReading': meterReading,
      'date': date,
      'manualUnits': null,
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final snap = await doc.get();
    return _toReading(snap.id, snap.data()!);
  }

  Future<Reading> updateReading(Reading r) async {
    await _readings.doc(r.id).update({
      'meterReading': r.meterReading,
      'date': r.dateKey,
      'manualUnits': r.manualUnits,
      'note': r.note,
    });
    final snap = await _readings.doc(r.id).get();
    return _toReading(snap.id, snap.data()!);
  }

  /// Set (or clear, with null) the manual override.
  Future<Reading> setManualUnits(String id, int? manualUnits) async {
    await _readings.doc(id).update({'manualUnits': manualUnits});
    final snap = await _readings.doc(id).get();
    return _toReading(snap.id, snap.data()!);
  }

  Future<void> deleteReading(String id) async {
    await _readings.doc(id).delete();
  }

  Future<int?> getMonthlyTarget() async {
    final snap = await _targetDoc.get();
    final value = snap.data()?['value'];
    return value == null ? null : (value as num).toInt();
  }

  Future<void> setMonthlyTarget(int? value) async {
    if (value == null) {
      await _targetDoc.delete();
    } else {
      await _targetDoc.set({'value': value});
    }
  }

  Reading _toReading(String id, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return Reading(
      id: id,
      meterReading: (data['meterReading'] as num).toInt(),
      date: DateTime.parse(data['date'] as String),
      manualUnits:
          data['manualUnits'] == null ? null : (data['manualUnits'] as num).toInt(),
      note: (data['note'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
