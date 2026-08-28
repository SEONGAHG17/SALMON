import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/constants.dart';

class CategoryColorManager {
  static final CategoryColorManager _instance = CategoryColorManager._internal();
  factory CategoryColorManager() => _instance;
  CategoryColorManager._internal();

  // { '카테고리명': {'bg': Color, 'fg': Color} }
  final Map<String, Map<String, Color>> _categoryColors = {};

  // 24색 기본 확장 팔레트
  static final List<Color> extendedPalette = [
    const Color(0xFF1F7A3F), // 공모전/장학금 (초록)
    const Color(0xFFC4471C), // 맛집 (오렌지)
    const Color(0xFF2C5FCC), // 패션 (블루)
    const Color(0xFF6B3FCC), // 헤어 (퍼플)
    const Color(0xFFB87700), // 기프티콘 (옐로우/앰버)
    const Color(0xFFB83267), // 운동 (핑크)
    const Color(0xFF0D6A85), // 대외활동 (틸)
    const Color(0xFFD93B2B), // 레드
    const Color(0xFF00897B), // 민트
    const Color(0xFF5E35B1), // 인디고
    const Color(0xFF8D6E63), // 브라운
    const Color(0xFF37474F), // 다크 슬레이트
    const Color(0xFF0097A7), // 시안
    const Color(0xFF43A047), // 프레시 그린
    const Color(0xFFF4511E), // 플레임 오렌지
    const Color(0xFFE91E63), // 로즈
    const Color(0xFF3949AB), // 네이비
    const Color(0xFF7CB342), // 올리브
    const Color(0xFFFB8C00), // 웜 오렌지
    const Color(0xFF8E24AA), // 딥 퍼플
    const Color(0xFF00ACC1), // 스카이
    const Color(0xFF546E7A), // 블루 그레이
    const Color(0xFF6D4C41), // 커피
    const Color(0xFF6B6B70), // 그레이
  ];

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF6B6B70);
    }
  }

  static String toHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // 서버 동기화
  Future<void> fetchCategoriesAndColors() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/history/categories'));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        final rawCats = data['categories'];

        _categoryColors.clear();

        if (rawCats is List) {
          for (int i = 0; i < rawCats.length; i++) {
            final item = rawCats[i];
            String name = '';
            Color color;

            if (item is Map) {
              name = item['name']?.toString() ?? '';
              color = item['color'] != null ? _parseHexColor(item['color'].toString()) : _generateColorByIndex(i);
            } else {
              name = item.toString();
              color = _generateColorByIndex(i);
            }

            if (name.isNotEmpty) {
              _categoryColors[name] = {
                'bg': color.withOpacity(0.18),
                'fg': color,
              };
            }
          }
        }
      }
    } catch (e) {
      debugPrint("❌ 카테고리 색상 동기화 실패: $e");
    }
  }

  // 무제한 색상 생성 (HSL Shift)
  Color _generateColorByIndex(int index) {
    if (index < extendedPalette.length) {
      return extendedPalette[index];
    }
    final double hue = (index * 137.508) % 360;
    return HSLColor.fromAHSL(1.0, hue, 0.65, 0.45).toColor();
  }

  // 사용되지 않은 다음 추천 색상
  Color getNextAvailableColor() {
    final usedColors = _categoryColors.values.map((m) => m['fg']!.value).toSet();
    for (var c in extendedPalette) {
      if (!usedColors.contains(c.value)) {
        return c;
      }
    }
    return _generateColorByIndex(_categoryColors.length);
  }

  // 중복 검사
  bool isColorInUse(Color color, {String? excludeCategory}) {
    for (var entry in _categoryColors.entries) {
      if (excludeCategory != null && entry.key == excludeCategory) continue;
      if (entry.value['fg']!.value == color.value) return true;
    }
    return false;
  }

  // 카테고리 색상 가져오기
  Map<String, Color> getColor(String category) {
    if (_categoryColors.containsKey(category)) {
      return _categoryColors[category]!;
    }
    final index = category.hashCode.abs() % extendedPalette.length;
    final fallbackColor = extendedPalette[index];
    return {
      'bg': fallbackColor.withOpacity(0.18),
      'fg': fallbackColor,
    };
  }
}