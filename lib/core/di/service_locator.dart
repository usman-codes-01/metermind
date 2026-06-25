import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../features/readings/readings_cubit.dart';
import '../../features/readings/readings_repository.dart';

/// App-wide service locator. Call [init] once in `main` before `runApp`
/// (after `Firebase.initializeApp`).
final GetIt sl = GetIt.instance;

Future<void> init() async {
  // External.
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  // Readings.
  sl.registerLazySingleton<ReadingsRepository>(
      () => ReadingsRepository(sl(), sl()));

  // Single app-wide cubit (state shared across both screens).
  sl.registerLazySingleton<ReadingsCubit>(() => ReadingsCubit(sl()));
}
