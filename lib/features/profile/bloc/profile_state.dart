part of 'profile_bloc.dart';

enum ProfileStatus { initial, loading, loaded, failure }

/// Яка операція виконується / до якого блоку екрана належить помилка.
enum ProfileOperation {
  none,
  savingName,
  savingPhoto,
  changingPassword,
  linkingGoogle,
}

final class ProfileState extends Equatable {
  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.operation = ProfileOperation.none,
    this.errorSection = ProfileOperation.none,
    this.error,
    this.needRelogin = false,
    this.message,
    this.completedOperation = ProfileOperation.none,
    this.messageId = 0,
  });

  final ProfileStatus status;
  final AppUser? profile;

  /// Операція, що виконується зараз.
  final ProfileOperation operation;

  /// Блок екрана, до якого належить [error].
  final ProfileOperation errorSection;
  final String? error;

  /// Firebase вимагає свіжого входу (зміна пароля).
  final bool needRelogin;

  /// Одноразове повідомлення про успіх (snackbar). [messageId] росте щоразу,
  /// тому однакові повідомлення підряд теж спрацьовують.
  final String? message;
  final ProfileOperation completedOperation;
  final int messageId;

  bool get isBusy => operation != ProfileOperation.none;

  bool isBusyWith(ProfileOperation op) => operation == op;

  /// Помилка конкретного блоку (або `null`).
  String? errorFor(ProfileOperation section) =>
      errorSection == section ? error : null;

  ProfileState copyWith({
    ProfileStatus? status,
    AppUser? profile,
    ProfileOperation? operation,
    ProfileOperation? errorSection,
    String? error,
    bool needRelogin = false,
    bool clearError = false,
    String? message,
    ProfileOperation? completedOperation,
    int? messageId,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      operation: operation ?? this.operation,
      errorSection: clearError
          ? ProfileOperation.none
          : (errorSection ?? this.errorSection),
      error: clearError ? null : (error ?? this.error),
      needRelogin: clearError ? false : (needRelogin || this.needRelogin),
      message: message ?? this.message,
      completedOperation: completedOperation ?? this.completedOperation,
      messageId: messageId ?? this.messageId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        profile,
        operation,
        errorSection,
        error,
        needRelogin,
        message,
        completedOperation,
        messageId,
      ];
}
