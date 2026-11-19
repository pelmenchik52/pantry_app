import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/storage/app_preferences.dart';
import '../data/app_user.dart';
import '../data/auth_failure.dart';
import '../data/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Керує станом авторизації: реєстрація, вхід (email / Google),
/// скидання пароля, вихід, відновлення сеансу після перезапуску.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository authRepository,
    required AppPreferences preferences,
    AnalyticsService? analytics,
  })  : _repo = authRepository,
        _prefs = preferences,
        _analytics = analytics ?? AnalyticsService.instance,
        super(const AuthState()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleSignInRequested>(_onGoogleSignIn);
    on<AuthPasswordResetRequested>(_onPasswordReset);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthFeedbackCleared>(_onFeedbackCleared);
  }

  final AuthRepository _repo;
  final AppPreferences _prefs;
  final AnalyticsService _analytics;

  String? _monitoredUid;

  // ------------------------------------------------ стан сеансу ------------

  /// Підписка на Firebase Auth. Саме звідси відновлюється сеанс
  /// після перезапуску застосунку (токен зберігає SDK).
  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) {
    return emit.onEach<User?>(
      _repo.userChanges(),
      onData: (user) {
        _syncMonitoring(user);
        if (user == null) {
          emit(state.copyWith(
            status: AuthStatus.unauthenticated,
            clearUser: true,
          ));
        } else {
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: AppUser.fromFirebase(user),
          ));
        }
      },
      onError: (error, stackTrace) {
        addError(error, stackTrace);
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
        ));
      },
    );
  }

  /// Побічні ефекти: аналітика та контекст Sentry (лише за зміни користувача).
  void _syncMonitoring(User? user) {
    if (user?.uid == _monitoredUid) return;
    _monitoredUid = user?.uid;
    _analytics.setUser(user?.uid);
    Sentry.configureScope(
      (scope) => scope.setUser(
        user == null ? null : SentryUser(id: user.uid, email: user.email),
      ),
    );
  }

  // ------------------------------------------------------ дії ---------------

  Future<void> _onSignIn(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) {
    return _perform(emit, AuthOperation.signIn, () async {
      await _repo.signIn(email: event.email, password: event.password);
      await _analytics.logLogin('password');
      await _prefs.setLastEmail(event.email.trim());
    });
  }

  Future<void> _onSignUp(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) {
    return _perform(emit, AuthOperation.signUp, () async {
      await _repo.signUp(
        email: event.email,
        password: event.password,
        displayName: event.name,
      );
      await _analytics.logSignUp('password');
      await _prefs.setLastEmail(event.email.trim());
    });
  }

  Future<void> _onGoogleSignIn(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) {
    return _perform(emit, AuthOperation.google, () async {
      await _repo.signInWithGoogle();
      if (event.isSignUp) {
        await _analytics.logSignUp('google');
      } else {
        await _analytics.logLogin('google');
      }
    });
  }

  Future<void> _onPasswordReset(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) {
    return _perform(
      emit,
      AuthOperation.passwordReset,
      () async {
        await _repo.sendPasswordResetEmail(email: event.email);
        await _analytics.logEvent('password_reset_requested');
      },
      resetEmailSent: true,
    );
  }

  Future<void> _onSignOut(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) {
    return _perform(emit, AuthOperation.signOut, () async {
      await _analytics.logEvent('logout');
      await _repo.signOut();
    });
  }

  void _onFeedbackCleared(AuthFeedbackCleared event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearError: true, resetEmailSent: false));
  }

  /// Спільна схема: «зайнято» → дія → успіх або повідомлення про помилку.
  Future<void> _perform(
    Emitter<AuthState> emit,
    AuthOperation operation,
    Future<void> Function() action, {
    bool resetEmailSent = false,
  }) async {
    if (state.isBusy) return; // захист від подвійного натискання
    emit(state.copyWith(
      operation: operation,
      clearError: true,
      resetEmailSent: false,
    ));
    try {
      await action();
      emit(state.copyWith(
        operation: AuthOperation.none,
        resetEmailSent: resetEmailSent,
      ));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        operation: AuthOperation.none,
        // Закрите користувачем вікно Google — не помилка.
        error: failure.cancelled ? null : failure.message,
      ));
    }
  }
}
