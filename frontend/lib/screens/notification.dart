import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../styles/app_theme.dart';
import '../services/alert_storage.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  final Map<String, bool> _expandedState = {};

  // 한국 현재 시각 (KST)
  DateTime get _koreanNow => DateTime.now().toUtc().add(const Duration(hours: 9));

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // 어떤 타임존/UTC 문자열이 들어와도 정확한 한국 시간(KST)으로 변환
  DateTime _toKstDateTime(dynamic dateVal) {
    if (dateVal == null) return _koreanNow;
    try {
      if (dateVal is DateTime) {
        return dateVal.isUtc ? dateVal.add(const Duration(hours: 9)) : dateVal;
      }
      final str = dateVal.toString().trim();
      DateTime parsed = DateTime.parse(str);
      
      // UTC 표기이거나 Z/오프셋이 포함된 경우 한국 시간으로 9시간 더함
      if (str.endsWith('Z') || str.contains('+00') || parsed.isUtc) {
        return parsed.toUtc().add(const Duration(hours: 9));
      }
      return parsed;
    } catch (_) {
      return _koreanNow;
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final localAlerts = await AlertStorage.getAlerts();
      List<dynamic> combined = List.from(localAlerts);

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

          for (var r in remoteList) {
            final rId = (r['id'] ?? r['title'] ?? '').toString();
            if (rId.isNotEmpty && !combined.any((item) => (item['id'] ?? item['title'] ?? '').toString() == rId)) {
              combined.add(r);
            }
          }
        }
      } catch (apiError) {
        debugPrint("⚠️ [백엔드 알림 조회 생략 / 로컬 알림 표시]: $apiError");
      }

      // 한국 시간 기준 내림차순 정렬 (최신순)
      combined.sort((a, b) {
        final dateA = _toKstDateTime(a['createdAt'] ?? a['created_at'] ?? a['timestamp']);
        final dateB = _toKstDateTime(b['createdAt'] ?? b['created_at'] ?? b['timestamp']);
        return dateB.compareTo(dateA);
      });

      setState(() {
        _notifications = combined;
      });
    } catch (e) {
      debugPrint("❌ [알림 목록 조회 오류]: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllNotifications() async {
    try {
      await AlertStorage.clearAll();
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/v1/settings/notifications?user_id=default_user'),
        );
      } catch (_) {}

      setState(() {
        _notifications.clear();
        _expandedState.clear();
      });
    } catch (e) {
      debugPrint("❌ [알림 전체 삭제 실패]: $e");
    }
  }

  Future<void> _deleteSingleAlert(String id) async {
    try {
      await AlertStorage.deleteAlert(id);
      try {
        await http.delete(
          Uri.parse('$baseUrl/api/v1/settings/notifications/$id?user_id=default_user'),
        );
      } catch (_) {}

      setState(() {
        _notifications.removeWhere((item) => (item['id']?.toString() ?? '') == id);
      });
    } catch (e) {
      debugPrint("❌ [단일 알림 삭제 실패]: $e");
    }
  }

  String _getDateGroupLabel(dynamic dateVal) {
    final kstDate = _toKstDateTime(dateVal);
    final nowKst = _koreanNow;
    final today = DateTime(nowKst.year, nowKst.month, nowKst.day);
    final target = DateTime(kstDate.year, kstDate.month, kstDate.day);
    final diffDays = today.difference(target).inDays;

    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final weekdayStr = weekdayNames[kstDate.weekday - 1];

    if (diffDays == 0) {
      return '오늘 (${kstDate.month}월 ${kstDate.day}일)';
    } else if (diffDays == 1) {
      return '어제 (${kstDate.month}월 ${kstDate.day}일)';
    } else {
      return '${kstDate.month}월 ${kstDate.day}일 ($weekdayStr요일)';
    }
  }

  Map<String, List<dynamic>> _groupNotifications() {
    final Map<String, List<dynamic>> groups = {};

    for (var item in _notifications) {
      final rawDate = item['createdAt'] ?? item['created_at'] ?? item['timestamp'] ?? item['date'];
      final label = _getDateGroupLabel(rawDate);

      if (!groups.containsKey(label)) {
        groups[label] = [];
      }
      groups[label]!.add(item);
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groupedData = _groupNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '알림 내역 (최근 7일)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1E),
          ),
        ),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: _clearAllNotifications,
              child: const Text('모두 비우기', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        '최근 7일간 수신된 알림이 없습니다.',
                        style: TextStyle(color: Color(0xFFA1A1A6), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  color: AppColors.brand,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: groupedData.keys.length,
                    itemBuilder: (context, index) {
                      final groupLabel = groupedData.keys.elementAt(index);
                      final items = groupedData[groupLabel]!;

                      _expandedState.putIfAbsent(groupLabel, () => true);
                      final isExpanded = _expandedState[groupLabel]!;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E5E7)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.vertical(
                                top: const Radius.circular(18),
                                bottom: isExpanded ? Radius.zero : const Radius.circular(18),
                              ),
                              onTap: () {
                                setState(() {
                                  _expandedState[groupLabel] = !isExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: groupLabel.startsWith('오늘')
                                            ? const Color(0xFFFF5247)
                                            : const Color(0xFF8E8E93),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      groupLabel,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: groupLabel.startsWith('오늘')
                                            ? const Color(0xFF1A1A1E)
                                            : const Color(0xFF48484A),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2F2F7),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${items.length}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8E8E93),
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: const Color(0xFF8E8E93),
                                      size: 22,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded) ...[
                              const Divider(height: 1, color: Color(0xFFF2F2F7)),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(12),
                                itemCount: items.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, itemIndex) {
                                  final notif = items[itemIndex];
                                  final id = (notif['id'] ?? '$index-$itemIndex').toString();
                                  return _buildNotificationItem(notif, id);
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationItem(dynamic notif, String id) {
    final title = notif['title'] ?? '알림';
    final body = notif['body'] ?? '';
    final isDailySummary = notif['isDailySummary'] == true || notif['is_daily_summary'] == true;
    final rawDate = notif['createdAt'] ?? notif['created_at'] ?? notif['timestamp'] ?? notif['date'];
    
    // 한국 시간(KST) 시:분 포맷 (예: 08:44)
    final kstDateTime = _toKstDateTime(rawDate);
    final timeStr = '${kstDateTime.hour.toString().padLeft(2, '0')}:${kstDateTime.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 22),
      ),
      onDismissed: (_) => _deleteSingleAlert(id),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEBEBF0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDailySummary
                    ? const Color(0xFFFFEAEA)
                    : const Color(0xFFFFEBE8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDailySummary
                    ? Icons.analytics_rounded
                    : Icons.notifications_active_outlined,
                color: const Color(0xFFFF5247),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A1E),
                          ),
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 11, color: Color(0xFFA1A1A6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF6B6B70),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

