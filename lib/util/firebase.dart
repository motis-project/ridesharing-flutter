import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import 'supabase_manager.dart';

FirebaseManager firebaseManager = FirebaseManager();

class FirebaseManager {
  FirebaseMessaging? messaging;
  NotificationSettings? settings;

  Future<void> initialize({String? name}) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp(name: name, options: DefaultFirebaseOptions.currentPlatform);
      messaging = FirebaseMessaging.instance;
    }
  }
}

Future<void> requestPermissionAndLoadPushToken() async {
  // at the moment Push Notifications are only supported on Android
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    firebaseManager.settings = await firebaseManager.messaging!.requestPermission();

    if (firebaseManager.settings!.authorizationStatus == AuthorizationStatus.authorized) {
      final String? fcmToken = await firebaseManager.messaging!.getToken();
      await supabaseManager.supabaseClient.from('push_tokens').upsert(
        <String, dynamic>{
          'token': fcmToken,
          'user_id': supabaseManager.currentProfile?.id,
          'disabled': false,
        },
        onConflict: 'token',
      );
    }
  }
}

Future<void> disablePushToken() async {
  // at the moment Push Notifications are only supported on Android
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final String? fcmToken = await firebaseManager.messaging!.getToken();
    await supabaseManager.supabaseClient
        .from('push_tokens')
        .update(<String, dynamic>{'disabled': true}).eq('token', fcmToken);
  }
}
