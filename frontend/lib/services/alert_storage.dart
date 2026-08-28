import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AlertStorage {
  static const String _storageKey = 't_salmon_weekly_alerts';

  // 한국 표준시(UTC+9) DateTime 반환
  static DateTime get _koreanNow => DateTime.now().toUtc().add(const Duration(hours: 9));

  // 알림 저장
  static Future<void> saveAlert({
    required String title,
    required String body,
    String? imageUrl,
    bool isDailySummary = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> currentList = await getAlerts();

    final nowKst = _koreanNow;

    // 새 알림 최상단 삽입 (KST 기준 ISO 문자열 저장)
    currentList.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'isDailySummary': isDailySummary,
      'createdAt': nowKst.toIso8601String(),
    });

    // 7일(168시간) 이내 알림만 필터링 유지
    final sevenDaysAgo = nowKst.subtract(const Duration(days: 7));
    final filteredList = currentList.where((item) {
      final createdAt = DateTime.tryParse(item['createdAt'] ?? '') ?? nowKst;
      return createdAt.isAfter(sevenDaysAgo);
    }).toList();

    await prefs.setString(_storageKey, jsonEncode(filteredList));
  }

  // 최근 7일치 알림 목록 불러오기
  static Future<List<Map<String, dynamic>>> getAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      final sevenDaysAgo = _koreanNow.subtract(const Duration(days: 7));

      return decoded
          .map((e) => Map<String, dynamic>.from(e))
          .where((item) {
            final createdAt = DateTime.tryParse(item['createdAt'] ?? '') ?? _koreanNow;
            return createdAt.isAfter(sevenDaysAgo);
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  // 단일 알림 삭제
  static Future<void> deleteAlert(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> currentList = await getAlerts();
    currentList.removeWhere((item) => item['id'] == id);
    await prefs.setString(_storageKey, jsonEncode(currentList));
  }

  // 전체 알림 내역 비우기
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
