part of 'profile_bloc.dart';

sealed class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Завантажити дані профілю.
final class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

final class ProfileNameSubmitted extends ProfileEvent {
  const ProfileNameSubmitted(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ProfilePhotoSubmitted extends ProfileEvent {
  const ProfilePhotoSubmitted(this.photoUrl);

  final String photoUrl;

  @override
  List<Object?> get props => [photoUrl];
}

final class ProfilePasswordChangeSubmitted extends ProfileEvent {
  const ProfilePasswordChangeSubmitted({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  @override
  List<Object?> get props => [currentPassword, newPassword];
}

final class ProfileGoogleLinkRequested extends ProfileEvent {
  const ProfileGoogleLinkRequested();
}
