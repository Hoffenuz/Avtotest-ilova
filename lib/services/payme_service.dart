import 'dart:convert';

import '../config/supabase_config.dart';
import 'supabase_service.dart';

/// One purchasable tariff, exactly as stored in `payme_plans`.
///
/// Prices are never hard-coded in the app: Payme rejects a transaction whose
/// amount doesn't match what the merchant's server expects (`-31001`), so the
/// amount has to come from the same row the `payme` Edge Function validates
/// against.
class PaymePlan {
  final String planName;
  final int amountTiyin;
  final int tariffDays;

  const PaymePlan({
    required this.planName,
    required this.amountTiyin,
    required this.tariffDays,
  });

  factory PaymePlan.fromRow(Map<String, dynamic> row) => PaymePlan(
    planName: row['plan_name'] as String,
    amountTiyin: (row['amount_tiyin'] as num).toInt(),
    tariffDays: (row['tariff_days'] as num).toInt(),
  );

  int get amountSom => amountTiyin ~/ 100;

  /// `35000` → `35 000`
  String get formattedSom {
    final digits = amountSom.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class PaymeService {
  PaymeService._();

  /// Active tariffs, cheapest first. Readable with the anon key —
  /// `payme_plans` has a public SELECT policy limited to `is_active = true`.
  static Future<List<PaymePlan>> fetchPlans() async {
    final rows = await SupabaseService.client
        .from('payme_plans')
        .select('plan_name, amount_tiyin, tariff_days')
        .eq('is_active', true);

    final plans =
        (rows as List<dynamic>)
            .map((row) => PaymePlan.fromRow(row as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.tariffDays.compareTo(b.tariffDays));
    return plans;
  }

  /// Builds a Payme checkout link.
  ///
  /// Payme's GET form takes `key=value` pairs joined by `;` and base64-encoded
  /// (UTF-8 safe). The account field is `email` because that is how this
  /// merchant's kassa is configured — for phone accounts it carries the
  /// synthetic `998XXXXXXXXX@pro.com` address, which is what the `payme`
  /// Edge Function looks the user up by.
  static String buildCheckoutUrl({
    required String accountEmail,
    required int amountTiyin,
    required String lang,
  }) {
    final params = <String>[
      'm=${SupabaseConfig.paymeMerchantId}',
      'ac.email=$accountEmail',
      'a=$amountTiyin',
      'l=${paymeLanguage(lang)}',
      'c=${SupabaseConfig.paymeReturnUrl}',
    ].join(';');

    return SupabaseConfig.paymeCheckoutBase + encodeParams(params);
  }

  /// UTF-8 safe base64 of a Payme parameter string. Verified against the
  /// example in Payme's documentation by `test/payment_integration_test.dart`.
  static String encodeParams(String params) =>
      base64.encode(utf8.encode(params));

  /// Inverse of [encodeParams]; used by tests and for debugging a link.
  static String decodeCheckoutUrl(String url) {
    final encoded = url.substring(SupabaseConfig.paymeCheckoutBase.length);
    return utf8.decode(base64.decode(encoded));
  }

  /// App language code → Payme interface language.
  static String paymeLanguage(String appLang) {
    switch (appLang) {
      case 'ru':
        return 'ru';
      case 'en':
        return 'en';
      default:
        return 'uz';
    }
  }
}
