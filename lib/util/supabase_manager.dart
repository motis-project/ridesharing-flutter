import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../account/models/profile.dart';
import 'search/address_suggestion_manager.dart';

SupabaseManager supabaseManager = SupabaseManager();

class SupabaseManager {
  Profile? currentProfile;
  late SupabaseClient supabaseClient;

  Future<void> initialize() async {
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_BASE_URL'),
      anonKey: dotenv.get('SUPABASE_BASE_KEY'),
    );
    supabaseClient = Supabase.instance.client;
    await reloadCurrentProfile();
  }

  Future<void> reloadCurrentProfile() async {
    try {
      final Map<String, dynamic>? response = await supabaseClient
          .from('profiles')
          .select<Map<String, dynamic>?>()
          .eq('auth_id', supabaseClient.auth.currentUser!.id)
          .maybeSingle();
      if (response == null) {
        currentProfile = null;
      } else {
        currentProfile = Profile.fromJson(response);
      }
    } catch (e) {
      currentProfile = null;
    }

    // Reload the history suggestions to show the new profile's history.
    unawaited(addressSuggestionManager.loadHistorySuggestions());
  }
}
