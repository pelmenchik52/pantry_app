part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Яка саме операція зараз виконується (для індикаторів завантаження).
enum AuthOperation { none, signIn, signUp, google, passwordReset, signOut }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.operation = AuthOperation.none,
    this.error,
    this.resetEmailSent = false,
  });

  /// `unknown` — сеанс ще відновлюється; далі `authenticated` / `unauthenticated`.
  final AuthStatus status;
  final AppUser? user;
  final AuthOperation operation;

  /// Текст помилки для показу в інтерфейсі.
  final String? error;

  /// Лист для скидання пароля успішно надіслано.
  final bool resetEmailSent;

  bool get isBusy => operation != AuthOperation.none;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool clearUser = false,
    AuthOperation? operation,
    String? error,
    bool clearError = false,
    bool? resetEmailSent,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      operation: operation ?? this.operation,
      error: clearError ? null : (error ?? this.error),
      resetEmailSent: resetEmailSent ?? this.resetEmailSent,
    );
  }

  @override
  List<Object?> get props => [status, user, operation, error, resetEmailSent];
}
