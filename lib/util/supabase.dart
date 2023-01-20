import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/models/profile.dart';
import 'search/address_suggestion_manager.dart';

class SupabaseManager {
  static Profile? _currentProfile;

  static Profile? getCurrentProfile() => _currentProfile;

  static void setCurrentProfile(Profile? profile) {
    _currentProfile = profile;
  }

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
        setCurrentProfile(null);
      } else {
        setCurrentProfile(Profile.fromJson(response));
      }
    } catch (e) {
      setCurrentProfile(null);
    }

    // Reload the history suggestions to show the new profile's history.
    addressSuggestionManager.loadHistorySuggestions();
  }
}
