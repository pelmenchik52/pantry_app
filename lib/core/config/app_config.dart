/// Конфігурація застосунку.
///
/// DSN Sentry можна передати під час запуску:
///   flutter run -d chrome --dart-define=SENTRY_DSN=https://xxx@oXXX.ingest.sentry.io/XXX
/// або вписати значення за замовчуванням нижче.
/// Якщо DSN порожній — Sentry вимкнений і застосунок працює як раніше.
class AppConfig {
  AppConfig._();

  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://5c87aa2325e5fe3e68bbbca88d0a58fb@o4512338944655360.ingest.de.sentry.io/4512338954813520', // <-- сюди можна вставити DSN із Sentry.io
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
}
