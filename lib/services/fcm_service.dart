import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<void> initializeFCM(String uid) async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('🚫 Permissão de notificação negada');
        return;
      }
      const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
        'petkeeper_channel',
        'PetKeeper Notificações',
        description: 'Canal para notificações do PetKeeper Lite',
        importance: Importance.high,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );
      await _localNotifications.initialize(initSettings);
      final String? token = await _firebaseMessaging.getToken();
      debugPrint('🎯 Token FCM: $token');
      if (token != null && uid.isNotEmpty) {
        await _registerToken(uid, token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _registerToken(uid, newToken);
      });

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Mensagem recebida: ${message.notification?.title}');
        _showLocalNotification(message);
      });
    } catch (e) {
      debugPrint('Erro ao inicializar FCM: $e');
    }
  }

  static Future<void> _registerToken(String uid, String token) async {
    DocumentReference<Map<String, dynamic>> userRef = _firestore.collection('users').doc(uid);
    await userRef.set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static Future<void> deleteToken() async {
    try {
      User? user = await FirebaseAuth.instance.currentUser;
      if (user == null) return;
      String? token = await _firebaseMessaging.getToken();
      if (token == null) return;
      DocumentReference<Map<String, dynamic>> userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
      debugPrint('🧹 Token FCM removido com sucesso: $token');
    } catch (e) {
      debugPrint('Erro ao remover token FCM: $e');
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) {
      debugPrint("⚠️ Mensagem recebida sem campo notification: ${message.data}");
      return;
    }

    const NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'petkeeper_channel',
        'PetKeeper Notificações',
        channelDescription: 'Canal para notificações do PetKeeper Lite',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'PetKeeper 🐾',
      notification.body ?? 'Nova notificação recebida',
      notificationDetails,
    );
  }
}
