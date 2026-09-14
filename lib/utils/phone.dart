import 'package:flutter/services.dart';

/// What a typed sign-in identifier turned out to be.
enum IdentifierKind { empty, phone, email, invalid }

/// Uzbek phone-number handling, mirroring the website's `src/lib/phone.ts`
/// and the `phone-signup` Edge Function byte for byte.
///
/// Accounts created by phone are stored in Supabase Auth under a synthetic
/// address — `998901234567@pro.com`. That address is an implementation
/// detail: it is sent to the API, but it must never be shown in the UI.
class UzPhone {
  UzPhone._();

  static const String countryCode = '998';
  static const String emailDomain = 'pro.com';
  static const int localDigits = 9;
  static const int minPasswordLength = 8;

  /// `"901234567"` | `"998901234567"` | `"+998 90 123 45 67"` →
  /// `"998901234567"`, or null when the number can't be a valid UZ mobile.
  static String? normalize(String? input) {
    if (input == null) return null;
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    final String local;
    if (digits.length == localDigits) {
      local = digits;
    } else if (digits.length == countryCode.length + localDigits &&
        digits.startsWith(countryCode)) {
      local = digits.substring(countryCode.length);
    } else {
      return null;
    }

    // Operator codes never start with 0 or 1.
    if (RegExp(r'^[01]').hasMatch(local)) return null;
    return countryCode + local;
  }

  /// Normalized number → the address used with Supabase Auth.
  static String? toAuthEmail(String? input) {
    final normalized = normalize(input);
    return normalized == null ? null : '$normalized@$emailDomain';
  }

  /// What the user typed on the sign-in form → the address to authenticate
  /// with. Anything containing `@` is treated as an email account.
  static String? identifierToAuthEmail(String? input) {
    final raw = input?.trim() ?? '';
    if (raw.isEmpty) return null;
    if (raw.contains('@')) {
      final email = raw.toLowerCase();
      return looksLikeEmail(email) ? email : null;
    }
    return toAuthEmail(raw);
  }

  /// How a typed identifier will be used, so the form can say so out loud.
  static IdentifierKind classify(String? input) {
    final raw = input?.trim() ?? '';
    if (raw.isEmpty) return IdentifierKind.empty;
    if (raw.contains('@')) {
      return looksLikeEmail(raw.toLowerCase())
          ? IdentifierKind.email
          : IdentifierKind.invalid;
    }
    // Digits only (spaces, +, dashes allowed) → the user means a phone.
    if (RegExp(r'^[\d\s+()-]+$').hasMatch(raw)) {
      return normalize(raw) == null
          ? IdentifierKind.invalid
          : IdentifierKind.phone;
    }
    return IdentifierKind.invalid;
  }

  static bool looksLikeEmail(String value) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(value);

  /// `998901234567@pro.com` → `+998 90 123 45 67`.
  ///
  /// Returns null for ordinary email accounts, whose address should simply be
  /// displayed as-is.
  static String? displayFromAuthEmail(String? email) {
    final value = email?.trim().toLowerCase() ?? '';
    if (!value.endsWith('@$emailDomain')) return null;
    final normalized = normalize(value.split('@').first);
    if (normalized == null) return null;
    return displayFromNormalized(normalized);
  }

  /// `998901234567` → `+998 90 123 45 67`.
  static String displayFromNormalized(String normalized) {
    if (normalized.length != countryCode.length + localDigits) {
      return '+$normalized';
    }
    return '+${normalized.substring(0, 3)} ${normalized.substring(3, 5)} '
        '${normalized.substring(5, 8)} ${normalized.substring(8, 10)} '
        '${normalized.substring(10, 12)}';
  }

  /// Local digits (max 9) → `90 123 45 67`, for the input field itself.
  static String formatLocal(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < d.length && i < localDigits; i++) {
      if (i == 2 || i == 5 || i == 7) buffer.write(' ');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  /// True when the account was created through the phone flow.
  static bool isPhoneAccount(String? email) =>
      (email?.trim().toLowerCase() ?? '').endsWith('@$emailDomain');
}

/// Formats a phone field as `90 123 45 67` while typing and caps it at nine
/// digits. The `+998` part is shown as a static prefix, not typed.
class UzPhoneInputFormatter extends TextInputFormatter {
  const UzPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // A pasted or autofilled number usually carries the country code, and the
    // field already shows `+998` as a static prefix — so drop the duplicate.
    //
    // BY LENGTH, NEVER BY PREFIX ALONE (docs/MOBILE-CONTENT-PROMPT.md §8):
    // `99` is a live operator code, so a perfectly ordinary nine-digit local
    // number can itself begin with `998` — `99 812 34 56` → `998123456`. A
    // bare `startsWith('998')` test would eat those three digits and leave
    // `123456`, which is how the website locked out every `99 8xx xx xx`
    // subscriber. Only a number that is *longer* than nine digits can have a
    // country code in front of it.
    if (digits.length > UzPhone.localDigits &&
        digits.startsWith(UzPhone.countryCode)) {
      digits = digits.substring(UzPhone.countryCode.length);
    }

    final capped = digits.length > UzPhone.localDigits
        ? digits.substring(0, UzPhone.localDigits)
        : digits;
    final formatted = UzPhone.formatLocal(capped);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
