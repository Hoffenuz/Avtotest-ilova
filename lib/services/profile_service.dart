import 'supabase_service.dart';

class UserProfile {
  final String id;
  final String? username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final int tariffDays;
  final DateTime? tariffEndDate;

  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    required this.tariffDays,
    required this.tariffEndDate,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String?,
      email: (map['email'] as String?) ?? '',
      fullName: map['full_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      tariffDays: (map['tariff_days'] as num?)?.toInt() ?? 0,
      tariffEndDate: map['tariff_end_date'] != null
          ? DateTime.tryParse(map['tariff_end_date'] as String)
          : null,
    );
  }
}

class ProfileService {
  ProfileService._();

  static Future<UserProfile?> fetchOwn(String userId) async {
    final row = await SupabaseService.client
        .from('profiles')
        .select(
          'id, username, email, full_name, avatar_url, tariff_days, tariff_end_date',
        )
        .eq('id', userId)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));

    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  /// Returns false when RLS or a missing row means nothing was written —
  /// `update` alone succeeds silently on zero matched rows, which used to
  /// make the app report "saved" when it had saved nothing.
  static Future<bool> updateFullName(String userId, String fullName) async {
    final rows = await SupabaseService.client
        .from('profiles')
        .update({
          'full_name': fullName,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId)
        .select('id')
        .timeout(const Duration(seconds: 15));

    return (rows as List<dynamic>).isNotEmpty;
  }
}
