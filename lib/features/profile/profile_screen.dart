import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
import '../auth/data/auth_failure.dart';
import '../auth/data/auth_repository.dart';
import 'avatar_presets.dart';

/// Профіль користувача: фото, ім'я, способи входу, зміна пароля, вихід.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = AuthRepository.instance;

  final _nameKey = GlobalKey<FormState>();
  final _photoKey = GlobalKey<FormState>();
  final _passwordKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _photoUrl;
  late final TextEditingController _email;
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _savingName = false;
  bool _savingPhoto = false;
  bool _changingPassword = false;
  bool _linking = false;
  bool _signingOut = false;

  String? _nameError;
  String? _photoError;
  String? _passwordError;
  String? _linkError;
  bool _needRelogin = false;

  @override
  void initState() {
    super.initState();
    final user = _repo.currentUser;
    _name = TextEditingController(text: user?.displayName ?? '');
    _photoUrl = TextEditingController(text: user?.photoURL ?? '');
    _email = TextEditingController(text: user?.email ?? '');
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

  void _toast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ------------------------------------------------------------- дії -------

  Future<void> _saveName() async {
    if (_savingName) return;
    if (!(_nameKey.currentState?.validate() ?? false)) return;
    setState(() {
      _savingName = true;
      _nameError = null;
    });
    try {
      await _repo.updateProfile(displayName: _name.text.trim());
      await AnalyticsService.instance.logEvent('profile_name_updated');
      if (mounted) _toast('Дані збережено');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _nameError = e.message);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePhoto() async {
    if (_savingPhoto) return;
    if (!(_photoKey.currentState?.validate() ?? false)) return;
    setState(() {
      _savingPhoto = true;
      _photoError = null;
    });
    try {
      await _repo.updateProfile(photoUrl: _photoUrl.text.trim());
      await AnalyticsService.instance.logEvent('profile_photo_updated');
      if (mounted) _toast('Фото профілю оновлено');
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _photoError = e.message);
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _changePassword() async {
    if (_changingPassword) return;
    if (!(_passwordKey.currentState?.validate() ?? false)) return;
    setState(() {
      _changingPassword = true;
      _passwordError = null;
      _needRelogin = false;
    });
    try {
      await _repo.changePassword(
        currentPassword: _current.text,
        newPassword: _new.text,
      );
      await AnalyticsService.instance.logEvent('password_changed');
      if (!mounted) return;
      _passwordKey.currentState?.reset();
      _current.clear();
      _new.clear();
      _confirm.clear();
      _toast('Пароль змінено');
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _passwordError = e.message;
          _needRelogin = e.requiresRecentLogin;
        });
      }
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _linkGoogle() async {
    if (_linking) return;
    setState(() {
      _linking = true;
      _linkError = null;
    });
    try {
      await _repo.linkGoogle();
      await AnalyticsService.instance.logEvent('google_linked');
      if (mounted) _toast('Google підключено до акаунту');
    } on AuthFailure catch (e) {
      if (mounted && !e.cancelled) setState(() => _linkError = e.message);
    } finally {
      if (mounted) setState(() => _linking = false);
    }
  }

  Future<void> _logout() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await AnalyticsService.instance.logEvent('logout');
      await _repo.signOut();
      // AuthGate покаже екран входу; прибираємо зі стеку цей екран.
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() => _signingOut = false);
        _toast(e.message);
      }
    }
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: StreamBuilder<User?>(
              stream: _repo.userChanges(),
              initialData: _repo.currentUser,
              builder: (context, snapshot) {
                final user = snapshot.data ?? _repo.currentUser;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      const SizedBox(height: 14),
                      _buildSummary(user),
                      const SizedBox(height: 14),
                      _buildPhotoCard(),
                      const SizedBox(height: 14),
                      _buildPersonalCard(),
                      const SizedBox(height: 14),
                      _buildProvidersCard(),
                      const SizedBox(height: 14),
                      _buildPasswordCard(),
                      const SizedBox(height: 14),
                      _buildDevCard(),
                      const SizedBox(height: 14),
                      OutlineAppButton(
                        label: _signingOut ? 'Вихід…' : 'Вийти з акаунту',
                        fullWidth: true,
                        color: AppColors.danger,
                        borderColor: const Color(0x66E5594F),
                        onPressed: _signingOut ? null : _logout,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
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

  Widget _buildSummary(User? user) {
    final name = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!
        : 'Без імені';
    return AppCard(
      child: Column(
        children: [
          UserAvatar(photoUrl: user?.photoURL, size: 64),
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

  Widget _buildPhotoCard() {
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
                    onTap: _savingPhoto
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
              enabled: !_savingPhoto,
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
            if (_photoError != null) ...[
              const SizedBox(height: 12),
              StatusBanner(_photoError!),
            ],
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Застосувати фото',
              fullWidth: false,
              isLoading: _savingPhoto,
              onPressed: _savePhoto,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalCard() {
    return AppCard(
      child: Form(
        key: _nameKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Особисті дані', style: _title),
            const SizedBox(height: 16),
            if (_nameError != null) ...[
              StatusBanner(_nameError!),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: 'Ім’я',
              controller: _name,
              enabled: !_savingName,
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
              isLoading: _savingName,
              onPressed: _saveName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProvidersCard() {
    final hasPassword = _repo.hasPasswordProvider;
    final hasGoogle = _repo.hasGoogleProvider;
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
          if (_linkError != null) ...[
            const SizedBox(height: 4),
            StatusBanner(_linkError!),
          ],
          if (!hasGoogle) ...[
            const SizedBox(height: 8),
            OutlineAppButton(
              label: _linking ? 'Підключення…' : 'Підключити Google',
              onPressed: _linking ? null : _linkGoogle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    if (!_repo.hasPasswordProvider) {
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
            if (_passwordError != null) ...[
              StatusBanner(_passwordError!),
              if (_needRelogin) ...[
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
              enabled: !_changingPassword,
              textInputAction: TextInputAction.next,
              validator: Validators.passwordRequired,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Новий пароль',
              hint: 'Мінімум 6 символів',
              controller: _new,
              obscureText: true,
              enabled: !_changingPassword,
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
              enabled: !_changingPassword,
              textInputAction: TextInputAction.done,
              validator: Validators.confirmPassword(() => _new.text),
              onFieldSubmitted: (_) => _changePassword(),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Змінити пароль',
              fullWidth: false,
              isLoading: _changingPassword,
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
