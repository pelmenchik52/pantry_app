import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/status_banner.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/bloc/auth_bloc.dart';
import '../auth/data/app_user.dart';
import '../auth/data/auth_repository.dart';
import 'avatar_presets.dart';
import 'bloc/profile_bloc.dart';

/// Профіль користувача: фото, ім'я, способи входу, зміна пароля, вихід.
/// Стан екрана веде [ProfileBloc], який створюється разом із маршрутом.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        authRepository: context.read<AuthRepository>(),
      )..add(const ProfileLoadRequested()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _nameKey = GlobalKey<FormState>();
  final _photoKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  // У віджеті лишаються лише контролери полів введення;
  // усе інше (дані, прапорці завантаження, помилки) — у ProfileBloc.
  final _name = TextEditingController();
  final _photoUrl = TextEditingController();
  final _email = TextEditingController();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreen('profile');
  }

  @override
  void dispose() {
    _name.dispose();
    _photoUrl.dispose();
    _email.dispose();
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  ProfileBloc get _bloc => context.read<ProfileBloc>();

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Заповнює поля даними профілю, коли вони завантажені.
  void _fillFields(AppUser? user) {
    _name.text = user?.displayName ?? '';
    _photoUrl.text = user?.photoUrl ?? '';
    _email.text = user?.email ?? '';
  }

  // ------------------------------------------------------------- дії -------

  void _saveName() {
    if (_bloc.state.isBusy) return;
    if (!(_nameKey.currentState?.validate() ?? false)) return;
    _bloc.add(ProfileNameSubmitted(_name.text));
  }

  void _savePhoto() {
    if (_bloc.state.isBusy) return;
    if (!(_photoKey.currentState?.validate() ?? false)) return;
    _bloc.add(ProfilePhotoSubmitted(_photoUrl.text));
  }

  void _changePassword() {
    if (_bloc.state.isBusy) return;
    if (!(_passwordKey.currentState?.validate() ?? false)) return;
    _bloc.add(ProfilePasswordChangeSubmitted(
      currentPassword: _current.text,
      newPassword: _new.text,
    ));
  }

  void _linkGoogle() {
    if (_bloc.state.isBusy) return;
    _bloc.add(const ProfileGoogleLinkRequested());
  }

  /// Вихід виконує AuthBloc; AuthGate після цього сам закриває екран.
  void _logout() {
    context.read<AuthBloc>().add(const AuthSignOutRequested());
  }

  /// Навмисна помилка для перевірки Sentry (аналог Crashlytics для Web).
  Future<void> _generateTestError() async {
    try {
      throw StateError('Тестова помилка Sentry (ЛР №4, Домашня комора)');
    } catch (e, st) {
      await Sentry.captureException(e, stackTrace: st);
      await AnalyticsService.instance.logEvent('test_error_generated');
      if (mounted) _toast('Тестову помилку надіслано в Sentry');
    }
  }

  // ------------------------------------------------------------- UI --------

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Профіль завантажено → заповнюємо поля.
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (prev, curr) =>
              prev.status != ProfileStatus.loaded &&
              curr.status == ProfileStatus.loaded,
          listener: (context, state) => _fillFields(state.profile),
        ),
        // Помилка виходу з акаунту → snackbar.
        BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, curr) =>
              prev.operation == AuthOperation.signOut &&
              curr.error != null &&
              prev.error != curr.error,
          listener: (context, state) => _toast(state.error!),
        ),
        // Успішна дія → snackbar (+ очищення полів пароля).
        BlocListener<ProfileBloc, ProfileState>(
          listenWhen: (prev, curr) => prev.messageId != curr.messageId,
          listener: (context, state) {
            if (state.completedOperation ==
                ProfileOperation.changingPassword) {
              _passwordKey.currentState?.reset();
              _current.clear();
              _new.clear();
              _confirm.clear();
            }
            if (state.message != null) _toast(state.message!);
          },
        ),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: BlocBuilder<ProfileBloc, ProfileState>(
                builder: (context, state) {
                  switch (state.status) {
                    case ProfileStatus.initial:
                    case ProfileStatus.loading:
                      return const Center(child: CircularProgressIndicator());
                    case ProfileStatus.failure:
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(state.error ?? 'Сталася помилка.',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.muted)),
                              const SizedBox(height: 14),
                              OutlineAppButton(
                                label: 'Назад',
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ),
                      );
                    case ProfileStatus.loaded:
                      return _buildContent(state);
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ProfileState state) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => prev.operation != curr.operation,
      builder: (context, auth) => _buildBody(
        state,
        signingOut: auth.operation == AuthOperation.signOut,
      ),
    );
  }

  Widget _buildBody(ProfileState state, {required bool signingOut}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 14),
          _buildSummary(state.profile),
          const SizedBox(height: 14),
          _buildPhotoCard(state),
          const SizedBox(height: 14),
          _buildPersonalCard(state),
          const SizedBox(height: 14),
          _buildProvidersCard(state),
          const SizedBox(height: 14),
          _buildPasswordCard(state),
          const SizedBox(height: 14),
          _buildDevCard(),
          const SizedBox(height: 14),
          OutlineAppButton(
            label: signingOut ? 'Вихід…' : 'Вийти з акаунту',
            fullWidth: true,
            color: AppColors.danger,
            borderColor: const Color(0x66E5594F),
            onPressed: signingOut ? null : _logout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          tooltip: 'Назад',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.muted),
        ),
        const Text('Профіль',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSummary(AppUser? user) {
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : 'Без імені';
    return AppCard(
      child: Column(
        children: [
          UserAvatar(photoUrl: user?.photoUrl, size: 64),
          const SizedBox(height: 12),
          Text(name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(user?.email ?? '—',
              textAlign: TextAlign.center,
              style: AppTheme.mono.copyWith(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(ProfileState state) {
    final saving = state.isBusyWith(ProfileOperation.savingPhoto);
    final error = state.errorFor(ProfileOperation.savingPhoto);
    return AppCard(
      child: Form(
        key: _photoKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Фото профілю', style: _title),
            const SizedBox(height: 6),
            const Text(
              'Оберіть готовий аватар або вставте власне HTTPS-посилання.',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final url in kAvatarPresets)
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: saving
                        ? null
                        : () => setState(() => _photoUrl.text = url),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _photoUrl.text.trim() == url
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: UserAvatar(photoUrl: url, size: 44),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Власне посилання на зображення',
              hint: 'https://…',
              controller: _photoUrl,
              keyboardType: TextInputType.url,
              enabled: !saving,
              validator: Validators.httpsUrl,
              onChanged: (_) => setState(() {}), // оновлює попередній перегляд
            ),
            if (_photoUrl.text.trim().startsWith('https://')) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  UserAvatar(photoUrl: _photoUrl.text.trim(), size: 48),
                  const SizedBox(width: 10),
                  const Text('Попередній перегляд',
                      style: TextStyle(fontSize: 10, color: AppColors.dim)),
                ],
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              StatusBanner(error),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Застосувати фото',
              fullWidth: false,
              isLoading: saving,
              onPressed: _savePhoto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard(ProfileState state) {
    final saving = state.isBusyWith(ProfileOperation.savingName);
    final error = state.errorFor(ProfileOperation.savingName);
    return AppCard(
      child: Form(
        key: _nameKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Особисті дані', style: _title),
            const SizedBox(height: 16),
            if (error != null) ...[
              StatusBanner(error),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Ім’я',
              controller: _name,
              enabled: !saving,
              textInputAction: TextInputAction.done,
              validator: Validators.name,
              onFieldSubmitted: (_) => _saveName(),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Електронна пошта',
              controller: _email,
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Зберегти',
              fullWidth: false,
              isLoading: saving,
              onPressed: _saveName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersCard(ProfileState state) {
    final hasPassword = state.profile?.hasPasswordProvider ?? false;
    final hasGoogle = state.profile?.hasGoogleProvider ?? false;
    final linking = state.isBusyWith(ProfileOperation.linkingGoogle);
    final linkError = state.errorFor(ProfileOperation.linkingGoogle);
    Widget row(String label, bool on) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(on ? Icons.check_circle : Icons.circle_outlined,
                  size: 15, color: on ? AppColors.ok : AppColors.dim),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Способи входу', style: _title),
          const SizedBox(height: 14),
          row('Електронна пошта та пароль', hasPassword),
          row('Google', hasGoogle),
          if (linkError != null) ...[
            const SizedBox(height: 4),
            StatusBanner(linkError),
          ],
          if (!hasGoogle) ...[
            const SizedBox(height: 8),
            OutlineAppButton(
              label: linking ? 'Підключення…' : 'Підключити Google',
              onPressed: linking ? null : _linkGoogle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordCard(ProfileState state) {
    final changing = state.isBusyWith(ProfileOperation.changingPassword);
    final error = state.errorFor(ProfileOperation.changingPassword);
    if (!(state.profile?.hasPasswordProvider ?? false)) {
      return const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Зміна пароля', style: _title),
            SizedBox(height: 10),
            Text(
              'Ви входите через Google, тому пароля в цього акаунту немає. '
              'Щоб створити пароль, скористайтесь «Забули пароль?» на екрані входу.',
              style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.5),
            ),
          ],
        ),
      );
    }
    return AppCard(
      child: Form(
        key: _passwordKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Зміна пароля', style: _title),
            const SizedBox(height: 16),
            if (error != null) ...[
              StatusBanner(error),
              if (state.needRelogin) ...[
                const SizedBox(height: 8),
                AppLink('Вийти та увійти знову', onTap: _logout),
              ],
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Поточний пароль',
              hint: '••••••••',
              controller: _current,
              obscureText: true,
              enabled: !changing,
              textInputAction: TextInputAction.next,
              validator: Validators.passwordRequired,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Новий пароль',
              hint: 'Мінімум 6 символів',
              controller: _new,
              obscureText: true,
              enabled: !changing,
              textInputAction: TextInputAction.next,
              validator: (v) =>
                  Validators.newPassword(v) ??
                  Validators.differentFrom(() => _current.text,
                      'Новий пароль має відрізнятись від поточного')(v),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Підтвердження нового пароля',
              hint: 'Повторіть пароль',
              controller: _confirm,
              obscureText: true,
              enabled: !changing,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _new.text),
              onFieldSubmitted: (_) => _changePassword(),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Змінити пароль',
              fullWidth: false,
              isLoading: changing,
              onPressed: _changePassword,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Інструменти розробника', style: _title),
          const SizedBox(height: 6),
          const Text(
            'Надсилає тестову помилку в Sentry (для звіту до ЛР №4).',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          OutlineAppButton(
            label: 'Згенерувати тестову помилку',
            color: AppColors.warn,
            borderColor: const Color(0x66E6B800),
            onPressed: _generateTestError,
          ),
        ],
      ),
    );
  }
}

const TextStyle _title = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
