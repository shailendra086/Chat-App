import 'dart:convert';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// Background message handler (MUST be a top-level function annotated with @pragma)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Prevent duplicate messages in short succession
  final Set<String> _seenMessageIds = {};

  Future<void> initialize() async {
    try {
      // 1. Request notification permissions
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('FCM Permission authorizationStatus: ${settings.authorizationStatus}');

      // 2. Setup Background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Initialize Local Notifications Plugin
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null) {
            try {
              final Map<String, dynamic> data = jsonDecode(payload) as Map<String, dynamic>;
              _handleNotificationTap(data);
            } catch (e) {
              print("Error parsing local notification payload: $e");
            }
          }
        },
      );

      // 4. Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important chat notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Handle Foreground Messages (App is running)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final messageId = message.messageId;
        if (messageId != null && _seenMessageIds.contains(messageId)) {
          return; // Avoid duplicate notifications
        }
        if (messageId != null) {
          _seenMessageIds.add(messageId);
        }

        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android?.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        }
      });

      // 6. Handle Background Message Click (App is in background)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationTap(message.data);
      });

      // 7. Handle Terminated Message Click (App is fully closed)
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage.data);
      }
    } catch (e) {
      print("Error initializing NotificationService: $e");
    }
  }

  /// Refreshes and registers FCM Token when user is signed in
  Future<void> registerUserToken(String userId) async {
    try {
      String? token;
      if (kIsWeb) {
        // FCM on Web requires a VAPID key. To enable:
        // 1. Generate Web Push certificate key in Firebase Console -> Settings -> Cloud Messaging.
        // 2. Pass it below, e.g., token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_KEY');
        print("FCM Web push notifications require a VAPID key. Configure it in NotificationService.");
      } else {
        token = await _messaging.getToken();
      }

      if (token != null) {
        await _saveTokenToDatabase(userId, token);
      }

      // Listen for token updates
      _messaging.onTokenRefresh.listen((newToken) async {
        await _saveTokenToDatabase(userId, newToken);
      });
    } catch (e) {
      print("Error fetching FCM token: $e");
    }
  }

  Future<void> _saveTokenToDatabase(String userId, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      print("Successfully updated user token in Firestore.");
    } catch (e) {
      print("Error updating FCM token in Firestore: $e");
    }
  }

  /// Resolves the clicked notification data and redirects to Chat screen
  Future<void> _handleNotificationTap(Map<String, dynamic> data) async {
    final chatId = data['chatId'] as String?;
    final senderId = data['senderId'] as String?;

    if (chatId != null && senderId != null) {
      try {
        // Fetch sender user model from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
        if (userDoc.exists) {
          final peerUser = UserModel.fromMap(userDoc.data()!);
          
          // Navigate to the Chat screen using GetX
          Get.toNamed(
            AppRoutes.chat,
            arguments: {
              'chatId': chatId,
              'peerUser': peerUser,
            },
          );
        }
      } catch (e) {
        print("Error handling notification redirection: $e");
      }
    }
  }
}
