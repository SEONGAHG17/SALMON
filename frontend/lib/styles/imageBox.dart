import 'package:flutter/material.dart';

class ImageBoxStyle {
  // 앱 시그니처 코랄 & 에러 컬러 톤
  static const Color coralMain = Color(0xFFFF6B6B);
  static const Color coralLightBg = Color(0xFFFFF0F0);
  static const Color coralBadgeBg = Color(0xFFFFEAEA);
  static const Color coralText = Color(0xFFD32F2F);

  // 기본 정상 상태 컬러
  static const Color normalBg = Colors.white;
  static const Color normalBorder = Color(0xFFEEEEEE);
  static const Color normalText = Color(0xFF1A1A1E);

  /// 아이템이 분석 실패/ERROR 상태인지 확인
  static bool isError(Map<String, dynamic> item) {
    final String cat = item['category']?.toString().toUpperCase() ?? '';
    return cat == 'ERROR' ||
        cat == '분석 실패' ||
        item['status'] == 'fail' ||
        item['is_valid'] == false;
  }

  /// 카드 전체 외곽 데코레이션 (배경색, 코랄/회색 테두리, 그림자)
  static BoxDecoration getBoxDecoration(bool isErrorState) {
    return BoxDecoration(
      color: isErrorState ? coralLightBg : normalBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isErrorState ? coralMain : normalBorder,
        width: isErrorState ? 1.5 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: isErrorState
              ? coralMain.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// 요약 텍스트 스타일
  static TextStyle getSummaryTextStyle(bool isErrorState) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: isErrorState ? coralText : normalText,
      height: 1.3,
    );
  }

  /// ERROR 뱃지 전용 데코레이션
  static BoxDecoration getErrorBadgeDecoration() {
    return BoxDecoration(
      color: coralBadgeBg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: coralMain.withOpacity(0.5), width: 0.8),
    );
  }

  /// ERROR 뱃지 텍스트 스타일
  static const TextStyle errorBadgeTextStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: coralMain,
  );
}