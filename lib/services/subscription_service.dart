import 'supabase_service.dart';

/// Result of the `get_user_access_state(user_id)` RPC — the sole source of
/// truth for PRO access. `state` is one of: guest | free_logged_in |
/// active_trial | expired_trial | active_pro | expired_pro. Trial is disabled
/// product-wide, so only `active_pro` ever counts as premium (matches the
/// website's `useAccessState`/`AuthContext` behavior).
class UserAccessState {
  final String state;
  final bool isPremium;
  final DateTime? expiresAt;

  const UserAccessState({
    required this.state,
    required this.isPremium,
    required this.expiresAt,
  });

  static const none = UserAccessState(
    state: 'guest',
    isPremium: false,
    expiresAt: null,
  );

  factory UserAccessState.fromMap(Map<String, dynamic> map) {
    final state = (map['state'] as String?) ?? 'guest';
    final rawPremium = map['is_premium'] as bool? ?? false;
    final rawExpiry = map['expires_at'];
    return UserAccessState(
      state: state,
      isPremium: state == 'active_pro' && rawPremium,
      expiresAt: rawExpiry == null
          ? null
          : DateTime.parse(rawExpiry as String).toUtc(),
    );
  }
}

/// Display details for the PRO screen. Derived entirely from
/// [UserAccessState.expiresAt] — the RPC already resolves the correct expiry
/// regardless of whether access came from a `subscriptions` row or
/// `profiles.tariff_end_date`, so no separate table read is needed.
class SubscriptionInfo {
  final String type;
  final DateTime expiresAt;

  const SubscriptionInfo({required this.type, required this.expiresAt});

  bool get isActive => DateTime.now().toUtc().isBefore(expiresAt.toUtc());

  int get daysRemaining {
    final diff = expiresAt.toUtc().difference(DateTime.now().toUtc());
    if (diff.isNegative) return 0;
    final hours = diff.inMinutes / 60.0;
    return (hours / 24.0).ceil();
  }

  String get expiryDateTashkent {
    final tashkent = expiresAt.toUtc().add(const Duration(hours: 5));
    final d = tashkent.day.toString().padLeft(2, '0');
    final m = tashkent.month.toString().padLeft(2, '0');
    final y = tashkent.year.toString();
    return '$d.$m.$y';
  }

  factory SubscriptionInfo.fromAccess(UserAccessState access) {
    return SubscriptionInfo(
      type: 'pro',
      expiresAt: access.expiresAt ?? DateTime.now().toUtc(),
    );
  }
}

/// Reads subscription / PRO-access state from the real avtotestu.uz project.
class SubscriptionService {
  SubscriptionService._();

  /// Authoritative PRO check via the `get_user_access_state` RPC. The RPC is
  /// IDOR-safe: for an authenticated caller it always resolves to
  /// `auth.uid()` server-side and ignores the passed id, so this can only
  /// ever return the calling user's own access state.
  static Future<UserAccessState> fetchAccessState(String userId) async {
    // Chegaralangan: javob kelmasa ilova keshdagi holat bilan davom etadi.
    final raw = await SupabaseService.client
        .rpc('get_user_access_state', params: {'user_id': userId})
        .timeout(const Duration(seconds: 15));

    if (raw is List && raw.isNotEmpty) {
      return UserAccessState.fromMap(raw.first as Map<String, dynamic>);
    }
    if (raw is Map<String, dynamic>) {
      return UserAccessState.fromMap(raw);
    }
    return UserAccessState.none;
  }

  /// Display details for the PRO screen.
  static Future<SubscriptionInfo?> fetchActiveDetails(String userId) async {
    final access = await fetchAccessState(userId);
    if (!access.isPremium) return null;
    return SubscriptionInfo.fromAccess(access);
  }
}
