import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/widgets/phone_frame.dart';
import 'features/auth/auth_gate.dart';
import 'features/readings/readings_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  runApp(const MeterMindApp());
}

class MeterMindApp extends StatelessWidget {
  const MeterMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeController()),
        // Single app-wide cubit; AuthGate triggers load() once signed in.
        BlocProvider<ReadingsCubit>.value(value: di.sl<ReadingsCubit>()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'MeterMind',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: theme.mode,
            // Every screen lives inside the 390×830 phone frame.
            builder: (context, child) => PhoneFrame(child: child ?? const SizedBox()),
            // Login gate → app once signed in.
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
