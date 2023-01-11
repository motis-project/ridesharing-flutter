import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/models/profile.dart';

class SupabaseManager {
  static Profile? _currentProfile;

  static Profile? getCurrentProfile() => _currentProfile;

  static SupabaseClient supabaseClient = Supabase.instance.client;

  static void setClient(SupabaseClient client) {
    supabaseClient = client;
  }

  static Future<void> reloadCurrentProfile() async {
    try {
      final response = await supabaseClient
          .from('profiles')
          .select<Map<String, dynamic>?>()
          .eq('auth_id', supabaseClient.auth.currentUser!.id)
          .maybeSingle();

      if (response == null) {
        _currentProfile = null;
      } else {
        _currentProfile = Profile.fromJson(response);
      }
    } catch (e) {
      _currentProfile = null;
    }
  }
}
