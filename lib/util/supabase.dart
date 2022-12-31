import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/models/profile.dart';

class SupabaseManagerManager {
  SupabaseClient getSupabaseClient() {
    return Supabase.instance.client;
  }
}

class SupabaseManager {
  static SupabaseManagerManager supabaseManagerManager = SupabaseManagerManager();

  static Profile? _currentProfile;

  static Profile? getCurrentProfile() => _currentProfile;

  static SupabaseClient supabaseClient = supabaseManagerManager.getSupabaseClient();

  static SupabaseClient getClient() => supabaseClient;

  static setSupabaseManagerManager(SupabaseManagerManager client) {
    supabaseManagerManager = client;
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
