import 'dart:async';

import 'package:flutter/foundation.dart';

/// Avto-o'tish taymeri — saytdagi `useQuestionAnimation.schedule` mantiqi.
///
/// Animatsiya to'g'ri harakatni KO'RSATADI (javobni oshkor qiladi), shuning
/// uchun avto-o'tish video ustidan "sakrab" ketmasligi kerak. Video bor
/// savolda amal video tugaguncha ([onAnimationDone]) ushlab turiladi, keyin
/// [afterAnimationDelay] dan so'ng bajariladi. Video bo'lmasa — oddiy taymer.
///
/// Widget'dan ajratilgan — unit test bilan tekshiriladi.
class AutoAdvanceScheduler {
  /// Video tugagach keyingi savolga o'tishdan oldingi qisqa pauza (oxirgi
  /// kadrni ko'rish uchun).
  static const Duration afterAnimationDelay = Duration(milliseconds: 700);

  Timer? _timer;
  VoidCallback? _pending;

  /// Amal video tugashini kutyapti.
  bool get isWaitingForAnimation => _pending != null;

  /// Taymer yoki kutish bor.
  bool get isScheduled => _pending != null || (_timer?.isActive ?? false);

  /// [fn] ni rejalashtiradi. [waitForAnimation] bo'lsa — video tugaguncha
  /// kutadi, aks holda [delay] dan keyin bajaradi. Avvalgi reja bekor bo'ladi.
  void schedule(
    VoidCallback fn, {
    required Duration delay,
    required bool waitForAnimation,
  }) {
    cancel();
    if (waitForAnimation) {
      _pending = fn;
      return;
    }
    _timer = Timer(delay, fn);
  }

  /// Video tugadi / o'ynab bo'lmadi — kutilayotgan amal qisqa pauzadan keyin.
  void onAnimationDone() {
    final fn = _pending;
    _pending = null;
    if (fn == null) return;
    _timer?.cancel();
    _timer = Timer(afterAnimationDelay, fn);
  }

  /// Foydalanuvchi o'zi boshqarganda (izoh ochdi, savol tanladi) — hammasi
  /// bekor.
  void cancel() {
    _pending = null;
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => cancel();
}
