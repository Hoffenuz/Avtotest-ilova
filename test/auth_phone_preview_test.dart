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

/// A typed phone number is shown back in full, so the user sees exactly
/// which number they are signing in or registering with.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, {bool signUp = false}) async {
    tester.view.physicalSize = const Size(360, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: AuthScreen(startOnSignUp: signUp),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sign-in: 887778877 reads back as +998 88 777 88 77', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '887778877');
    await tester.pump();
    expect(find.textContaining('+998 88 777 88 77'), findsOneWidget);
  });

  testWidgets('sign-in: an incomplete number shows no full form', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).first, '8877788');
    await tester.pump();
    expect(find.textContaining('+998'), findsNothing);
  });

  testWidgets('sign-up: the phone field reads back in full too', (
    tester,
  ) async {
    await pump(tester, signUp: true);
    await tester.enterText(find.byType(TextFormField).first, '887778877');
    await tester.pump();
    expect(find.textContaining('+998 88 777 88 77'), findsOneWidget);
  });
}
