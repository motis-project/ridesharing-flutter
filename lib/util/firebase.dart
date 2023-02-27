import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'supabase_manager.dart';

FirebaseMessaging messaging = FirebaseMessaging.instance;
FirebaseManager firebaseManager = FirebaseManager();

class FirebaseManager {
  FirebaseMessaging? messaging;
  NotificationSettings? settings;

  Future<void> initialize() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      await Firebase.initializeApp();
      messaging = FirebaseMessaging.instance;
      // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      //   print('A new onMessageOpenedApp event was published!');
      // });
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
  }
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
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

Future<void> deletePushToken() async {
  // at the moment Push Notifications are only supported on Android
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final String? fcmToken = await firebaseManager.messaging!.getToken();
    await supabaseManager.supabaseClient
        .from('push_tokens')
        .update(<String, dynamic>{'disabled': true}).eq('token', fcmToken);
  }
}
