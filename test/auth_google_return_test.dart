import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:avtotest_app/providers/language_provider.dart';
import 'package:avtotest_app/providers/settings_provider.dart';
import 'package:avtotest_app/providers/subscription_provider.dart';
import 'package:avtotest_app/providers/theme_provider.dart';
import 'package:avtotest_app/screens/auth_screen.dart';
import 'package:avtotest_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Signs in "from outside" — the way a Google session arrives through the
/// deep link while the sign-in screen is open.
class _FakeAuth extends AuthProvider {
  bool _in = false;
  @override
  bool get isLoggedIn => _in;
  void arrive() {
    _in = true;
    notifyListeners();
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a session arriving from Google closes the modal sign-in', (
    tester,
  ) async {
    final auth = _FakeAuth();
    bool? result;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthScreen(isModal: true),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);

    auth.arrive();
    await tester.pumpAndSettle();

    expect(find.byType(AuthScreen), findsNothing);
    expect(result, isTrue, reason: 'the caller (e.g. PRO purchase) goes on');
  });
}
