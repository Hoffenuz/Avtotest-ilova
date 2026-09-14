import 'package:avtotest_app/config/supabase_config.dart';
import 'package:avtotest_app/services/payme_service.dart';
import 'package:avtotest_app/utils/phone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UzPhone.normalize', () {
    test('accepts the three formats users actually type', () {
      const expected = '998901234567';
      expect(UzPhone.normalize('901234567'), expected);
      expect(UzPhone.normalize('998901234567'), expected);
      expect(UzPhone.normalize('+998901234567'), expected);
      expect(UzPhone.normalize('+998 90 123 45 67'), expected);
    });

    test('rejects wrong lengths and invalid operator codes', () {
      expect(UzPhone.normalize('12345'), isNull);
      expect(UzPhone.normalize('9989012345678'), isNull);
      expect(UzPhone.normalize('001234567'), isNull); // starts with 0
      expect(UzPhone.normalize('101234567'), isNull); // starts with 1
      expect(UzPhone.normalize(''), isNull);
      expect(UzPhone.normalize(null), isNull);
    });
  });

  group('identifier → auth email', () {
    test('phone becomes the synthetic address', () {
      expect(
        UzPhone.identifierToAuthEmail('90 123 45 67'),
        '998901234567@pro.com',
      );
    });

    test('legacy email is lower-cased and kept as-is', () {
      expect(
        UzPhone.identifierToAuthEmail('  User@Example.COM '),
        'user@example.com',
      );
    });
  });

  group('display', () {
    test('synthetic address renders as a phone number', () {
      expect(
        UzPhone.displayFromAuthEmail('998901234567@pro.com'),
        '+998 90 123 45 67',
      );
    });

    test('ordinary email has no phone form', () {
      expect(UzPhone.displayFromAuthEmail('user@example.com'), isNull);
    });

    test('formats digits while typing', () {
      expect(UzPhone.formatLocal('901234567'), '90 123 45 67');
      expect(UzPhone.formatLocal('9012'), '90 12');
    });
  });

  group('Payme checkout link', () {
    test('encodes the official documentation example exactly', () {
      // From Payme's docs — if this fails, the base64/UTF-8 handling is wrong.
      const raw = 'm=587f72c72cac0d162c722ae2;ac.order_id=197;a=500';
      const expected =
          'bT01ODdmNzJjNzJjYWMwZDE2MmM3MjJhZTI7YWMub3JkZXJfaWQ9MTk3O2E9NTAw';
      expect(PaymeService.encodeParams(raw), expected);
    });

    test('builds a link with merchant, account, amount, language, return', () {
      final url = PaymeService.buildCheckoutUrl(
        accountEmail: '998901234567@pro.com',
        amountTiyin: 3500000,
        lang: 'uz_lat',
      );

      expect(url, startsWith(SupabaseConfig.paymeCheckoutBase));
      expect(
        PaymeService.decodeCheckoutUrl(url),
        'm=${SupabaseConfig.paymeMerchantId};'
        'ac.email=998901234567@pro.com;'
        'a=3500000;l=uz;c=${SupabaseConfig.paymeReturnUrl}',
      );
    });

    test('passes the Russian interface through', () {
      final url = PaymeService.buildCheckoutUrl(
        accountEmail: 'user@example.com',
        amountTiyin: 1500000,
        lang: 'ru',
      );
      expect(PaymeService.decodeCheckoutUrl(url), contains(';l=ru;'));
    });
  });

  group('PaymePlan', () {
    test('converts tiyin to a readable som amount', () {
      const plan = PaymePlan(
        planName: 'monthly',
        amountTiyin: 3500000,
        tariffDays: 30,
      );
      expect(plan.amountSom, 35000);
      expect(plan.formattedSom, '35 000');
    });
  });
}
