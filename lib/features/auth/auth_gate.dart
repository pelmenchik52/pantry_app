import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/app_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../home/bloc/products_bloc.dart';
import '../home/data/local_product_repository.dart';
import '../home/data/product_repository.dart';
import '../home/home_screen.dart';
import 'bloc/auth_bloc.dart';
import 'login_screen.dart';

/// Кореневий екран: залежно від стану [AuthBloc] показує вхід або головну.
/// Саме тут відновлюється сеанс після перезапуску застосунку.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      // Вхід / вихід: прибираємо зі стеку всі екрани, відкриті поверх
      // кореневого (реєстрація, профіль, відновлення пароля).
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) =>
          Navigator.of(context).popUntil((route) => route.isFirst),
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.user?.uid != curr.user?.uid,
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.unknown:
            return const _RestoringSession();
          case AuthStatus.unauthenticated:
            return const LoginScreen();
          case AuthStatus.authenticated:
            final uid = state.user!.uid;
            // Список продуктів — окремий для кожного користувача,
            // тому репозиторій і BLoC створюються з ключем uid.
            return RepositoryProvider<ProductRepository>(
              key: ValueKey(uid),
              create: (context) => LocalProductRepository(
                preferences: context.read<AppPreferences>(),
                userId: uid,
              ),
              child: BlocProvider(
                create: (context) => ProductsBloc(
                  repository: context.read<ProductRepository>(),
                  preferences: context.read<AppPreferences>(),
                )..add(const ProductsLoadRequested()),
                child: const HomeScreen(),
              ),
            );
        }
      },
    );
  }
}

class _RestoringSession extends StatelessWidget {
  const _RestoringSession();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Відновлення сеансу…',
                style: TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
