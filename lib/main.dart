import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/bloc/app_bloc_observer.dart';
import 'core/config/app_config.dart';
import 'core/storage/app_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_gate.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
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
      // Локальне сховище та глобальний спостерігач за BLoC.
      final preferences = await AppPreferences.init();
      Bloc.observer = AppBlocObserver();
      runApp(SentryWidget(child: PantryApp(preferences: preferences)));
    },
  );
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key, required this.preferences});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    // Репозиторії та AuthBloc створюються над MaterialApp, тому доступні
    // на всіх екранах, зокрема тих, що відкриваються через Navigator.push.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: AuthRepository.instance),
        RepositoryProvider<AppPreferences>.value(value: preferences),
      ],
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: context.read<AuthRepository>(),
          preferences: context.read<AppPreferences>(),
        )..add(const AuthSubscriptionRequested()),
        child: _buildApp(),
      ),
    );
  }

  Widget _buildApp() {
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
