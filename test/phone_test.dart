import 'package:avtotest_app/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';

TextEditingValue _type(String text) {
  return const UzPhoneInputFormatter().formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: text),
  );
}

void main() {
  group('UzPhone.normalize', () {
    test('accepts every shape a user might type', () {
      expect(UzPhone.normalize('901234567'), '998901234567');
      expect(UzPhone.normalize('998901234567'), '998901234567');
      expect(UzPhone.normalize('+998901234567'), '998901234567');
      expect(UzPhone.normalize('+998 90 123 45 67'), '998901234567');
    });

    test('rejects impossible numbers', () {
      expect(UzPhone.normalize(''), isNull);
      expect(UzPhone.normalize('12345'), isNull);
      expect(UzPhone.normalize('9012345678'), isNull, reason: '10 digits');
      // Operator codes never start with 0 or 1.
      expect(UzPhone.normalize('001234567'), isNull);
      expect(UzPhone.normalize('101234567'), isNull);
    });

    // THE `998` TRAP (docs/MOBILE-CONTENT-PROMPT.md §8): `99` is a live
    // operator code, so a genuine nine-digit local number can itself start
    // with `998`. Trimming by prefix instead of by length locked every
    // `99 8xx xx xx` subscriber out of registration on the website.
    test('keeps a local number that happens to start with 998', () {
      expect(UzPhone.normalize('998123456'), '998998123456');
      expect(UzPhone.normalize('99 812 34 56'), '998998123456');
    });
  });

  group('UzPhoneInputFormatter', () {
    test('groups digits as they are typed', () {
      expect(_type('901234567').text, '90 123 45 67');
      expect(_type('9012').text, '90 12');
    });

    test('drops a pasted country code', () {
      expect(_type('998901234567').text, '90 123 45 67');
      expect(_type('+998 90 123 45 67').text, '90 123 45 67');
    });

    test('does NOT eat the 998 of a nine-digit local number', () {
      // Nine digits already — nothing to strip, however it starts.
      expect(_type('998123456').text, '99 812 34 56');
      expect(UzPhone.normalize(_type('998123456').text), '998998123456');
    });

    test('caps at nine local digits', () {
      expect(_type('9012345678901').text, '90 123 45 67');
    });
  });

  group('identifier routing', () {
    test('a phone becomes the synthetic address, an email stays itself', () {
      expect(
        UzPhone.identifierToAuthEmail('901234567'),
        '998901234567@pro.com',
      );
      expect(
        UzPhone.identifierToAuthEmail('Someone@Example.COM'),
        'someone@example.com',
      );
      expect(UzPhone.identifierToAuthEmail('not an identifier'), isNull);
    });

    test('classify says out loud how the entry will be used', () {
      expect(UzPhone.classify('90 123 45 67'), IdentifierKind.phone);
      expect(UzPhone.classify('a@b.uz'), IdentifierKind.email);
      expect(UzPhone.classify(''), IdentifierKind.empty);
      expect(UzPhone.classify('12345'), IdentifierKind.invalid);
    });
  });

  group('display', () {
    test('the synthetic address is never what the user sees', () {
      expect(
        UzPhone.displayFromAuthEmail('998901234567@pro.com'),
        '+998 90 123 45 67',
      );
      // An ordinary email account returns null so the caller shows the
      // address itself instead.
      expect(UzPhone.displayFromAuthEmail('someone@gmail.com'), isNull);
    });
  });
}
