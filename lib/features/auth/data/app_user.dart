import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Незмінна копія даних користувача Firebase.
///
/// Об'єкт `User` з Firebase — змінюваний і не порівнюється за значенням,
/// тому BLoC не помітив би зміну імені чи фото. [AppUser] порівнюється
/// за полями (Equatable), і стан оновлюється лише за реальних змін.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.providerIds = const [],
  });

  factory AppUser.fromFirebase(User user) => AppUser(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        providerIds: [for (final p in user.providerData) p.providerId],
      );

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  /// Способи входу: `password`, `google.com`.
  final List<String> providerIds;

  bool get hasPasswordProvider => providerIds.contains('password');
  bool get hasGoogleProvider => providerIds.contains('google.com');

  /// Ім'я для привітання: displayName → частина пошти → «користувач».
  String get greetingName {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final mail = email;
    if (mail != null && mail.contains('@')) return mail.split('@').first;
    return 'користувач';
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl, providerIds];
}
