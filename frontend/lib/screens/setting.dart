import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/constants.dart';
import '../services/notification_service.dart';
import 'settingcategory.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // 푸시 마스터 스위치
  bool _pushEnabled = true;

  // D-Day 세부 스위치
  bool _dDay0 = true;
  bool _dDay1 = true;
  bool _dDay2 = true;
  bool _dDay3 = true;
  bool _dDay5 = true;
  bool _dDay7 = true;
  bool _dDay10 = true;
  TimeOfDay _dDayTime = const TimeOfDay(hour: 9, minute: 0);

  // 일일 요약 리포트 스위치 및 시간
  bool _dailySummaryEnabled = true;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 18, minute: 50);

  // 아코디언 토글 확장 상태 관리
  bool _isDDayExpanded = true;
  bool _isDailyExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // ----------------------------------------------------
  // 설정값 불러오기 (SharedPreferences)
  // ----------------------------------------------------
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushEnabled = prefs.getBool('push_enabled') ?? prefs.getBool('push_master') ?? true;

      _dDay0 = prefs.getBool('d_day_0') ?? prefs.getBool('push_dday') ?? true;
      _dDay1 = prefs.getBool('d_day_1') ?? prefs.getBool('push_d1') ?? true;
      _dDay2 = prefs.getBool('d_day_2') ?? true;
      _dDay3 = prefs.getBool('d_day_3') ?? prefs.getBool('push_d3') ?? true;
      _dDay5 = prefs.getBool('d_day_5') ?? true;
      _dDay7 = prefs.getBool('d_day_7') ?? prefs.getBool('push_d7') ?? true;
      _dDay10 = prefs.getBool('d_day_10') ?? prefs.getBool('push_d10') ?? true;

      final dTimeStr = prefs.getString('d_day_time') ?? '09:00';
      final dParts = dTimeStr.split(':');
      _dDayTime = TimeOfDay(hour: int.parse(dParts[0]), minute: int.parse(dParts[1]));

      _dailySummaryEnabled = prefs.getBool('daily_summary_enabled') ?? true;
      final timeStr = prefs.getString('daily_summary_time') ?? '18:50';
      final parts = timeStr.split(':');
      _dailySummaryTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    });
  }

  // ----------------------------------------------------
  // 설정값 저장 및 백엔드 동기화
  // ----------------------------------------------------
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final summaryTimeStr =
        '${_dailySummaryTime.hour.toString().padLeft(2, '0')}:${_dailySummaryTime.minute.toString().padLeft(2, '0')}';
    final dDayTimeStr =
        '${_dDayTime.hour.toString().padLeft(2, '0')}:${_dDayTime.minute.toString().padLeft(2, '0')}';

    // 로컬 키 저장
    await prefs.setBool('push_enabled', _pushEnabled);
    await prefs.setBool('push_master', _pushEnabled);

    await prefs.setBool('d_day_0', _dDay0);
    await prefs.setBool('push_dday', _dDay0);

    await prefs.setBool('d_day_1', _dDay1);
    await prefs.setBool('push_d1', _dDay1);

    await prefs.setBool('d_day_2', _dDay2);

    await prefs.setBool('d_day_3', _dDay3);
    await prefs.setBool('push_d3', _dDay3);

    await prefs.setBool('d_day_5', _dDay5);

    await prefs.setBool('d_day_7', _dDay7);
    await prefs.setBool('push_d7', _dDay7);

    await prefs.setBool('d_day_10', _dDay10);
    await prefs.setBool('push_d10', _dDay10);

    await prefs.setString('d_day_time', dDayTimeStr);
    await prefs.setBool('daily_summary_enabled', _dailySummaryEnabled);
    await prefs.setString('daily_summary_time', summaryTimeStr);

    // 백엔드 API 동기화
    try {
      await http.post(
        Uri.parse('$baseUrl/api/v1/settings/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': 'default_user',
          'push_enabled': _pushEnabled,
          'd_day_0': _dDay0,
          'd_day_1': _dDay1,
          'd_day_2': _dDay2,
          'd_day_3': _dDay3,
          'd_day_5': _dDay5,
          'd_day_7': _dDay7,
          'd_day_10': _dDay10,
          'd_day_time': dDayTimeStr,
          'daily_summary_enabled': _dailySummaryEnabled,
          'daily_summary_time': summaryTimeStr,
        }),
      );
    } catch (_) {}
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return '$period ${hour.toString().padLeft(2, '0')}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFFFF5247);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A1E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '전체 설정',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1E),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 카테고리 관리 메뉴
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.category_outlined, color: Color(0xFF1A1A1E)),
                title: const Text('카테고리 관리', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingCategoryScreen()),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. 💡 D-Day 마감 알림 상세 설정 카드 (토글 아코디언)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: Column(
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.notifications_active_outlined, color: Color(0xFF1A1A1E)),
                    title: const Text('마감 알림 (D-Day)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text(
                      _pushEnabled ? '마감 임박 알림 활성' : '알림 꺼짐',
                      style: TextStyle(fontSize: 12, color: _pushEnabled ? const Color(0xFF2E7D32) : Colors.grey),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _pushEnabled,
                          activeColor: brandColor,
                          onChanged: (val) {
                            setState(() => _pushEnabled = val);
                            _saveSettings();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isDDayExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _isDDayExpanded = !_isDDayExpanded);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 펼침 상태일 때만 상세 D-Day 스위치 및 발송 시간 노출
                  if (_isDDayExpanded && _pushEnabled) ...[
                    const Divider(height: 1, color: Color(0xFFF2F2F7)),
                    _buildSubSwitch('당일 마감 알림 (D-Day)', _dDay0, (val) {
                      setState(() => _dDay0 = val);
                      _saveSettings();
                    }),
                    _buildSubSwitch('1일 전 마감 알림 (D-1)', _dDay1, (val) {
                      setState(() => _dDay1 = val);
                      _saveSettings();
                    }),
                    _buildSubSwitch('2일 전 마감 알림 (D-2)', _dDay2, (val) {
                      setState(() => _dDay2 = val);
                      _saveSettings();
                    }),
                    _buildSubSwitch('3일 전 마감 알림 (D-3)', _dDay3, (val) {
                      setState(() => _dDay3 = val);
                      _saveSettings();
                    }),
                    _buildSubSwitch('5일 전 마감 알림 (D-5)', _dDay5, (val) {
                      setState(() => _dDay5 = val);
                      _saveSettings();
                    }),
                    _buildSubSwitch('7일 전 마감 알림 (D-7)', _dDay7, (val) {
                      setState(() => _dDay7 = val);
                      _saveSettings();
                    }),
                    _buildSubSwitch('10일 전 마감 알림 (D-10)', _dDay10, (val) {
                      setState(() => _dDay10 = val);
                      _saveSettings();
                    }),
                    const Divider(height: 1, color: Color(0xFFF2F2F7)),
                    ListTile(
                      title: const Text('D-Day 알림 수신 시간', style: TextStyle(fontSize: 13.5, color: Color(0xFF48484A))),
                      subtitle: const Text('지정한 시간에 마감 임박 알림이 발송됩니다.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatTimeOfDay(_dDayTime),
                          style: const TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _dDayTime,
                        );
                        if (picked != null) {
                          setState(() => _dDayTime = picked);
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. 💡 일일 요약 리포트 카드 (토글 아코디언)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E5E7)),
              ),
              child: Column(
                children: [
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    leading: const Icon(Icons.analytics_outlined, color: Color(0xFF1A1A1E)),
                    title: const Text('일일 분석 리포트', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Text(
                      _dailySummaryEnabled ? '일일 리포트 알림 켜짐' : '알림 꺼짐',
                      style: TextStyle(
                        fontSize: 12,
                        color: _dailySummaryEnabled ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: _dailySummaryEnabled,
                          activeColor: brandColor,
                          onChanged: (val) {
                            setState(() => _dailySummaryEnabled = val);
                            _saveSettings();
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _isDailyExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _isDailyExpanded = !_isDailyExpanded);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 펼침 상태일 때만 수신 시간 선택 바 노출
                  if (_isDailyExpanded && _dailySummaryEnabled) ...[
                    const Divider(height: 1, color: Color(0xFFF2F2F7)),
                    ListTile(
                      title: const Text('리포트 수신 시간', style: TextStyle(fontSize: 13.5, color: Color(0xFF48484A))),
                      subtitle: const Text('하루 동안 분석된 이미지 현황을 요약 발송합니다.', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatTimeOfDay(_dailySummaryTime),
                          style: const TextStyle(color: brandColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _dailySummaryTime,
                        );
                        if (picked != null) {
                          setState(() => _dailySummaryTime = picked);
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. 테스트 알림 발송 버튼
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1E),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            label: const Text('푸시 알림 테스트 발송', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            onPressed: () async {
              await NotificationService().showNotification(
                id: 9999,
                title: '🔔 SALMON 알림 테스트',
                body: 'D-Day 및 일일 요약 리포트 설정이 정상 작동합니다.',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('테스트 푸시 알림을 전송했습니다.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13.5, color: Color(0xFF48484A))),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              activeColor: const Color(0xFFFF5247),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

