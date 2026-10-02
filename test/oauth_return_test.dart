import 'package:avtotest_app/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// The Google return link (`uz.avtotestu.app://auth-callback…`) is read by
/// the app itself, so a failed sign-in can say why.
void main() {
  test('a code is picked up', () {
    final r = AuthProvider.parseOAuthReturn(
      Uri.parse('uz.avtotestu.app://auth-callback?code=abc-123'),
    );
    expect(r?.code, 'abc-123');
    expect(r?.error, isNull);
  });

  test('an error in the query is kept, readable', () {
    final r = AuthProvider.parseOAuthReturn(
      Uri.parse(
        'uz.avtotestu.app://auth-callback?error=server_error'
        '&error_description=Unable+to+exchange+external+code',
      ),
    );
    expect(r?.code, isNull);
    expect(r?.error, 'Unable to exchange external code');
  });

  test('an error in the fragment is kept too', () {
    final r = AuthProvider.parseOAuthReturn(
      Uri.parse('uz.avtotestu.app://auth-callback#error=access_denied'),
    );
    expect(r?.error, 'access_denied');
  });

  test('any other link is ignored', () {
    expect(
      AuthProvider.parseOAuthReturn(Uri.parse('https://avtotestu.uz/x?code=1')),
      isNull,
    );
    expect(
      AuthProvider.parseOAuthReturn(
        Uri.parse('uz.avtotestu.app://other?code=1'),
      ),
      isNull,
    );
  });

  group('Google sheet: cancel vs. refused', () {
    test('closing the sheet is a cancel', () {
      expect(
        AuthProvider.isUserCancel(
          GoogleSignInExceptionCode.canceled,
          'activity is cancelled by the user.',
        ),
        isTrue,
      );
    });
    test('a missing SHA-1 / client is NOT a cancel', () {
      for (final d in [
        '[16] Account reauth failed.',
        '[28444] Developer console is not set up correctly.',
      ]) {
        expect(
          AuthProvider.isUserCancel(GoogleSignInExceptionCode.canceled, d),
          isFalse,
          reason: d,
        );
      }
      expect(
        AuthProvider.isUserCancel(
          GoogleSignInExceptionCode.clientConfigurationError,
          null,
        ),
        isFalse,
      );
    });
  });
}
