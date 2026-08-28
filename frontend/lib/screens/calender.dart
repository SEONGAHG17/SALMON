import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';
import '../constants/constants.dart';
import '../styles/app_theme.dart';
import '../styles/categorycolor.dart';
import 'detail.dart';
import 'edit.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<dynamic> _rawEvents = [];
  Map<dynamic, dynamic> _historyMap = {};
  bool _isLoading = true;

  // 1. 일정 전용 팔레트 (코랄색 제외: 블루, 그린, 오렌지/옐로우, 퍼플, 핑크, 틸, 인디고)
  final List<Color> _eventPalette = const [
    Color(0xFF5B8DEF), // 소프트 세룰리안 블루
    Color(0xFF48B585), // 소프트 세이지 그린
    Color(0xFFE89A3C), // 웜 애프리콧 오렌지
    Color(0xFF8A6FE8), // 소프트 아이리스 퍼플
    Color(0xFFE06287), // 뮤트 더스티 로즈
    Color(0xFF2EA5B8), // 소프트 딥 틸
    Color(0xFF6878D6), // 슬레이트 페리윙클
  ];

  Color _getEventColor(int index) {
    return _eventPalette[index % _eventPalette.length];
  }

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchCalendarData();
  }

  Future<void> _fetchCalendarData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await CategoryColorManager().fetchCategoriesAndColors();

      final hRes = await http.get(Uri.parse('$baseUrl/api/v1/history/'));
      if (hRes.statusCode == 200 && mounted) {
        final hData = jsonDecode(utf8.decode(hRes.bodyBytes));
        final List<dynamic> history = hData['history'] ?? [];
        _historyMap = {for (var h in history) if (h['id'] != null) h['id']: h};
      }

      final cRes = await http.get(Uri.parse('$baseUrl/api/v1/calendar/'));
      if (cRes.statusCode == 200 && mounted) {
        final cData = jsonDecode(utf8.decode(cRes.bodyBytes));
        setState(() {
          _rawEvents = cData['events'] ?? [];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToDetail(Map<String, dynamic> calendarEvent) async {
    final itemId = calendarEvent['item_id'];

    if (itemId != null && _historyMap.containsKey(itemId)) {
      final changed = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryDetailScreen(item: _historyMap[itemId]),
        ),
      );
      if (changed == true) _fetchCalendarData();
      return;
    }

    final fallbackItem = {
      'id': calendarEvent['item_id'] ?? 0,
      'summary': calendarEvent['title'] ?? '일정 정보',
      'category': calendarEvent['category'] ?? '일정',
      'action_type': '일정',
      'action_data': calendarEvent['end_date'] != null
          ? "${calendarEvent['event_date']} ~ ${calendarEvent['end_date']}"
          : calendarEvent['event_date'],
      'image_url': calendarEvent['image_url'],
      'created_at': calendarEvent['created_at'],
    };

    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryDetailScreen(item: fallbackItem),
      ),
    );
    if (changed == true) _fetchCalendarData();
  }

  DateTime _parseDate(String dateStr) {
    final p = dateStr.substring(0, 10).split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    List<Map<String, dynamic>> matched = [];

    for (int i = 0; i < _rawEvents.length; i++) {
      final ev = _rawEvents[i];
      if (ev['event_date'] == null) continue;

      final start = _parseDate(ev['event_date']);
      final end = ev['end_date'] != null ? _parseDate(ev['end_date']) : start;

      if (!target.isBefore(start) && !target.isAfter(end)) {
        final isRange = end.isAfter(start);
        final isStart = target.isAtSameMomentAs(start);
        final isEnd = target.isAtSameMomentAs(end);

        matched.add({
          'event': ev,
          'color': _getEventColor(i),
          'isRange': isRange,
          'isStart': isStart,
          'isEnd': isEnd,
        });
      }
    }
    return matched;
  }

  // 2. 상단 3단계 (월 - 2주 - 1주) 캡슐 닷 인디케이터 (활성화 시 코랄색 적용)
  Widget _buildCalendarFormatDots() {
    final formats = [
      {'format': CalendarFormat.month, 'label': '월'},
      {'format': CalendarFormat.twoWeeks, 'label': '2주'},
      {'format': CalendarFormat.week, 'label': '1주'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: formats.map((item) {
          final f = item['format'] as CalendarFormat;
          final isSelected = _calendarFormat == f;

          return GestureDetector(
            onTap: () => setState(() => _calendarFormat = f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? AppSpacing.sm : 0,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                // 활성화 시 팀원의 코랄 브랜드 컬러(AppColors.brand) 적용
                color: isSelected ? AppColors.brand : AppColors.textTertiary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: isSelected
                  ? Text(
                      item['label'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTypography.fontFamily,
                      ),
                    )
                  : const SizedBox(width: 6, height: 6),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCustomCalendarHeader() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthName = months[_focusedDay.month - 1];

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, 10, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_left, size: 22, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
              });
            },
          ),
          const SizedBox(width: AppSpacing.sm + 2),
          Text(
            "$monthName ${_focusedDay.year}",
            style: AppTypography.sectionTitle,
          ),
          const Spacer(),
          _buildCalendarFormatDots(),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.chevron_right, size: 22, color: AppColors.textPrimary),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStyledEventCard(Map<String, dynamic> info) {
    final item = info['event'] as Map<String, dynamic>;
    final Color borderColor = info['color'] as Color;
    final isRange = info['isRange'] as bool;

    final itemId = item['item_id'];
    final linkedHistory = itemId != null ? _historyMap[itemId] : null;

    final category = (item['category'] != null && item['category'].toString().trim().isNotEmpty)
        ? item['category'].toString()
        : (linkedHistory?['category'] ?? '기타');

    final catColors = CategoryColorManager().getColor(category);
    final imgUrl = item['image_url'] ?? linkedHistory?['image_url'];
    final title = item['title'] ?? linkedHistory?['summary'] ?? '일정 정보 없음';

    final dateText = isRange
        ? "마감 ${item['end_date'] ?? item['event_date']}"
        : "${item['event_date']}";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: AppShadows.card,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _navigateToDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: imgUrl != null
                    ? Image.network(
                        imgUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.bgSoft,
                          child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: AppColors.bgSoft,
                        child: const Icon(Icons.image, color: AppColors.textTertiary),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: catColors['bg'],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: catColors['fg'],
                              fontFamily: AppTypography.fontFamily,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.calendar_month, size: 16, color: AppColors.fashionFg),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateText,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.textSecondary),
                tooltip: '일정 수정',
                onPressed: () => EditDialogs.showCalendarEditDialog(
                  context: context,
                  event: item,
                  onSaved: _fetchCalendarData,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: AppColors.bgSofter,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: const Text(
          '등록된 일정',
          style: AppTypography.sectionTitle,
        ),
        actions: [
          IconButton(
            onPressed: _fetchCalendarData,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => EditDialogs.showCalendarEditDialog(
          context: context,
          initialDate: _selectedDay ?? _focusedDay,
          onSaved: _fetchCalendarData,
        ),
        backgroundColor: AppColors.brand,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : Column(
              children: [
                _buildCustomCalendarHeader(),
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  headerVisible: false,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) => setState(() => _calendarFormat = format),
                  onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, isSelected: false),
                    todayBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, isToday: true, isSelected: false),
                    selectedBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, isSelected: true),
                  ),
                ),
                const Divider(height: AppSpacing.xxl),
                Expanded(
                  child: selectedEvents.isEmpty
                      ? const Center(
                          child: Text(
                            '해당 날짜에 등록된 일정이 없습니다.',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          itemCount: selectedEvents.length,
                          itemBuilder: (context, index) {
                            return _buildHistoryStyledEventCard(selectedEvents[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildCustomDayCell(DateTime day, {bool isToday = false, bool isSelected = false}) {
    final events = _getEventsForDay(day);
    final rangeEvents = events.where((e) => e['isRange'] == true).toList();
    final dotEvents = events.where((e) => e['isRange'] == false).toList();

    const int maxRange = 2;
    const int maxDots = 3;

    // 실제 화면 한도를 넘어간 일정이 있을 때만 계산
    final int hiddenRangeCount = rangeEvents.length > maxRange ? (rangeEvents.length - maxRange) : 0;
    final int hiddenDotCount = dotEvents.length > maxDots ? (dotEvents.length - maxDots) : 0;
    final int hiddenTotal = hiddenRangeCount + hiddenDotCount;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: isSelected
          ? BoxDecoration(
              border: Border.all(color: AppColors.brand, width: 2),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            )
          : null,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 기간 일정 바 (최대 2개 노출)
          if (rangeEvents.isNotEmpty)
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Column(
                children: rangeEvents.take(maxRange).map((r) {
                  final Color c = r['color'];
                  final bool isStart = r['isStart'];
                  final bool isEnd = r['isEnd'];

                  return Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 1),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.85),
                      borderRadius: BorderRadius.horizontal(
                        left: isStart ? const Radius.circular(4) : Radius.zero,
                        right: isEnd ? const Radius.circular(4) : Radius.zero,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // 2. 날짜 숫자
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                color: isToday ? AppColors.brand : AppColors.textPrimary,
                fontFamily: AppTypography.fontFamily,
              ),
            ),
          ),

          // 3. 단일 일정 도트 (최대 3개) 및 실제 초과분(+@) 뱃지
          if (dotEvents.isNotEmpty || hiddenTotal > 0)
            Positioned(
              bottom: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ...dotEvents.take(maxDots).map((d) {
                    final Color c = d['color'];
                    return Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                  if (hiddenTotal > 0) ...[
                    const SizedBox(width: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+$hiddenTotal',
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          height: 1.1,
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
