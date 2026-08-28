import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../styles/app_theme.dart';
import '../styles/categorycolor.dart';
import '../services/notification_service.dart';
import 'allDday.dart';
import 'calender.dart';
import 'detail.dart';
import 'history.dart';
import 'notification.dart';
import 'setting.dart';
import 'settingcategory.dart';
import 'upload.dart';
import 'chatbot.dart';

class HomeScreen extends StatefulWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _recentItems = [];
  List<Map<String, dynamic>> _deadlineItems = [];
  String _selectedDeadlineFilter = '전체';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await CategoryColorManager().fetchCategoriesAndColors();

      // 1. 히스토리 목록 불러오기
      final historyRes = await http.get(Uri.parse('$baseUrl/api/v1/history/'));
      Map<dynamic, dynamic> historyMap = {};

      if (historyRes.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(historyRes.bodyBytes));
        final List<dynamic> allHistory = data['history'] ?? [];

        setState(() {
          _recentItems = allHistory.take(10).toList();
        });

        for (var h in allHistory) {
          if (h['id'] != null) {
            historyMap[h['id']] = h;
          }
        }
      }

      // 2. 캘린더 일정 및 마감 임박 데이터 연동
      final calendarRes = await http.get(Uri.parse('$baseUrl/api/v1/calendar/'));
      if (calendarRes.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(calendarRes.bodyBytes));
        final List<dynamic> events = data['events'] ?? [];
        _processDeadlines(events, historyMap);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processDeadlines(List<dynamic> events, Map<dynamic, dynamic> historyMap) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<Map<String, dynamic>> processed = [];

    for (var ev in events) {
      final dateStr = ev['end_date'] ?? ev['event_date'];
      if (dateStr == null) continue;

      try {
        final cleanDate = dateStr.toString().trim();
        final p = cleanDate.substring(0, 10).split('-');
        final targetDate = DateTime(
          int.parse(p[0]),
          int.parse(p[1]),
          int.parse(p[2]),
        );

        final diffDays = targetDate.difference(today).inDays;

        if (diffDays >= 0) {
          final linkedHistory = historyMap[ev['item_id']];
          final category = (ev['category'] != null && ev['category'].toString().trim().isNotEmpty)
              ? ev['category']
              : (linkedHistory?['category'] ?? '기타');
          final imgUrl = ev['image_url'] ?? linkedHistory?['image_url'];

          processed.add({
            'raw': ev,
            'title': ev['title'] ?? linkedHistory?['summary'] ?? '일정',
            'category': category,
            'image_url': imgUrl,
            'date': targetDate,
            'dDay': diffDays,
            'dateStr': cleanDate.substring(0, 10),
          });
        }
      } catch (_) {}
    }

    processed.sort((a, b) => (a['dDay'] as int).compareTo(b['dDay'] as int));

    setState(() {
      _deadlineItems = processed;
    });

    // 💡 D-7, D-10을 포함한 마감 임박 알림 동기화 트리거
    NotificationService().syncDeadlineNotifications(processed);
  }

  Map<String, Color> _getDDayStyle(int dDay) {
    if (dDay <= 3) {
      return {'bg': const Color(0xFFFFE5E2), 'fg': const Color(0xFFE53935)};
    } else if (dDay <= 7) {
      return {'bg': const Color(0xFFFFF0D6), 'fg': const Color(0xFFB87700)};
    } else {
      return {'bg': const Color(0xFFE2F3E7), 'fg': const Color(0xFF2E7D32)};
    }
  }

  List<Map<String, dynamic>> _getFilteredDeadlines() {
    return _deadlineItems.where((item) {
      final dDay = item['dDay'] as int;
      if (_selectedDeadlineFilter == '오늘·내일') {
        return dDay == 0 || dDay == 1;
      } else if (_selectedDeadlineFilter == '이번주') {
        return dDay >= 0 && dDay <= 7;
      } else if (_selectedDeadlineFilter == '이후') {
        return dDay > 7;
      }
      return true;
    }).toList();
  }

  void _openChatSearch(String query) {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return;

    _searchController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(initialQuery: cleanQuery),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/salmonImage.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 8),
            const Text(
              'SALMON',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1E),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1A1E), size: 24),
            tooltip: '알림 내역',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1E)),
            tooltip: '새로고침',
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.brand,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChatSearchBar(),
                    const SizedBox(height: 24),
                    _buildRecentImagesSection(),
                    const SizedBox(height: 24),
                    _buildQuickActionCards(),
                    const SizedBox(height: 28),
                    _buildDeadlineSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildChatSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: _openChatSearch,
        decoration: InputDecoration(
          hintText: '저장된 스크린샷 내용 물어보기 (예: 공모전, 14)',
          hintStyle: const TextStyle(color: Color(0xFFA1A1A6), fontSize: 14),
          prefixIcon: const Icon(Icons.auto_awesome, color: AppColors.brand, size: 20),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFA1A1A6), size: 20),
            onPressed: () => _openChatSearch(_searchController.text),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRecentImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '최근 분석 이미지',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1E)),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                _loadDashboardData();
              },
              child: const Text(
                '전체보기',
                style: TextStyle(fontSize: 14, color: AppColors.brand, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _recentItems.isEmpty
            ? Container(
                height: 120,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E7)),
                ),
                child: const Text('등록된 스크린샷이 없습니다.', style: TextStyle(color: Color(0xFFA1A1A6))),
              )
            : SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentItems.length,
                  itemBuilder: (context, index) {
                    final item = _recentItems[index];
                    final imgUrl = item['image_url'];

                    return GestureDetector(
                      onTap: () async {
                        final changed = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HistoryDetailScreen(item: item)),
                        );
                        if (changed == true) _loadDashboardData();
                      },
                      child: Container(
                        width: 105,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E5E7)),
                          color: Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: imgUrl != null
                              ? Image.network(
                                  imgUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF7F7F8),
                                    child: const Icon(Icons.image, color: Color(0xFFA1A1A6)),
                                  ),
                                )
                              : Container(
                                  color: const Color(0xFFF7F7F8),
                                  child: const Icon(Icons.image, color: Color(0xFFA1A1A6)),
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildQuickActionCards() {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            title: '새 스크린샷',
            icon: Icons.add_photo_alternate_outlined,
            color: const Color(0xFFFF7A6B),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
              _loadDashboardData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            title: '카테고리 설정',
            icon: Icons.category_outlined,
            color: const Color(0xFF0D6A85),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingCategoryScreen()),
              );
              _loadDashboardData();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            title: '전체 설정',
            icon: Icons.settings_outlined,
            color: const Color(0xFF6B3FCC),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineSection() {
    final todayCount = _deadlineItems.where((e) => (e['dDay'] as int) == 0).length;
    final weekCount =
        _deadlineItems.where((e) => (e['dDay'] as int) >= 0 && (e['dDay'] as int) <= 7).length;
    final laterCount = _deadlineItems.where((e) => (e['dDay'] as int) > 7).length;
    final filteredList = _getFilteredDeadlines();

    // 💡 홈 화면에는 최대 3개만 노출
    final visibleList = filteredList.take(3).toList();
    final int extraCount = filteredList.length - visibleList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '마감 임박',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1E),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B6B70)),
            children: [
              const TextSpan(text: '놓치면 안 되는 '),
              TextSpan(
                text: '${_deadlineItems.length}건',
                style: const TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '이 있어요'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('오늘', '$todayCount', const Color(0xFFE53935))),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard('이번주', '$weekCount', const Color(0xFFB87700))),
            const SizedBox(width: 10),
            Expanded(child: _buildSummaryCard('이후', '$laterCount', const Color(0xFF2E7D32))),
          ],
        ),
        const SizedBox(height: 16),

        // 좌측 필터 탭 & 우측 끝 밀착 +@ 버튼
        Row(
          children: [
            Row(
              children: ['전체', '오늘·내일', '이번주', '이후'].map((filter) {
                final isSelected = _selectedDeadlineFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDeadlineFilter = filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1A1A1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1A1A1E) : const Color(0xFFE5E5E7),
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF6B6B70),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            // 💡 3개 초과 건이 있을 때 allDday.dart로 이동
            if (extraCount > 0)
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllDdayScreen(
                        deadlineItems: _deadlineItems,
                        initialFilter: _selectedDeadlineFilter,
                      ),
                    ),
                  );
                  _loadDashboardData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+$extraCount',
                        style: const TextStyle(
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // 최대 3개 목록 카드 렌더링
        visibleList.isEmpty
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E5E7)),
                ),
                child: const Text(
                  '해당 조건의 마감 임박 일정이 없습니다.',
                  style: TextStyle(color: Color(0xFFA1A1A6), fontSize: 14),
                ),
              )
            : Column(
                children: visibleList.map((item) => _buildDeadlineCard(item)).toList(),
              ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, Color countColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6B70), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: countColor)),
              const SizedBox(width: 4),
              const Text(
                '건',
                style: TextStyle(fontSize: 13, color: Color(0xFFA1A1A6), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineCard(Map<String, dynamic> item) {
    final title = item['title'] as String;
    final category = item['category'] as String;
    final dateStr = item['dateStr'] as String;
    final dDay = item['dDay'] as int;
    final imgUrl = item['image_url'];

    final catColors = CategoryColorManager().getColor(category);
    final dDayStyle = _getDDayStyle(dDay);
    final periodSubtitle = dDay == 0 ? "유효기간 오늘까지" : "마감 $dateStr";
    final dDayText = dDay == 0 ? "D-Day" : "D-$dDay";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E5E7)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalendarScreen()),
            );
            _loadDashboardData();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: catColors['bg'],
                    child: imgUrl != null
                        ? Image.network(
                            imgUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.event, color: catColors['fg'], size: 22),
                          )
                        : Icon(Icons.event, color: catColors['fg'], size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColors['bg'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: catColors['fg'],
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        periodSubtitle,
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFA1A1A6)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 64,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dDayStyle['bg'],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    dDayText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: dDayStyle['fg'],
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
