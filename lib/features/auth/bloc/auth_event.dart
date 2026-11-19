part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Почати слухати стан Firebase Auth (відправляється один раз при старті).
final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

final class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

/// Вхід через Google; [isSignUp] впливає лише на подію аналітики.
final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested({this.isSignUp = false});

  final bool isSignUp;

  @override
  List<Object?> get props => [isSignUp];
}

final class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Прибрати повідомлення про помилку та ознаку «лист надіслано».
final class AuthFeedbackCleared extends AuthEvent {
  const AuthFeedbackCleared();
}
