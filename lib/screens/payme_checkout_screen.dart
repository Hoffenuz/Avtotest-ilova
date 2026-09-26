import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/supabase_config.dart';
import '../providers/language_provider.dart';
import '../providers/subscription_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ha_yo_dialog.dart';

/// Payme or Click checkout, hosted in a WebView.
///
/// Pops `true` when the provider redirected to [returnUrl] — which means the user
/// finished the flow, **not** that the payment succeeded. Only the Payme
/// server can confirm that, so the caller must re-read
/// `get_user_access_state` afterwards and never grant PRO on its own.
class PaymeCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final String planTitle;

  /// Where the provider sends the user when the flow is over. Payme and Click
  /// each have their own; reaching it closes this screen.
  final String returnUrl;

  const PaymeCheckoutScreen({
    super.key,
    required this.checkoutUrl,
    required this.planTitle,
    this.returnUrl = SupabaseConfig.paymeReturnUrl,
  });

  @override
  State<PaymeCheckoutScreen> createState() => _PaymeCheckoutScreenState();
}

class _PaymeCheckoutScreenState extends State<PaymeCheckoutScreen>
    with WidgetsBindingObserver {
  late final WebViewController _web;
  bool _loading = true;
  bool _returned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: _handleNavigation,
          onWebResourceError: (error) =>
              debugPrint('PaymeCheckout: ${error.description}'),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// PAYING OUTSIDE THIS WEBVIEW STILL HAS TO END THE CHECKOUT.
  ///
  /// A card app or the browser button takes the user out of here, and Payme
  /// then redirects THAT app to the return URL — this WebView never sees it,
  /// so the handler below never fires. The user comes back to a checkout page
  /// for a payment they already made, and closing it counts as a cancel.
  ///
  /// Coming back to the foreground is the signal: ask the server whether the
  /// subscription is live, and if it is, close as a success.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted || _returned) return;
    final sub = context.read<SubscriptionProvider>();
    sub.refresh(force: true).then((_) {
      if (mounted && !_returned && sub.isPro) _finish(true);
    });
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;

    // Payme is done with us → close and let the caller verify the result.
    if (url.startsWith(widget.returnUrl)) {
      _finish(true);
      return NavigationDecision.prevent;
    }

    // Card apps and bank 3-D Secure flows hand off through custom schemes
    // (payme://, tbcbank://, uzcard://…) which a WebView cannot open itself.
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.hasScheme &&
        uri.scheme != 'http' &&
        uri.scheme != 'https') {
      launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).catchError((_) => false);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  void _finish(bool completed) {
    if (_returned || !mounted) return;
    _returned = true;
    Navigator.pop(context, completed);
  }

  /// Closing mid-payment is easy to do by accident, so confirm first.
  Future<void> _confirmClose(String lang) async {
    String s(String k) => AppStrings.get(k, lang);
    final ok = await showHaYoDialog(
      context,
      title: s('payment_cancel_title'),
      message: s('payment_cancel_msg'),
      lang: lang,
      yesLabel: s('yes'),
      noLabel: s('no'),
      destructive: true,
    );
    if (ok == true) _finish(false);
  }

  Future<void> _openExternally(String lang) async {
    final uri = Uri.parse(widget.checkoutUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.get('payment_open_failed', lang))),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.get('payment_open_failed', lang))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String s(String k) => AppStrings.get(k, lang);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmClose(lang);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.planTitle),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: s('close'),
            onPressed: () => _confirmClose(lang),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: s('payment_open_browser'),
              onPressed: () => _openExternally(lang),
            ),
          ],
          bottom: _loading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    backgroundColor: AppTheme.border(context),
                    color: AppTheme.orange,
                    minHeight: 2,
                  ),
                )
              : null,
        ),
        body: WebViewWidget(controller: _web),
      ),
    );
  }
}
