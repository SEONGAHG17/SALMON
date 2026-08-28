import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'alert_storage.dart';

// 백그라운드/종료 상태에서 FCM 푸시 수신 시 최상단 탑레벨 핸들러
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 [FCM 백그라운드 푸시 수신]: ${message.notification?.title}");
  
  final title = message.notification?.title ?? message.data['title'] ?? '알림';
  final body = message.notification?.body ?? message.data['body'] ?? '';
  
  if (title.isNotEmpty) {
    await AlertStorage.saveAlert(
      title: title,
      body: body,
      isDailySummary: message.data['is_daily_summary'] == 'true',
    );
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    // 1. 알림 권한 요청
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint("🔔 [FCM 권한 허용됨]");
    }

    // 2. 디바이스 FCM 토큰 확인 및 출력
    String? token = await _fcm.getToken();
    debugPrint("======================================================");
    debugPrint(" [현재 디바이스 FCM 토큰]:\n$token");
    debugPrint("======================================================");

    // 3. 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. 포그라운드(앱 실행 중) 수신 리스너 등록 -> 상단바 팝업 띄우기
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 [FCM 포그라운드 수신]: ${message.notification?.title}");
      
      final title = message.notification?.title ?? message.data['title'] ?? '알림';
      final body = message.notification?.body ?? message.data['body'] ?? '';
      final int notifId = message.messageId.hashCode;

      NotificationService().showNotification(
        id: notifId,
        title: title,
        body: body,
      );
    });
  }
}
