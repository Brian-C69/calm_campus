import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_role.dart';
import 'user_profile_service.dart';

class RoleService {
  RoleService._();

  static final RoleService instance = RoleService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserRole> getCachedRole() async {
    return UserProfileService.instance.getRole();
  }

  Future<UserRole> refreshRoleFromSupabase() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      await UserProfileService.instance.saveRole(UserRole.student);
      return UserRole.student;
    }

    try {
      final Map<String, dynamic>? profile = await _client
          .from('profiles')
          .select('role,is_consultant,is_online,display_name')
          .eq('id', user.id)
          .maybeSingle();

      final UserRole role = UserRole.fromString(
        profile != null ? profile['role'] as String? : user.userMetadata?['role'] as String?,
      );

      await UserProfileService.instance.saveRole(role);
      await UserProfileService.instance.saveDisplayName(
        profile?['display_name'] as String? ?? (user.userMetadata?['preferred_name'] as String?),
      );
      await UserProfileService.instance.saveConsultantFlag(
        profile?['is_consultant'] as bool? ?? role == UserRole.admin,
      );
      await UserProfileService.instance.saveOnlineFlag(
        profile?['is_online'] as bool? ?? false,
      );

      return role;
    } catch (_) {
      final UserRole fallback = UserRole.fromString(user.userMetadata?['role'] as String?);
      await UserProfileService.instance.saveRole(fallback);
      return fallback;
    }
  }

  Future<void> upsertStudentProfileOnSignup(String displayName) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'role': UserRole.student.label,
        'display_name': displayName,
        'is_consultant': false,
        'is_online': false,
      });
    } catch (_) {
      // Silent best-effort; role will still default to student locally.
    }
  }
}
