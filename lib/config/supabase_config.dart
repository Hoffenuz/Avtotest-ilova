/// Supabase project configuration.
///
/// The publishable (anon) key is safe to embed in the client — it only
/// grants the access permitted by Row Level Security policies.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://lvdndseuobzbgzrarygu.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx2ZG5kc2V1b2J6Ymd6cmFyeWd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0OTk4MTYsImV4cCI6MjA4MjA3NTgxNn0.V6Gh1WaWBtjcU_Ia0DiUjbGApigaC2j5mDJjWP7-FFg';

  /// Manual payment / support contact for subscription purchases.
  static const String paymentTelegramUrl = 'https://t.me/avtosmart1';

  /// Public community group — news, Q&A, tips. Separate from the support
  /// contact above: one is a person to write to, the other is a channel to
  /// follow.
  static const String telegramGroupUrl = 'https://t.me/avtosmartuzb';

  /// Public site; also the base of the Payme return URL.
  static const String siteUrl = 'https://avtotestu.uz';

  /// Payme kassa (merchant) id — public, it travels inside every checkout
  /// link. The merchant key stays server-side in Supabase Vault.
  static const String paymeMerchantId = '6a6b94141aa0d0bde1ab83cf';

  static const String paymeCheckoutBase = 'https://checkout.paycom.uz/';

  /// Where Payme sends the browser once the user is done. The app never loads
  /// this page — it intercepts the navigation and closes the checkout view.
  static const String paymeReturnUrl = '$siteUrl/payment-return';

  /// Click's return address — the same page the website uses, so a payment
  /// finished in an outside browser still lands somewhere that re-checks PRO.
  static const String clickReturnUrl = '$siteUrl/profile?from=click';

  /// Deep link registered in AndroidManifest.xml and in the Supabase
  /// dashboard's redirect URL list; used by Google sign-in.
  static const String authRedirectUrl = 'uz.avtotestu.app://auth-callback';

  /// The Google "Web application" OAuth client Supabase's Google provider is
  /// configured with (public — it is in every Google sign-in URL). Native
  /// sign-in asks Google for an ID token issued to THIS client, which is the
  /// audience Supabase accepts. Android also needs its own OAuth client
  /// (package + SHA-1) in the same Google Cloud project — see
  /// docs/GOOGLE-SIGNIN-ANDROID.md.
  static const String googleWebClientId =
      '272991925832-vithrtfh5iobm30fqkeb9dldvfvdnsvn.apps.googleusercontent.com';
}
