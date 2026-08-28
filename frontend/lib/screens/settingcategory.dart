import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';
import '../styles/app_theme.dart';

class SettingCategoryScreen extends StatefulWidget {
  const SettingCategoryScreen({super.key});

  @override
  State<SettingCategoryScreen> createState() => _SettingCategoryScreenState();
}

class _SettingCategoryScreenState extends State<SettingCategoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  // 전체 색상 팔레트 풀 (15종)
  final List<Color> _paletteColors = const [
    Color(0xFF5AC8FA), // 하늘
    Color(0xFFFF9500), // 주황
    Color(0xFFAF52DE), // 보라
    Color(0xFF34C759), // 초록
    Color(0xFF5856D6), // 남색
    Color(0xFF8E8E93), // 회색
    Color(0xFFFF3B30), // 빨강
    Color(0xFFFF2D55), // 핑크
    Color(0xFFFFCC00), // 노랑
    Color(0xFF007AFF), // 파랑
    Color(0xFF30B0C7), // 청록
    Color(0xFF5E5CE6), // 인디고
    Color(0xFFA2845E), // 브라운
    Color(0xFF636366), // 다크그레이
    Color(0xFF2C2C2E), // 블랙
  ];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // 카테고리 전체 목록 및 색상 불러오기
  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/settings/categories'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("❌ 카테고리 목록 조회 실패: $e");
      setState(() => _isLoading = false);
    }
  }

  // 색상 HEX 문자열 -> Color 변환 유틸
  Color _hexToColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return AppColors.brand;
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.brand;
    }
  }

  // Color -> HEX 문자열 변환 유틸
  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // 현재 다른 카테고리에서 사용 중인 색상 HEX Set 조회
  Set<String> _getUsedColorHexes({int? excludeCategoryId}) {
    final used = <String>{};
    for (final cat in _categories) {
      final int catId = cat['id'] ?? 0;
      if (excludeCategoryId != null && catId == excludeCategoryId) {
        continue; // 자기 자신의 현재 색상은 선택 가능하도록 제외
      }
      final String? hex = cat['color_hex'];
      if (hex != null && hex.isNotEmpty) {
        used.add(hex.toUpperCase());
      }
    }
    return used;
  }

  // 1. 색상 변경 API 호출
  Future<void> _updateColor(int categoryId, Color newColor) async {
    final hexCode = _colorToHex(newColor);
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/v1/settings/categories/$categoryId/color'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'color_hex': hexCode}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("카테고리 색상이 변경되었습니다.")),
        );
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("색상 변경에 실패했습니다.")),
        );
      }
    } catch (e) {
      debugPrint("❌ 색상 변경 에러: $e");
    }
  }

  // 2. 카테고리 삭제 API 호출
  Future<void> _deleteCategory(int categoryId, String name) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/v1/settings/categories/$categoryId?name=${Uri.encodeComponent(name)}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("카테고리가 삭제되었습니다.")),
        );
        _fetchCategories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("카테고리 삭제에 실패했습니다.")),
        );
      }
    } catch (e) {
      debugPrint("❌ 카테고리 삭제 에러: $e");
    }
  }

  // 3. 카테고리 추가 다이얼로그
  void _showAddCategoryDialog() {
    final textController = TextEditingController();
    final usedColors = _getUsedColorHexes();

    // 사용되지 않은 첫 번째 색상을 기본 선택값으로 지정
    Color selectedColor = _paletteColors.firstWhere(
      (c) => !usedColors.contains(_colorToHex(c).toUpperCase()),
      orElse: () => _paletteColors[0],
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('새 카테고리 추가', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: '카테고리 이름 입력',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('뱃지 색상 선택 (중복 사용 불가)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _paletteColors.map((color) {
                    final hex = _colorToHex(color).toUpperCase();
                    final isUsed = usedColors.contains(hex);
                    final isSelected = selectedColor.value == color.value;

                    return GestureDetector(
                      onTap: isUsed
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("이미 다른 카테고리에서 사용 중인 색상입니다."),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          : () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isUsed ? color.withOpacity(0.3) : color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                        ),
                        child: isUsed
                            ? const Icon(Icons.lock, size: 14, color: Colors.white70)
                            : (isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final name = textController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(ctx);

                  try {
                    await http.post(
                      Uri.parse('$baseUrl/api/v1/settings/categories'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode({
                        'name': name,
                        'color_hex': _colorToHex(selectedColor),
                      }),
                    );
                    _fetchCategories();
                  } catch (e) {
                    debugPrint("❌ 카테고리 추가 에러: $e");
                  }
                },
                child: const Text('추가'),
              ),
            ],
          );
        },
      ),
    );
  }

  // 4. 색상 변경 다이얼로그 (중복 색상 비활성화)
  void _showColorPickerModal(Map<String, dynamic> item) {
    final int categoryId = item['id'] ?? 0;
    final String categoryName = item['name'] ?? '';
    Color selectedColor = _hexToColor(item['color_hex']);

    // 현재 수정 중인 카테고리 외 다른 카테고리가 쓰고 있는 색상 Set
    final usedColors = _getUsedColorHexes(excludeCategoryId: categoryId);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("'$categoryName' 색상 변경", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('뱃지 색상 선택 (중복 색상 잠금)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _paletteColors.map((color) {
                    final hex = _colorToHex(color).toUpperCase();
                    final isUsed = usedColors.contains(hex);
                    final isSelected = selectedColor.value == color.value;

                    return GestureDetector(
                      onTap: isUsed
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("이미 다른 카테고리에서 사용 중인 색상입니다."),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            }
                          : () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isUsed ? color.withOpacity(0.3) : color,
                          shape: BoxShape.circle,
                          border: isSelected ? Border.all(color: Colors.black, width: 2.5) : null,
                        ),
                        child: isUsed
                            ? const Icon(Icons.lock, size: 16, color: Colors.white70)
                            : (isSelected ? const Icon(Icons.check, size: 20, color: Colors.white) : null),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (categoryId > 0) {
                    _updateColor(categoryId, selectedColor);
                  }
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        title: const Text(
          '카테고리 관리',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: _showAddCategoryDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _fetchCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brand))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _categories[index];
                final String name = item['name'] ?? '';
                final int id = item['id'] ?? 0;
                final bool isDefault = item['is_default'] == true;
                final Color catColor = _hexToColor(item['color_hex']);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      // 카테고리 뱃지 미리보기
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(
                            color: catColor,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '기본',
                            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // 색상 수정 아이콘
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                        onPressed: () => _showColorPickerModal(item),
                      ),
                      // 삭제 아이콘 (기본 카테고리가 아닐 때만 노출)
                      if (!isDefault)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFFF3B30)),
                          onPressed: () => _deleteCategory(id, name),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
