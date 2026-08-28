import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../styles/categorycolor.dart';
import '../styles/imageBox.dart';
import 'detail.dart';
import 'edit.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _historyList = [];
  List<String> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await CategoryColorManager().fetchCategoriesAndColors();

      final hRes = await http.get(Uri.parse('$baseUrl/api/v1/history/'));
      final cRes = await http.get(Uri.parse('$baseUrl/api/v1/history/categories'));

      if (hRes.statusCode == 200 && mounted) {
        final hData = jsonDecode(utf8.decode(hRes.bodyBytes));
        _historyList = hData['history'] ?? [];
      }
      if (cRes.statusCode == 200 && mounted) {
        final cData = jsonDecode(utf8.decode(cRes.bodyBytes));
        final raw = cData['categories'] ?? [];
        _categories = raw
            .map<String>((e) => e is Map ? e['name'].toString() : e.toString())
            .toList();
      }
    } catch (e) {
      debugPrint("데이터 로드 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("전체 데이터 삭제"),
        content: const Text("모든 분석 히스토리와 연결된 일정이 영구 삭제됩니다. 진행하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("전체 비우기", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final res = await http.delete(Uri.parse('$baseUrl/api/v1/history/'));
      if (res.statusCode == 200) {
        _loadAllData();
      }
    }
  }

  Map<String, List<dynamic>> _groupHistoryByDate() {
    Map<String, List<dynamic>> grouped = {};
    for (var item in _historyList) {
      String date = (item['created_at'] != null)
          ? item['created_at'].toString().split('T')[0]
          : "기타";
      grouped.putIfAbsent(date, () => []).add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupHistoryByDate();
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('분석 히스토리',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A1E))),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            tooltip: '전체 데이터 삭제',
            onPressed: _historyList.isEmpty ? null : _clearAllData,
          ),
          IconButton(
              onPressed: _loadAllData,
              icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1E))),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyList.isEmpty
              ? const Center(child: Text('저장된 히스토리가 없습니다.'))
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final items = grouped[date]!;
                      final isToday = (date == todayStr);

                      if (isToday) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  "오늘 등록된 기록",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1E)),
                                ),
                              ),
                              ...items.map((item) => _buildCard(item)),
                              const Divider(height: 24),
                            ],
                          ),
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE5E5E7)),
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: false,
                          title: Text(date,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${items.length}개의 기록",
                              style: const TextStyle(
                                  color: Color(0xFFA1A1A6), fontSize: 13)),
                          children: items.map((item) => _buildCard(item)).toList(),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildCard(dynamic item) {
    final bool isErr = ImageBoxStyle.isError(item);
    final actionType = item['action_type'] ?? '';
    final category = isErr ? 'ERROR' : (item['category'] ?? '미분류');
    final catColors = CategoryColorManager().getColor(category);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: ImageBoxStyle.getBoxDecoration(isErr),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final changed = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => HistoryDetailScreen(item: item)),
          );
          if (changed == true) _loadAllData();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['image_url'] != null
                    ? Image.network(
                        item['image_url'],
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFF2F2F4),
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFFF2F2F4),
                        child: const Icon(Icons.image)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: isErr
                              ? ImageBoxStyle.getErrorBadgeDecoration()
                              : BoxDecoration(
                                  color: catColors['bg'],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                          child: Text(
                            category,
                            style: isErr
                                ? ImageBoxStyle.errorBadgeTextStyle
                                : TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: catColors['fg']),
                          ),
                        ),
                        const Spacer(),
                        if (!isErr) ...[
                          if (actionType.contains('일정') ||
                              actionType.contains('캘린더'))
                            const Icon(Icons.calendar_month,
                                size: 16, color: Colors.blueAccent)
                          else if (actionType.contains('지도') ||
                              actionType.contains('매핑'))
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.redAccent)
                          else if (actionType.contains('링크'))
                            const Icon(Icons.link,
                                size: 16, color: Colors.orangeAccent),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['summary'] ?? (isErr ? '[분석 실패] 정보를 추출하지 못했습니다.' : '요약 내용 없음'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ImageBoxStyle.getSummaryTextStyle(isErr),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon:
                    const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') {
                    EditDialogs.showHistoryEditDialog(
                      context: context,
                      item: item,
                      categories: _categories,
                      onUpdated: _loadAllData,
                    );
                  } else if (val == 'delete') {
                    EditDialogs.showDeleteConfirmDialog(
                      context: context,
                      itemId: item['id'],
                      onDeleted: _loadAllData,
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  if (!isErr) const PopupMenuItem(value: 'edit', child: Text('수정')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('삭제', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
