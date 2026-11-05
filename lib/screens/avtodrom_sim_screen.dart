import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../providers/language_provider.dart';
import '../services/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/ha_yo_dialog.dart';

/// Avtodrom simulyatori — saytdagi `avtodrom.avtotestu.uz` (Godot web buildi)
/// WebView ichida.
///
/// NEGA WEBVIEW: Play Store alohida Godot ilovasini ikki marta rad etdi; web
/// versiya esa brauzerda ishlaydi va saytda ham shu. Ilova to'liq funksiyali,
/// shuning uchun «faqat WebView» siyosatiga tushmaydi.
///
/// NEGA LANDSCAPE: boshqaruv (rul, pedallar) keng ekranga mo'ljallangan.
/// Ilova portretga qulflangan (main.dart) — shu ekran ochilganda tizim o'zi
/// gorizontalga buradi, yopilganda portretga qaytaradi.
class AvtodromSimScreen extends StatefulWidget {
  const AvtodromSimScreen({super.key});

  static const String baseUrl = 'https://avtodrom.avtotestu.uz/';

  @override
  State<AvtodromSimScreen> createState() => _AvtodromSimScreenState();
}

class _AvtodromSimScreenState extends State<AvtodromSimScreen> {
  late final WebViewController _web;
  bool _loading = true;
  bool _failed = false;
  late final String _lang;

  @override
  void initState() {
    super.initState();
    _lang = context.read<LanguageProvider>().lang;
    // Ekran ochilishi bilan GORIZONTAL: simulyator portretda «telefonni
    // buring» deb turardi, foydalanuvchi o'zi burishi kerak edi. Endi faqat
    // landscape ruxsat etiladi — tizim o'zi buradi; chiqishda portretga qaytadi.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Status bar va navigatsiya tugmalari yashirin — o'yin butun ekranda.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          // Faqat bosh sahifaning o'zi muhim: o'yin ichidagi resurslar
          // (wasm/pck) xatosi bu yerga ham keladi, lekin ular `isForMainFrame`
          // emas — ularni «ochilmadi» deb ko'rsatmaymiz.
          onWebResourceError: (e) {
            if (e.isForMainFrame == true && mounted) {
              setState(() {
                _failed = true;
                _loading = false;
              });
            }
          },
          // Simulyator ichidan saytga olib chiquvchi havolalar — tashqarida
          // ochilmasin, WebView ichida qolmasin: shunchaki e'tiborsiz.
          onNavigationRequest: (req) {
            final host = Uri.tryParse(req.url)?.host ?? '';
            return host == 'avtodrom.avtotestu.uz'
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      );
    _load();
  }

  void _load() {
    setState(() {
      _failed = false;
      _loading = true;
    });
    final uri = Uri.parse(AvtodromSimScreen.baseUrl).replace(
      queryParameters: {'lang': _lang, 'src': 'app'},
    );
    _web.loadRequest(uri);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _confirmExit() async {
    String s(String k) => AppStrings.get(k, _lang);
    final yes = await showHaYoDialog(
      context,
      title: s('avtodrom_sim'),
      message: s('avtodrom_sim_exit_q'),
      lang: _lang,
      yesLabel: s('avtodrom_sim_exit_yes'),
      noLabel: s('cancel'),
    );
    if (yes == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    String s(String k) => AppStrings.get(k, _lang);

    return PopScope(
      // Imtihon o'rtasida tasodifiy «orqaga» hammasini yo'qotadi — tasdiq.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmExit());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (!_failed) WebViewWidget(controller: _web),
            if (_loading && !_failed)
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.success,
                        strokeWidth: 2.5,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          s('avtodrom_sim_loading'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_failed)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        color: Colors.white70,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s('avtodrom_sim_offline'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: Text(s('retry')),
                      ),
                    ],
                  ),
                ),
              ),
            // Chiqish tugmasi — chap yuqori burchakda, kichik va yarim shaffof:
            // o'yin boshqaruviga xalaqit bermaydi, lekin doim topiladi.
            Positioned(
              top: 8,
              left: 8,
              child: SafeArea(
                child: Material(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    tooltip: s('avtodrom_sim_exit_yes'),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: _confirmExit,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
