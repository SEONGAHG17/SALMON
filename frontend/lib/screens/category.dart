import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../styles/categorycolor.dart';
import '../styles/imageBox.dart';
import 'detail.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<dynamic> _allHistory = [];
  List<dynamic> _filteredList = [];
  List<String> _categories = ['전체'];
  String _selectedCategory = '전체';
  String _searchQuery = '';
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await CategoryColorManager().fetchCategoriesAndColors();

      final hRes = await http.get(Uri.parse('$baseUrl/api/v1/history/'));
      final cRes = await http.get(Uri.parse('$baseUrl/api/v1/history/categories'));

      if (hRes.statusCode == 200 && cRes.statusCode == 200 && mounted) {
        final hData = jsonDecode(utf8.decode(hRes.bodyBytes));
        final cData = jsonDecode(utf8.decode(cRes.bodyBytes));

        final rawList = cData['categories'] ?? [];
        final List<String> serverCats = rawList
            .map<String>((e) => e is Map ? e['name'].toString() : e.toString())
            .toList();

        setState(() {
          _allHistory = hData['history'] ?? [];
          _categories = ['전체', ...serverCats];
          if (!_categories.contains(_selectedCategory)) {
            _selectedCategory = '전체';
          }
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint("❌ [카테고리 데이터 조회 실패]: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredList = _allHistory.where((item) {
        final category = item['category']?.toString() ?? '';
        final summary = item['summary']?.toString().toLowerCase() ?? '';
        final actionData = item['action_data']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        final matchesCategory =
            (_selectedCategory == '전체') || (category == _selectedCategory);
        final matchesQuery = query.isEmpty ||
            summary.contains(query) ||
            actionData.contains(query) ||
            category.toLowerCase().contains(query);

        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final leftList = <dynamic>[];
    final rightList = <dynamic>[];
    for (int i = 0; i < _filteredList.length; i++) {
      if (i % 2 == 0) {
        leftList.add(_filteredList[i]);
      } else {
        rightList.add(_filteredList[i]);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'category',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1E),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '보관함 · ${_allHistory.length}개',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFA1A1A6),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1A1E)),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A6B)))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFFFF7A6B),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F4),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            _searchQuery = val;
                            _applyFilter();
                          },
                          decoration: InputDecoration(
                            hintText: '캡처한 내용을 검색해보세요',
                            hintStyle:
                                const TextStyle(color: Color(0xFFA1A1A6), fontSize: 14),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFFA1A1A6), size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear,
                                        size: 18, color: Color(0xFFA1A1A6)),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _applyFilter();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          final isCatErr = cat == 'ERROR';
                          final colors = CategoryColorManager().getColor(cat);

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = cat;
                                _applyFilter();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF1A1A1E)
                                    : (isCatErr
                                        ? const Color(0xFFFFEAEA)
                                        : (cat == '전체' ? Colors.white : colors['bg'])),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF1A1A1E)
                                      : (isCatErr
                                          ? const Color(0xFFFF6B6B).withOpacity(0.5)
                                          : const Color(0xFFE5E5E7)),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isCatErr
                                            ? const Color(0xFFFF6B6B)
                                            : (cat == '전체'
                                                ? const Color(0xFF6B6B70)
                                                : colors['fg'])),
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),
                  _filteredList.isEmpty
                      ? const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              '해당 조건의 분석 결과가 없습니다.',
                              style: TextStyle(
                                  color: Color(0xFF6B6B70), fontSize: 14),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverToBoxAdapter(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: leftList.map((item) {
                                      final colors = CategoryColorManager()
                                          .getColor(item['category'] ?? '');
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: _buildDynamicCard(item, colors),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    children: rightList.map((item) {
                                      final colors = CategoryColorManager()
                                          .getColor(item['category'] ?? '');
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 14),
                                        child: _buildDynamicCard(item, colors),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildDynamicCard(dynamic item, Map<String, Color> colors) {
    final bool isErr = ImageBoxStyle.isError(item);
    final imgUrl = item['image_url'];
    final category = isErr ? 'ERROR' : (item['category'] ?? '미분류');
    final summary = item['summary'] ?? (isErr ? '[분석 실패] 정보를 추출하지 못했습니다.' : '요약 내용 없음');
    final createdAt = item['created_at'] != null
        ? item['created_at'].toString().split('T')[0]
        : '최근';

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HistoryDetailScreen(item: item),
          ),
        );
        if (changed == true) _fetchData();
      },
      child: Container(
        width: double.infinity,
        decoration: ImageBoxStyle.getBoxDecoration(isErr),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imgUrl != null
                      ? Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF7F7F8),
                            child: const Icon(Icons.broken_image,
                                color: Color(0xFFA1A1A6)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFF7F7F8),
                          child: const Icon(Icons.image,
                              color: Color(0xFFA1A1A6)),
                        ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: isErr
                          ? ImageBoxStyle.getErrorBadgeDecoration()
                          : BoxDecoration(
                              color: colors['bg'],
                              borderRadius: BorderRadius.circular(6),
                            ),
                      child: Text(
                        category,
                        style: isErr
                            ? ImageBoxStyle.errorBadgeTextStyle
                            : TextStyle(
                                color: colors['fg'],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ImageBoxStyle.getSummaryTextStyle(isErr),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    createdAt,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFA1A1A6),
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
