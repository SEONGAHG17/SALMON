import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';
import 'alert_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'deadline_channel',
      '마감 임박 및 분석 알림',
      description: '마감 임박 및 일일 리포트 알림을 수신합니다.',
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 상단바 푸시 발송 + 로컬 AlertStorage 기록
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'deadline_channel',
      '마감 임박 및 분석 알림',
      channelDescription: '마감 임박 및 일일 리포트 알림을 수신합니다.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );

    await AlertStorage.saveAlert(
      title: title,
      body: body,
    );
  }

  // 💡 백엔드 DB(notifications 테이블)의 새 알림을 조회하여 상단바로 즉시 발송
  Future<void> syncRemoteNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final bool pushEnabled = prefs.getBool('push_enabled') ?? true;
    if (!pushEnabled) return;

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/settings/notifications?user_id=default_user'),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(res.bodyBytes));
        List<dynamic> remoteList = [];

        if (decoded is List) {
          remoteList = decoded;
        } else if (decoded is Map<String, dynamic>) {
          remoteList = decoded['notifications'] ?? decoded['alerts'] ?? decoded['data'] ?? [];
        }

        for (var item in remoteList) {
          final int notifId = (item['id'] is int)
              ? item['id']
              : int.tryParse(item['id'].toString()) ?? item['title'].hashCode;
          final String title = item['title'] ?? '알림';
          final String body = item['body'] ?? '';

          final sentKey = 'sent_remote_push_$notifId';
          final alreadySent = prefs.getBool(sentKey) ?? false;

          // 아직 스마트폰 상단바에 띄우지 않은 DB 알림인 경우 푸시 발송
          if (!alreadySent) {
            await showNotification(
              id: notifId,
              title: title,
              body: body,
            );
            await prefs.setBool(sentKey, true);
          }
        }
      }
    } catch (e) {
      debugPrint("⚠️ [원격 알림 동기화 오류]: $e");
    }
  }

  // D-Day 마감 알림 실시간 동기화
  Future<void> syncDeadlineNotifications(List<Map<String, dynamic>> deadlineItems) async {
    final prefs = await SharedPreferences.getInstance();
    final bool masterPush = prefs.getBool('push_enabled') ?? true;
    final bool notifyDday = prefs.getBool('d_day_0') ?? true;
    final bool notifyD1 = prefs.getBool('d_day_1') ?? true;
    final bool notifyD2 = prefs.getBool('d_day_2') ?? true;
    final bool notifyD3 = prefs.getBool('d_day_3') ?? true;
    final bool notifyD5 = prefs.getBool('d_day_5') ?? true;
    final bool notifyD7 = prefs.getBool('d_day_7') ?? true;
    final bool notifyD10 = prefs.getBool('d_day_10') ?? true;

    if (!masterPush) return;

    for (var item in deadlineItems) {
      final int dDay = item['dDay'] as int;
      final String title = item['title'] ?? '일정';
      final int itemId = (item['raw']?['id'] is int)
          ? item['raw']['id']
          : (item['title'].hashCode);

      bool shouldNotify = false;
      String message = "";

      if (dDay == 0 && notifyDday) {
        shouldNotify = true;
        message = "오늘 마감되는 일정입니다: $title";
      } else if (dDay == 1 && notifyD1) {
        shouldNotify = true;
        message = "마감 1일 전입니다: $title";
      } else if (dDay == 2 && notifyD2) {
        shouldNotify = true;
        message = "마감 2일 전입니다: $title";
      } else if (dDay == 3 && notifyD3) {
        shouldNotify = true;
        message = "마감 3일 전입니다: $title";
      } else if (dDay == 5 && notifyD5) {
        shouldNotify = true;
        message = "마감 5일(D-5) 전입니다: $title";
      } else if (dDay == 7 && notifyD7) {
        shouldNotify = true;
        message = "마감 7일(D-7) 남았습니다: $title";
      } else if (dDay == 10 && notifyD10) {
        shouldNotify = true;
        message = "마감 10일(D-10) 남았습니다: $title";
      }

      if (shouldNotify) {
        final sentKey = 'sent_push_${itemId}_D$dDay';
        final alreadySent = prefs.getBool(sentKey) ?? false;

        if (!alreadySent) {
          await showNotification(
            id: itemId.abs() + dDay,
            title: "⏳ 마감 임박 알림 (D-$dDay)",
            body: message,
          );
          await prefs.setBool(sentKey, true);
        }
      }
    }
  }
}
