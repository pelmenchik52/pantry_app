import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Sentry перехоплює необроблені помилки Flutter і Dart (аналог Crashlytics
  // для Web, де Firebase Crashlytics не підтримується).
  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.sentryDsn; // порожній DSN = Sentry вимкнено
      options.environment = AppConfig.environment;
      options.tracesSampleRate = 1.0;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      runApp(SentryWidget(child: const PantryApp()));
    },
  );
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Домашня комора',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('uk'),
      supportedLocales: const [Locale('uk'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Вхід або головний екран залежно від стану Firebase Auth.
      home: const AuthGate(),
    );
  }
}
