import 'package:avtotest_app/config/supabase_config.dart';
import 'package:avtotest_app/services/click_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The Click link must match the website's `buildClickPayUrl` byte for byte in
/// meaning: the same cashbox ids, the amount as "N.NN" and the server's order
/// id — or Click's Prepare call finds no order and the payment is refused.
void main() {
  const orderId = '3f2b8c1e-9a4d-4e7b-8c21-0d5e6f7a8b9c';

  group('formatTiyin', () {
    test(
      'whole som',
      () => expect(ClickService.formatTiyin(1500000), '15000.00'),
    );
    test(
      'keeps tiyin exact',
      () => expect(ClickService.formatTiyin(8300005), '83000.05'),
    );
    test('below one som', () => expect(ClickService.formatTiyin(7), '0.07'));
  });

  test('builds the site-compatible pay link', () {
    final url = ClickService.buildPayUrl(
      orderId: orderId,
      amountTiyin: 3500000,
      returnUrl: SupabaseConfig.clickReturnUrl,
    );
    final uri = Uri.parse(url!);
    expect(uri.origin, 'https://my.click.uz');
    expect(uri.path, '/services/pay');
    expect(uri.queryParameters, {
      'service_id': '112576',
      'merchant_id': '57313',
      'amount': '35000.00',
      'transaction_param': orderId,
      'return_url': 'https://avtotestu.uz/profile?from=click',
      'merchant_user_id': '91937',
    });
  });

  test('refuses anything the server would not have produced', () {
    String? build(String id, int amount) => ClickService.buildPayUrl(
      orderId: id,
      amountTiyin: amount,
      returnUrl: SupabaseConfig.clickReturnUrl,
    );
    expect(build('', 3500000), isNull);
    expect(build('not-a-uuid', 3500000), isNull);
    expect(build(orderId, 0), isNull);
    expect(build(orderId, -100), isNull);
  });
}
