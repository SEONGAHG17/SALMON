import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../constants/constants.dart';
import '../styles/categorycolor.dart';
import '../styles/imageBox.dart';
import 'edit.dart';

class HistoryDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isFromUpload;

  const HistoryDetailScreen({
    super.key,
    required this.item,
    this.isFromUpload = false,
  });

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Map<String, dynamic> _currentItem;
  List<String> _categories = [];
  Map<String, dynamic>? _linkedCalendarEvent;
  bool _isDataChanged = false;

  @override
  void initState() {
    super.initState();
    _currentItem = Map<String, dynamic>.from(widget.item);
    _fetchCategories();
    _fetchLinkedCalendarEvent();
  }

  Future<void> _fetchCategories() async {
    try {
      await CategoryColorManager().fetchCategoriesAndColors();
      final res = await http.get(Uri.parse('$baseUrl/api/v1/history/categories'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final raw = data['categories'] ?? [];
        setState(() {
          _categories = raw.map<String>((e) => e is Map ? e['name'].toString() : e.toString()).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchLinkedCalendarEvent() async {
    final actionType = _currentItem['action_type'] ?? '';
    if (!actionType.contains('일정') && !actionType.contains('캘린더')) return;

    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/calendar/'));
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final List<dynamic> events = data['events'] ?? [];
        final matched = events.firstWhere(
          (e) => e['item_id'] == _currentItem['id'],
          orElse: () => null,
        );

        if (matched != null && mounted) {
          setState(() {
            _linkedCalendarEvent = Map<String, dynamic>.from(matched);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _deleteItem(dynamic itemId) async {
    if (itemId == null) return;
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/history/$itemId'),
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('데이터가 정상적으로 삭제되었습니다.')),
        );
        _navigateToHomeOrPop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  void _navigateToHomeOrPop([bool? forceChanged]) {
    if (widget.isFromUpload) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } else {
      final result = forceChanged ?? _isDataChanged;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, result);
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  void _openImageViewer(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.white70, size: 64),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNaverMap(String addressQuery) async {
    final query = addressQuery.trim();
    if (query.isEmpty) return;
    // 💡 151번 줄 수정: 깨진 마크다운 태그를 제거하고 올바른 URL 문자열 보간 적용
    final url = Uri.parse('https://m.map.naver.com/search2/search.naver?query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openBrowserUrl(String rawUrl) async {
    var cleanUrl = rawUrl.trim();
    if (cleanUrl.isEmpty) return;
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }
    final url = Uri.parse(cleanUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  String _resolveSearchTarget() {
    final actionData = _currentItem['action_data']?.toString().trim() ?? '';
    if (actionData.isNotEmpty) return actionData;

    if (_currentItem['places'] is List && (_currentItem['places'] as List).isNotEmpty) {
      final firstPlace = _currentItem['places'][0];
      if (firstPlace is Map) {
        final address = firstPlace['address']?.toString().trim() ?? '';
        if (address.isNotEmpty) return address;
        final placeName = firstPlace['place_name']?.toString().trim() ?? '';
        if (placeName.isNotEmpty) return placeName;
      }
    }
    return _currentItem['summary']?.toString().trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isErrorState = ImageBoxStyle.isError(_currentItem);
    final String catName = _currentItem['category']?.toString() ?? (isErrorState ? 'ERROR' : '기타');
    final String errorReason = _currentItem['error_reason']?.toString() ??
        (_currentItem['analysis'] != null && _currentItem['analysis']['error_reason'] != null
            ? _currentItem['analysis']['error_reason'].toString()
            : '');

    final actionType = _currentItem['action_type'] ?? '해당없음';
    final isCalendarAction = !isErrorState && (actionType.contains('일정') || actionType.contains('캘린더'));
    final isMapAction = !isErrorState && (actionType.contains('지도') || actionType.contains('매핑'));
    final isLinkAction = !isErrorState && (actionType.contains('링크') || actionType.contains('웹'));

    final searchTarget = _resolveSearchTarget();
    final rawActionData = _currentItem['action_data']?.toString().trim() ?? '';
    final isUrl = isLinkAction ||
        searchTarget.startsWith('http://') ||
        searchTarget.startsWith('https://') ||
        searchTarget.contains('.com') ||
        searchTarget.contains('.kr');

    final imageUrl = _currentItem['image_url'];
    final displayCategory = isErrorState ? 'ERROR' : catName;
    final catColors = CategoryColorManager().getColor(displayCategory);

    String calendarPeriodText = '';
    if (_linkedCalendarEvent != null) {
      final sDate = _linkedCalendarEvent!['event_date'];
      final eDate = _linkedCalendarEvent!['end_date'];
      if (sDate != null) {
        calendarPeriodText = (eDate != null && eDate != sDate) ? "$sDate ~ $eDate" : "$sDate";
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToHomeOrPop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              widget.isFromUpload ? Icons.home_rounded : Icons.arrow_back_ios_new_rounded,
              color: const Color(0xFF1A1A1E),
            ),
            tooltip: widget.isFromUpload ? '홈으로 이동' : '뒤로가기',
            onPressed: () => _navigateToHomeOrPop(),
          ),
          title: const Text(
            '분석 상세 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1E)),
          ),
          actions: [
            if (!isErrorState)
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF1A1A1E)),
                onPressed: () => EditDialogs.showHistoryEditDialog(
                  context: context,
                  item: _currentItem,
                  categories: _categories,
                  onUpdated: () {
                    _isDataChanged = true;
                    _navigateToHomeOrPop(true);
                  },
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => EditDialogs.showDeleteConfirmDialog(
                context: context,
                itemId: _currentItem['id'],
                onDeleted: () => _deleteItem(_currentItem['id']),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                GestureDetector(
                  onTap: () => _openImageViewer(imageUrl),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 180,
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image, size: 48)),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('탭하여 원본 확대', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              if (isMapAction && !isUrl)
                Card(
                  color: Colors.green.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade200),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green),
                            SizedBox(width: 8),
                            Text('지도 검색 위치', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(searchTarget.isNotEmpty ? searchTarget : '등록된 주소 정보가 없습니다.', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: searchTarget.isNotEmpty ? () => _openNaverMap(searchTarget) : null,
                          icon: const Icon(Icons.map_outlined, color: Colors.white),
                          label: const Text('네이버 지도에서 위치 확인', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF03C75A)),
                        ),
                      ],
                    ),
                  ),
                ),

              if (isCalendarAction)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: Colors.blue, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('캘린더 일정으로 등록됨', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 15)),
                            if (calendarPeriodText.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text('일정 기간: $calendarPeriodText', style: TextStyle(color: Colors.blue.shade900, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                decoration: ImageBoxStyle.getBoxDecoration(isErrorState),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('카테고리', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: isErrorState
                              ? ImageBoxStyle.getErrorBadgeDecoration()
                              : BoxDecoration(
                                  color: catColors['bg'],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                          child: Text(
                            displayCategory,
                            style: isErrorState
                                ? ImageBoxStyle.errorBadgeTextStyle
                                : TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: catColors['fg']),
                          ),
                        ),
                      ],
                    ),
                    
                    if (!isErrorState) ...[
                      const Divider(height: 24),
                      _buildInfoRow('액션 분류', actionType),
                    ],
                    
                    if (!isErrorState && calendarPeriodText.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow('캘린더 등록 기간', calendarPeriodText),
                    ],

                    const Divider(height: 24),
                    _buildInfoRow(
                      '요약 내용',
                      isErrorState
                          ? (errorReason.isNotEmpty ? '[분석 실패] $errorReason' : (_currentItem['summary'] ?? '[분석 실패] 정보를 추출하지 못했습니다.'))
                          : (_currentItem['summary'] ?? '-'),
                      isErrorState: isErrorState,
                    ),

                    if (!isErrorState && searchTarget.isNotEmpty) ...[
                      const Divider(height: 24),
                      if (actionType.contains('링크') || searchTarget.startsWith('http'))
                        _buildHyperlinkRow('바로가기 링크', searchTarget, () => _openBrowserUrl(searchTarget))
                      else
                        _buildInfoRow('검색 주소 / 장소', searchTarget),
                    ] else if (!isErrorState && rawActionData.isNotEmpty) ...[
                      const Divider(height: 24),
                      if (rawActionData.startsWith('http'))
                        _buildHyperlinkRow('바로가기 링크', rawActionData, () => _openBrowserUrl(rawActionData))
                      else
                        _buildInfoRow('상세 데이터', rawActionData),
                    ],
                  ],
                ),
              ),

              if (widget.isFromUpload) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _navigateToHomeOrPop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      '확인 (홈으로 이동)',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isErrorState = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          value,
          style: ImageBoxStyle.getSummaryTextStyle(isErrorState),
        ),
      ],
    );
  }

  Widget _buildHyperlinkRow(String label, String urlText, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              // 💡 494번 줄 수정: dynamic 키워드 제거하고 올바른 MainAxisSize 지정
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    urlText,
                    style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.blueAccent, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.open_in_new, size: 16, color: Colors.blueAccent),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
