import 'supabase_service.dart';

/// Click (my.click.uz) checkout — the app's copy of the website's
/// `src/lib/click.ts`. Like Payme, NOTHING here grants PRO:
///
///   1. `click_create_order` creates the order on the server. The price comes
///      from `payme_plans` there; the app never sets an amount.
///   2. The user pays on Click's page with that order id as
///      `transaction_param`.
///   3. Click calls the `click` Edge Function (Prepare/Complete, signed with
///      the secret key kept only in Supabase Vault); PRO is written on
///      Complete, and the app only re-reads it afterwards.
class ClickService {
  ClickService._();

  static const String _payUrl = 'https://my.click.uz/services/pay';

  /// Cashbox ids — not secret, they travel in the payment link (the site's
  /// VITE_CLICK_* values).
  static const String serviceId = '112576';
  static const String merchantId = '57313';
  static const String merchantUserId = '91937';

  static final RegExp _orderId = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  /// Tiyin → the "N.NN" Click expects, without floating-point rounding.
  static String formatTiyin(int amountTiyin) {
    final som = amountTiyin ~/ 100;
    final tiyin = (amountTiyin % 100).toString().padLeft(2, '0');
    return '$som.$tiyin';
  }

  /// Null when the order id or amount is not something the server would have
  /// produced — better no link than a link to the wrong payment.
  static String? buildPayUrl({
    required String orderId,
    required int amountTiyin,
    required String returnUrl,
  }) {
    if (!_orderId.hasMatch(orderId) || amountTiyin <= 0) return null;
    return Uri.parse(_payUrl)
        .replace(
          queryParameters: {
            'service_id': serviceId,
            'merchant_id': merchantId,
            'amount': formatTiyin(amountTiyin),
            'transaction_param': orderId,
            'return_url': returnUrl,
            'merchant_user_id': merchantUserId,
          },
        )
        .toString();
  }

  /// Creates the order for [planName]. Throws [ClickOrderException] with the
  /// server's reason (`already_paid`, `plan_not_found`, `too_many_orders`, …)
  /// or `network` when the call itself failed.
  static Future<ClickOrder> createOrder(String planName) async {
    final Object? data;
    try {
      data = await SupabaseService.client
          .rpc('click_create_order', params: {'p_plan_name': planName})
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const ClickOrderException('network');
    }
    if (data is! Map) throw const ClickOrderException('unknown');
    if (data['ok'] != true) {
      throw ClickOrderException(data['error']?.toString() ?? 'unknown');
    }
    final amount = data['amount_tiyin'];
    return ClickOrder(
      orderId: data['order_id']?.toString() ?? '',
      amountTiyin: amount is num
          ? amount.toInt()
          : int.tryParse('$amount') ?? 0,
    );
  }
}

class ClickOrder {
  final String orderId;
  final int amountTiyin;
  const ClickOrder({required this.orderId, required this.amountTiyin});
}

class ClickOrderException implements Exception {
  final String reason;
  const ClickOrderException(this.reason);

  @override
  String toString() => 'ClickOrderException($reason)';
}
