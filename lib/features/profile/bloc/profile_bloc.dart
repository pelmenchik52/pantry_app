import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/analytics_service.dart';
import '../../auth/data/app_user.dart';
import '../../auth/data/auth_failure.dart';
import '../../auth/data/auth_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

/// Завантаження та редагування профілю: ім'я, фото, пароль,
/// підключення Google.
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required AuthRepository authRepository,
    AnalyticsService? analytics,
  })  : _repo = authRepository,
        _analytics = analytics ?? AnalyticsService.instance,
        super(const ProfileState()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileNameSubmitted>(_onName);
    on<ProfilePhotoSubmitted>(_onPhoto);
    on<ProfilePasswordChangeSubmitted>(_onPassword);
    on<ProfileGoogleLinkRequested>(_onLinkGoogle);
  }

  final AuthRepository _repo;
  final AnalyticsService _analytics;

  // ------------------------------------------------------ завантаження ------

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      // Свіжі дані із сервера; за відсутності мережі лишається кеш SDK.
      await _repo.reloadUser();
    } on AuthFailure {
      // Не критично: показуємо дані, які вже є на пристрої.
    }
    final profile = _currentProfile();
    if (profile == null) {
      emit(state.copyWith(
        status: ProfileStatus.failure,
        errorSection: ProfileOperation.none,
        error: 'Сеанс завершено. Увійдіть знову.',
      ));
      return;
    }
    emit(state.copyWith(status: ProfileStatus.loaded, profile: profile));
  }

  // ------------------------------------------------------ редагування ------

  Future<void> _onName(
    ProfileNameSubmitted event,
    Emitter<ProfileState> emit,
  ) {
    return _perform(
      emit,
      ProfileOperation.savingName,
      successMessage: 'Дані збережено',
      action: () async {
        await _repo.updateProfile(displayName: event.name.trim());
        await _analytics.logEvent('profile_name_updated');
      },
    );
  }

  Future<void> _onPhoto(
    ProfilePhotoSubmitted event,
    Emitter<ProfileState> emit,
  ) {
    return _perform(
      emit,
      ProfileOperation.savingPhoto,
      successMessage: 'Фото профілю оновлено',
      action: () async {
        await _repo.updateProfile(photoUrl: event.photoUrl.trim());
        await _analytics.logEvent('profile_photo_updated');
      },
    );
  }

  Future<void> _onPassword(
    ProfilePasswordChangeSubmitted event,
    Emitter<ProfileState> emit,
  ) {
    return _perform(
      emit,
      ProfileOperation.changingPassword,
      successMessage: 'Пароль змінено',
      action: () async {
        await _repo.changePassword(
          currentPassword: event.currentPassword,
          newPassword: event.newPassword,
        );
        await _analytics.logEvent('password_changed');
      },
    );
  }

  Future<void> _onLinkGoogle(
    ProfileGoogleLinkRequested event,
    Emitter<ProfileState> emit,
  ) {
    return _perform(
      emit,
      ProfileOperation.linkingGoogle,
      successMessage: 'Google підключено до акаунту',
      action: () async {
        await _repo.linkGoogle();
        await _analytics.logEvent('google_linked');
      },
    );
  }

  // ------------------------------------------------------- службове --------

  AppUser? _currentProfile() {
    final user = _repo.currentUser;
    return user == null ? null : AppUser.fromFirebase(user);
  }

  Future<void> _perform(
    Emitter<ProfileState> emit,
    ProfileOperation operation, {
    required String successMessage,
    required Future<void> Function() action,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(operation: operation, clearError: true));
    try {
      await action();
      emit(state.copyWith(
        operation: ProfileOperation.none,
        profile: _currentProfile(),
        message: successMessage,
        completedOperation: operation,
        messageId: state.messageId + 1,
      ));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        operation: ProfileOperation.none,
        errorSection: operation,
        // Закрите користувачем вікно Google — не помилка.
        error: failure.cancelled ? null : failure.message,
        needRelogin: failure.requiresRecentLogin,
      ));
    }
  }
}
