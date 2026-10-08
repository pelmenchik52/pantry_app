# Домашня комора — Flutter Web (Лабораторна №3)

UI без бекенду: вхід, реєстрація, відновлення пароля, лист надіслано,
головний екран (список/пошук/фільтри/додавання/редагування), профіль.
Дані захардкоджені (`lib/core/data/mock_data.dart`).

## Запуск (один раз створюємо web-обгортку)

```bash
flutter create --platforms=web --project-name pantry_app .   # у цій папці
rm -rf test                                                  # стандартний тест не потрібен
flutter pub get
flutter run -d chrome
```

> `flutter create .` не перезаписує вже наявні `lib/` та `pubspec.yaml`.

## Структура

```
lib/
├── main.dart
├── core/
│   ├── data/mock_data.dart
│   ├── models/product.dart
│   ├── theme/{app_colors,app_theme}.dart
│   ├── utils/formatters.dart
│   └── widgets/            # перевикористовувані віджети
│       ├── app_buttons.dart  app_card.dart  app_text_field.dart
│       ├── auth_scaffold.dart  category_chip.dart  product_row.dart
│       └── quantity_stepper.dart  stat_card.dart
└── features/
    ├── auth/{login,register,forgot_password,email_sent}_screen.dart
    ├── home/{home_screen,product_form}.dart
    └── profile/profile_screen.dart
```
