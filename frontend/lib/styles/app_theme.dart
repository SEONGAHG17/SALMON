import 'package:flutter/material.dart';

/// Salmon 앱의 공통 디자인 토큰
class AppColors {
  // 1. 브랜드 메인 컬러 (코랄)
  static const Color brand = Color(0xFFFF7A6B);
  static const Color brandDark = Color(0xFFE85D4E);
  static const Color brandLight = Color(0xFFFFE9E5);
  static const Color brandAccent = Color(0xFFFF6B5B);
  static const Color brandSoft = Color(0xFFF98A7E);

  // 기존 화면 코드 호환용 별칭
  static const Color primary = Color(0xFFFF7A6B);
  static const Color primaryDark = Color(0xFFE85D4E);
  static const Color primaryLight = Color(0xFFFFE9E5);
  static const Color deepPurple = Color(0xFFFF7A6B);

  // 2. 배경 / 구분선 / 테두리
  static const Color bg = Color(0xFFFFFFFF);
  static const Color bgSoft = Color(0xFFF7F7F8);
  static const Color bgSofter = Color(0xFFFAFAFB);
  static const Color background = Color(0xFFFAFAFB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFEEEEEF);
  static const Color border = Color(0xFFE5E5E7);

  // 3. 텍스트
  static const Color textPrimary = Color(0xFF1A1A1E);
  static const Color textSecondary = Color(0xFF6B6B70);
  static const Color textTertiary = Color(0xFFA1A1A6);

  // 4. 상태
  static const Color success = Color(0xFF22A559);
  static const Color successBg = Color(0xFFDFF2E5);
  static const Color warning = Color(0xFFB87700);
  static const Color warningBg = Color(0xFFFFF0D6);
  static const Color error = Color(0xFFD93B2B);
  static const Color errorBg = Color(0xFFFFE1DE);

  // 5. 카테고리 태그 색상
  static const Color foodBg = Color(0xFFFFE5DC);
  static const Color foodFg = Color(0xFFC4471C);
  static const Color tagFoodBg = Color(0xFFFFE5DC);
  static const Color tagFoodFg = Color(0xFFC4471C);

  static const Color fashionBg = Color(0xFFDDE9FF);
  static const Color fashionFg = Color(0xFF2C5FCC);
  static const Color tagFashionBg = Color(0xFFDDE9FF);
  static const Color tagFashionFg = Color(0xFF2C5FCC);

  static const Color hairBg = Color(0xFFEBE0FF);
  static const Color hairFg = Color(0xFF6B3FCC);
  static const Color tagHairBg = Color(0xFFEBE0FF);
  static const Color tagHairFg = Color(0xFF6B3FCC);

  static const Color scholarBg = Color(0xFFDFF2E5);
  static const Color scholarFg = Color(0xFF1F7A3F);
  static const Color tagScholarBg = Color(0xFFDFF2E5);
  static const Color tagScholarFg = Color(0xFF1F7A3F);

  static const Color giftBg = Color(0xFFFFF0D6);
  static const Color giftFg = Color(0xFFB87700);
  static const Color tagGiftBg = Color(0xFFFFF0D6);
  static const Color tagGiftFg = Color(0xFFB87700);

  static const Color workoutBg = Color(0xFFFFE0EC);
  static const Color workoutFg = Color(0xFFB83267);

  static const Color clubBg = Color(0xFFE0F0F5);
  static const Color clubFg = Color(0xFF0D6A85);

  // 6. 보조 UI 색상
  static const Color locationBg = Color(0xFFEEF3E9);
  static const Color purple = Color(0xFF7A5AE0);
  static const Color mutedPurple = Color(0xFF49454F);

  // 7. 캘린더 팔레트
  static const List<Color> calendarPalette = [
    Color(0xFFFF7A6B),
    Color(0xFF2C5FCC),
    Color(0xFF1F7A3F),
    Color(0xFFB87700),
    Color(0xFF6B3FCC),
    Color(0xFFB83267),
    Color(0xFF0D6A85),
  ];
}

/// 타이포그래피 시스템
class AppTypography {
  static const String fontFamily = 'Pretendard';

  static const TextStyle display = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.7,
  );

  static const TextStyle pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.6,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle titleBold = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: -0.2,
  );

  static const TextStyle small = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    letterSpacing: -0.2,
  );

  static const TextStyle tiny = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: -0.2,
  );

  static const TextStyle dDay = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
}

/// 간격 시스템
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// 모서리 곡률 시스템
class AppRadius {
  static const double xs = 8;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 16;
  static const double xxl = 20;
  static const double pill = 999;
}

/// 그림자 시스템
class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];
}

/// 데코레이션 및 버튼
class AppDecorations {
  static final BoxDecoration card = BoxDecoration(
    color: AppColors.bg,
    borderRadius: BorderRadius.circular(AppRadius.xl),
  );

  static final BoxDecoration cardBox = BoxDecoration(
    color: AppColors.cardBg,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(color: AppColors.border),
    boxShadow: AppShadows.card,
  );

  static final BoxDecoration outlinedCard = BoxDecoration(
    color: AppColors.bg,
    borderRadius: BorderRadius.circular(AppRadius.xl),
    border: Border.all(color: AppColors.border),
  );

  static final BoxDecoration softCard = BoxDecoration(
    color: AppColors.bgSoft,
    borderRadius: BorderRadius.circular(AppRadius.lg),
  );

  static final BoxDecoration brandCard = BoxDecoration(
    color: AppColors.brand,
    borderRadius: BorderRadius.circular(AppRadius.lg),
  );

  static final BoxDecoration brandLightCard = BoxDecoration(
    color: AppColors.brandLight,
    borderRadius: BorderRadius.circular(AppRadius.xl),
  );

  static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.brand,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
  );

  static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.bgSoft,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
  );
}

/// 카테고리 스타일
class AppCategoryStyle {
  final Color background;
  final Color foreground;
  final String name;
  final String icon;

  const AppCategoryStyle({
    required this.background,
    required this.foreground,
    required this.name,
    required this.icon,
  });

  static const food = AppCategoryStyle(
    background: AppColors.foodBg,
    foreground: AppColors.foodFg,
    name: '맛집',
    icon: '🍜',
  );

  static const fashion = AppCategoryStyle(
    background: AppColors.fashionBg,
    foreground: AppColors.fashionFg,
    name: '패션',
    icon: '👗',
  );

  static const hair = AppCategoryStyle(
    background: AppColors.hairBg,
    foreground: AppColors.hairFg,
    name: '헤어',
    icon: '✂️',
  );

  static const scholar = AppCategoryStyle(
    background: AppColors.scholarBg,
    foreground: AppColors.scholarFg,
    name: '장학금',
    icon: '🎓',
  );

  static const gift = AppCategoryStyle(
    background: AppColors.giftBg,
    foreground: AppColors.giftFg,
    name: '기프트콘',
    icon: '🎁',
  );

  static const workout = AppCategoryStyle(
    background: AppColors.workoutBg,
    foreground: AppColors.workoutFg,
    name: '운동',
    icon: '🧘',
  );

  static const club = AppCategoryStyle(
    background: AppColors.clubBg,
    foreground: AppColors.clubFg,
    name: '대외활동',
    icon: '🎯',
  );
}

/// D-Day 스타일
class AppDDayStyle {
  final Color background;
  final Color foreground;

  const AppDDayStyle({
    required this.background,
    required this.foreground,
  });

  static const urgent = AppDDayStyle(
    background: AppColors.errorBg,
    foreground: AppColors.error,
  );

  static const soon = AppDDayStyle(
    background: AppColors.warningBg,
    foreground: AppColors.warning,
  );

  static const safe = AppDDayStyle(
    background: AppColors.successBg,
    foreground: AppColors.success,
  );
}

/// 앱 전역 테마
class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTypography.fontFamily,
      scaffoldBackgroundColor: AppColors.bgSofter,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brand,
        brightness: Brightness.light,
        primary: AppColors.brand,
        onPrimary: Colors.white,
        surface: AppColors.bg,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      textTheme: const TextTheme(
        displayLarge: AppTypography.display,
        headlineLarge: AppTypography.pageTitle,
        headlineMedium: AppTypography.title,
        titleLarge: AppTypography.sectionTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.caption,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppDecorations.primaryButton,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: CircleBorder(),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bg,
        selectedItemColor: AppColors.brand,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: TextStyle(fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgSofter,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
        ),
        hintStyle: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSoft,
        selectedColor: AppColors.brand,
        labelStyle: AppTypography.caption,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// /// Salmon 앱의 공통 디자인 토큰 및 기존 코드 호환 테마
// class AppColors {
//   // 1. 브랜드 메인 컬러
//   static const Color brand = Color(0xFFFF7A6B);
//   static const Color brandDark = Color(0xFFE85D4E);
//   static const Color brandLight = Color(0xFFFFE9E5);
//   static const Color brandAccent = Color(0xFFFF6B5B);
//   static const Color brandSoft = Color(0xFFF98A7E);

//   // 기존 화면 코드 호환용 별칭
//   static const Color primary = Color(0xFFFF7A6B);
//   static const Color primaryDark = Color(0xFFE85D4E);
//   static const Color primaryLight = Color(0xFFFFE9E5);
//   static const Color deepPurple = Color(0xFFFF7A6B);

//   // 2. 배경 / 구분선 / 테두리
//   static const Color bg = Color(0xFFFFFFFF);
//   static const Color bgSoft = Color(0xFFF7F7F8);
//   static const Color bgSofter = Color(0xFFFAFAFB);
//   static const Color background = Color(0xFFFAFAFB);
//   static const Color cardBg = Color(0xFFFFFFFF);
//   static const Color divider = Color(0xFFEEEEEF);
//   static const Color border = Color(0xFFE5E5E7);

//   // 3. 텍스트
//   static const Color textPrimary = Color(0xFF1A1A1E);
//   static const Color textSecondary = Color(0xFF6B6B70);
//   static const Color textTertiary = Color(0xFFA1A1A6);

//   // 4. 상태
//   static const Color success = Color(0xFF22A559);
//   static const Color successBg = Color(0xFFDFF2E5);
//   static const Color warning = Color(0xFFB87700);
//   static const Color warningBg = Color(0xFFFFF0D6);
//   static const Color error = Color(0xFFD93B2B);
//   static const Color errorBg = Color(0xFFFFE1DE);

//   // 5. 카테고리 태그 색상
//   static const Color foodBg = Color(0xFFFFE5DC);
//   static const Color foodFg = Color(0xFFC4471C);
//   static const Color tagFoodBg = Color(0xFFFFE5DC);
//   static const Color tagFoodFg = Color(0xFFC4471C);

//   static const Color fashionBg = Color(0xFFDDE9FF);
//   static const Color fashionFg = Color(0xFF2C5FCC);
//   static const Color tagFashionBg = Color(0xFFDDE9FF);
//   static const Color tagFashionFg = Color(0xFF2C5FCC);

//   static const Color hairBg = Color(0xFFEBE0FF);
//   static const Color hairFg = Color(0xFF6B3FCC);
//   static const Color tagHairBg = Color(0xFFEBE0FF);
//   static const Color tagHairFg = Color(0xFF6B3FCC);

//   static const Color scholarBg = Color(0xFFDFF2E5);
//   static const Color scholarFg = Color(0xFF1F7A3F);
//   static const Color tagScholarBg = Color(0xFFDFF2E5);
//   static const Color tagScholarFg = Color(0xFF1F7A3F);

//   static const Color giftBg = Color(0xFFFFF0D6);
//   static const Color giftFg = Color(0xFFB87700);
//   static const Color tagGiftBg = Color(0xFFFFF0D6);
//   static const Color tagGiftFg = Color(0xFFB87700);

//   static const Color workoutBg = Color(0xFFFFE0EC);
//   static const Color workoutFg = Color(0xFFB83267);

//   static const Color clubBg = Color(0xFFE0F0F5);
//   static const Color clubFg = Color(0xFF0D6A85);

//   // 6. 보조 UI 색상
//   static const Color locationBg = Color(0xFFEEF3E9);
//   static const Color purple = Color(0xFF7A5AE0);
//   static const Color mutedPurple = Color(0xFF49454F);

//   // 7. 캘린더 팔레트
//   static const List<Color> calendarPalette = [
//     Color(0xFFFF7A6B),
//     Color(0xFF2C5FCC),
//     Color(0xFF1F7A3F),
//     Color(0xFFB87700),
//     Color(0xFF6B3FCC),
//     Color(0xFFB83267),
//     Color(0xFF0D6A85),
//   ];
// }

// /// 타이포그래피 시스템
// class AppTypography {
//   static const String fontFamily = 'Pretendard';

//   static const TextStyle display = TextStyle(
//     fontSize: 26,
//     fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.7,
//   );

//   static const TextStyle pageTitle = TextStyle(
//     fontSize: 24,
//     fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.6,
//   );

//   static const TextStyle title = TextStyle(
//     fontSize: 22,
//     fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.5,
//   );

//   static const TextStyle sectionTitle = TextStyle(
//     fontSize: 18,
//     fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.3,
//   );

//   static const TextStyle titleBold = TextStyle(
//     fontSize: 18,
//     fontWeight: FontWeight.w700,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.3,
//   );

//   static const TextStyle bodyLarge = TextStyle(
//     fontSize: 14,
//     fontWeight: FontWeight.w400,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.2,
//   );

//   static const TextStyle bodyMedium = TextStyle(
//     fontSize: 13.5,
//     fontWeight: FontWeight.w600,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.3,
//   );

//   static const TextStyle body = TextStyle(
//     fontSize: 13,
//     fontWeight: FontWeight.w400,
//     color: AppColors.textPrimary,
//     letterSpacing: -0.2,
//   );

//   static const TextStyle caption = TextStyle(
//     fontSize: 12,
//     fontWeight: FontWeight.w400,
//     color: AppColors.textSecondary,
//     letterSpacing: -0.2,
//   );

//   static const TextStyle small = TextStyle(
//     fontSize: 11.5,
//     fontWeight: FontWeight.w400,
//     color: AppColors.textSecondary,
//     letterSpacing: -0.2,
//   );

//   static const TextStyle tiny = TextStyle(
//     fontSize: 10,
//     fontWeight: FontWeight.w600,
//     color: AppColors.textSecondary,
//     letterSpacing: -0.2,
//   );

//   static const TextStyle dDay = TextStyle(
//     fontSize: 18,
//     fontWeight: FontWeight.w700,
//     letterSpacing: -0.5,
//   );
// }

// /// 간격 시스템
// class AppSpacing {
//   static const double xs = 4;
//   static const double sm = 8;
//   static const double md = 12;
//   static const double lg = 16;
//   static const double xl = 20;
//   static const double xxl = 24;
//   static const double xxxl = 32;
// }

// /// 모서리 곡률 시스템
// class AppRadius {
//   static const double xs = 8;
//   static const double sm = 10;
//   static const double md = 12;
//   static const double lg = 14;
//   static const double xl = 16;
//   static const double xxl = 20;
//   static const double pill = 999;
// }

// /// 그림자 시스템
// class AppShadows {
//   static const List<BoxShadow> card = [
//     BoxShadow(
//       color: Color(0x12000000),
//       blurRadius: 10,
//       offset: Offset(0, 2),
//     ),
//   ];
// }

// /// 데코레이션 및 버튼
// class AppDecorations {
//   static final BoxDecoration card = BoxDecoration(
//     color: AppColors.bg,
//     borderRadius: BorderRadius.circular(AppRadius.xl),
//   );

//   static final BoxDecoration cardBox = BoxDecoration(
//     color: AppColors.cardBg,
//     borderRadius: BorderRadius.circular(AppRadius.xl),
//     border: Border.all(color: AppColors.border),
//     boxShadow: AppShadows.card,
//   );

//   static final BoxDecoration outlinedCard = BoxDecoration(
//     color: AppColors.bg,
//     borderRadius: BorderRadius.circular(AppRadius.xl),
//     border: Border.all(color: AppColors.border),
//   );

//   static final BoxDecoration softCard = BoxDecoration(
//     color: AppColors.bgSoft,
//     borderRadius: BorderRadius.circular(AppRadius.lg),
//   );

//   static final BoxDecoration brandCard = BoxDecoration(
//     color: AppColors.brand,
//     borderRadius: BorderRadius.circular(AppRadius.lg),
//   );

//   static final BoxDecoration brandLightCard = BoxDecoration(
//     color: AppColors.brandLight,
//     borderRadius: BorderRadius.circular(AppRadius.xl),
//   );

//   static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
//     backgroundColor: AppColors.brand,
//     foregroundColor: Colors.white,
//     elevation: 0,
//     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(AppRadius.lg),
//     ),
//     textStyle: const TextStyle(
//       fontSize: 14,
//       fontWeight: FontWeight.w600,
//       letterSpacing: -0.2,
//     ),
//   );

//   static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
//     backgroundColor: AppColors.bgSoft,
//     foregroundColor: AppColors.textPrimary,
//     elevation: 0,
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//     shape: RoundedRectangleBorder(
//       borderRadius: BorderRadius.circular(AppRadius.md),
//     ),
//   );
// }

// /// 카테고리 스타일
// class AppCategoryStyle {
//   final Color background;
//   final Color foreground;
//   final String name;
//   final String icon;

//   const AppCategoryStyle({
//     required this.background,
//     required this.foreground,
//     required this.name,
//     required this.icon,
//   });

//   static const food = AppCategoryStyle(
//     background: AppColors.foodBg,
//     foreground: AppColors.foodFg,
//     name: '맛집',
//     icon: '🍜',
//   );

//   static const fashion = AppCategoryStyle(
//     background: AppColors.fashionBg,
//     foreground: AppColors.fashionFg,
//     name: '패션',
//     icon: '👗',
//   );

//   static const hair = AppCategoryStyle(
//     background: AppColors.hairBg,
//     foreground: AppColors.hairFg,
//     name: '헤어',
//     icon: '✂️',
//   );

//   static const scholar = AppCategoryStyle(
//     background: AppColors.scholarBg,
//     foreground: AppColors.scholarFg,
//     name: '장학금',
//     icon: '🎓',
//   );

//   static const gift = AppCategoryStyle(
//     background: AppColors.giftBg,
//     foreground: AppColors.giftFg,
//     name: '기프트콘',
//     icon: '🎁',
//   );

//   static const workout = AppCategoryStyle(
//     background: AppColors.workoutBg,
//     foreground: AppColors.workoutFg,
//     name: '운동',
//     icon: '🧘',
//   );

//   static const club = AppCategoryStyle(
//     background: AppColors.clubBg,
//     foreground: AppColors.clubFg,
//     name: '대외활동',
//     icon: '🎯',
//   );
// }

// /// D-Day 스타일
// class AppDDayStyle {
//   final Color background;
//   final Color foreground;

//   const AppDDayStyle({
//     required this.background,
//     required this.foreground,
//   });

//   static const urgent = AppDDayStyle(
//     background: AppColors.errorBg,
//     foreground: AppColors.error,
//   );

//   static const soon = AppDDayStyle(
//     background: AppColors.warningBg,
//     foreground: AppColors.warning,
//   );

//   static const safe = AppDDayStyle(
//     background: AppColors.successBg,
//     foreground: AppColors.success,
//   );
// }

// /// 앱 전역 테마
// class AppTheme {
//   static ThemeData get light {
//     return ThemeData(
//       useMaterial3: true,
//       fontFamily: AppTypography.fontFamily,
//       scaffoldBackgroundColor: AppColors.bgSofter,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.brand,
//         brightness: Brightness.light,
//         primary: AppColors.brand,
//         onPrimary: Colors.white,
//         surface: AppColors.bg,
//         onSurface: AppColors.textPrimary,
//         error: AppColors.error,
//       ),
//       textTheme: const TextTheme(
//         displayLarge: AppTypography.display,
//         headlineLarge: AppTypography.pageTitle,
//         headlineMedium: AppTypography.title,
//         titleLarge: AppTypography.sectionTitle,
//         bodyLarge: AppTypography.bodyLarge,
//         bodyMedium: AppTypography.body,
//         bodySmall: AppTypography.caption,
//       ),
//       dividerTheme: const DividerThemeData(
//         color: AppColors.divider,
//         thickness: 1,
//         space: 1,
//       ),
//       appBarTheme: const AppBarTheme(
//         backgroundColor: AppColors.bg,
//         foregroundColor: AppColors.textPrimary,
//         elevation: 0,
//         centerTitle: false,
//         scrolledUnderElevation: 0,
//         titleTextStyle: TextStyle(
//           fontFamily: AppTypography.fontFamily,
//           fontSize: 20,
//           fontWeight: FontWeight.w700,
//           color: AppColors.textPrimary,
//           letterSpacing: -0.5,
//         ),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: AppDecorations.primaryButton,
//       ),
//       floatingActionButtonTheme: const FloatingActionButtonThemeData(
//         backgroundColor: AppColors.brand,
//         foregroundColor: Colors.white,
//         elevation: 3,
//         shape: CircleBorder(),
//       ),
//       bottomNavigationBarTheme: const BottomNavigationBarThemeData(
//         backgroundColor: Colors.white,
//         selectedItemColor: AppColors.brand,
//         unselectedItemColor: AppColors.textTertiary,
//         selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
//         unselectedLabelStyle: TextStyle(fontSize: 11),
//         type: BottomNavigationBarType.fixed,
//         elevation: 8,
//       ),
//       cardTheme: CardThemeData(
//         color: AppColors.bg,
//         elevation: 0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           side: const BorderSide(color: AppColors.border),
//         ),
//         margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
//       ),
//       inputDecorationTheme: InputDecorationTheme(
//         filled: true,
//         fillColor: AppColors.bgSoft,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           borderSide: BorderSide.none,
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           borderSide: BorderSide.none,
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(AppRadius.lg),
//           borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
//         ),
//         hintStyle: AppTypography.caption.copyWith(color: AppColors.textTertiary),
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: AppSpacing.lg,
//           vertical: AppSpacing.md,
//         ),
//       ),
//       chipTheme: ChipThemeData(
//         backgroundColor: AppColors.bgSoft,
//         selectedColor: AppColors.brand,
//         labelStyle: AppTypography.caption,
//         side: BorderSide.none,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(AppRadius.pill),
//         ),
//         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';

// // /// 기존 코드 및 팀원의 디자인 토큰을 100% 호환하도록 맞춘 스타일 정의
// // class AppColors {
// //   // 1. 브랜드 메인 컬러 (기존 코드의 primary / brand 호환)
// //   static const Color brand = Color(0xFFFF7A6B);[cite: 3]
// //   static const Color primary = Color(0xFFFF7A6B); // 기존에 primary로 쓰던 곳 대응
// //   static const Color primaryDark = Color(0xFFE85D4E);[cite: 3]
// //   static const Color primaryLight = Color(0xFFFFE9E5);[cite: 3]
// //   static const Color brandDark = Color(0xFFE85D4E);[cite: 3]
// //   static const Color brandLight = Color(0xFFFFE9E5);[cite: 3]

// //   // 2. 배경 및 테두리 (기존 background / bg / border 호환)
// //   static const Color bg = Color(0xFFFAFAFB);[cite: 3]
// //   static const Color background = Color(0xFFFAFAFB); // 기존 background 대응
// //   static const Color bgSoft = Color(0xFFF7F7F8);[cite: 3]
// //   static const Color cardBg = Colors.white;
// //   static const Color border = Color(0xFFE5E5E7);[cite: 3]
// //   static const Color divider = Color(0xFFEEEEEF);[cite: 3]

// //   // 3. 텍스트
// //   static const Color textPrimary = Color(0xFF1A1A1E);[cite: 3]
// //   static const Color textSecondary = Color(0xFF6B6B70);[cite: 3]
// //   static const Color textTertiary = Color(0xFFA1A1A6);[cite: 3]

// //   // 4. 상태
// //   static const Color success = Color(0xFF22A559);[cite: 3]
// //   static const Color warning = Color(0xFFB87700);[cite: 3]
// //   static const Color error = Color(0xFFD93B2B);[cite: 3]

// //   // 5. 카테고리 태그 색상 (기존 코드 명칭 및 팀원 토큰 호환)
// //   static const Color tagFoodBg = Color(0xFFFFE5DC);[cite: 3]
// //   static const Color tagFoodFg = Color(0xFFC4471C);[cite: 3]
// //   static const Color foodBg = Color(0xFFFFE5DC);[cite: 3]
// //   static const Color foodFg = Color(0xFFC4471C);[cite: 3]

// //   static const Color tagFashionBg = Color(0xFFDDE9FF);[cite: 3]
// //   static const Color tagFashionFg = Color(0xFF2C5FCC);[cite: 3]
// //   static const Color fashionBg = Color(0xFFDDE9FF);[cite: 3]
// //   static const Color fashionFg = Color(0xFF2C5FCC);[cite: 3]

// //   static const Color tagHairBg = Color(0xFFEBE0FF);[cite: 3]
// //   static const Color tagHairFg = Color(0xFF6B3FCC);[cite: 3]
// //   static const Color hairBg = Color(0xFFEBE0FF);[cite: 3]
// //   static const Color hairFg = Color(0xFF6B3FCC);[cite: 3]

// //   static const Color tagScholarBg = Color(0xFFDFF2E5);[cite: 3]
// //   static const Color tagScholarFg = Color(0xFF1F7A3F);[cite: 3]
// //   static const Color scholarBg = Color(0xFFDFF2E5);[cite: 3]
// //   static const Color scholarFg = Color(0xFF1F7A3F);[cite: 3]

// //   static const Color tagGiftBg = Color(0xFFFFF0D6);[cite: 3]
// //   static const Color tagGiftFg = Color(0xFFB87700);[cite: 3]
// //   static const Color giftBg = Color(0xFFFFF0D6);[cite: 3]
// //   static const Color giftFg = Color(0xFFB87700);[cite: 3]
// // }

// // class AppTypography {
// //   static const TextStyle titleBold = TextStyle(
// //     fontSize: 18,
// //     fontWeight: FontWeight.bold,
// //     color: AppColors.textPrimary,[cite: 3]
// //   );
// //   static const TextStyle body = TextStyle(
// //     fontSize: 14,
// //     color: AppColors.textPrimary,[cite: 3]
// //   );
// //   static const TextStyle caption = TextStyle(
// //     fontSize: 12,
// //     color: AppColors.textSecondary,[cite: 3]
// //   );
// // }

// // class AppDecorations {
// //   static final BoxDecoration cardBox = BoxDecoration(
// //     color: AppColors.cardBg,
// //     borderRadius: BorderRadius.circular(14),
// //     border: Border.all(color: AppColors.border),[cite: 3]
// //   );

// //   static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
// //     backgroundColor: AppColors.brand,[cite: 3]
// //     foregroundColor: Colors.white,
// //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// //     elevation: 0,
// //   );
// // }

// // // import 'package:flutter/material.dart';

// // // /// Salmon 앱의 공통 디자인 토큰
// // // ///
// // // /// 웹 UI의 design-tokens.js를 Flutter에서 바로 사용할 수 있도록
// // // /// 색상 / 타이포그래피 / 간격 / 모서리 / 공통 컴포넌트 스타일로 정리했습니다.
// // // class AppColors {
// // //   // 브랜드
// // //   static const Color brand = Color(0xFFFF7A6B);
// // //   static const Color brandDark = Color(0xFFE85D4E);
// // //   static const Color brandLight = Color(0xFFFFE9E5);
// // //   static const Color brandAccent = Color(0xFFFF6B5B);
// // //   static const Color brandSoft = Color(0xFFF98A7E);

// // //   // 배경 / 구분선 / 테두리
// // //   static const Color bg = Color(0xFFFFFFFF);
// // //   static const Color bgSoft = Color(0xFFF7F7F8);
// // //   static const Color bgSofter = Color(0xFFFAFAFB);
// // //   static const Color divider = Color(0xFFEEEEEF);
// // //   static const Color border = Color(0xFFE5E5E7);

// // //   // 텍스트
// // //   static const Color textPrimary = Color(0xFF1A1A1E);
// // //   static const Color textSecondary = Color(0xFF6B6B70);
// // //   static const Color textTertiary = Color(0xFFA1A1A6);

// // //   // 상태
// // //   static const Color success = Color(0xFF22A559);
// // //   static const Color successBg = Color(0xFFDFF2E5);
// // //   static const Color warning = Color(0xFFB87700);
// // //   static const Color warningBg = Color(0xFFFFF0D6);
// // //   static const Color error = Color(0xFFD93B2B);
// // //   static const Color errorBg = Color(0xFFFFE1DE);

// // //   // 카테고리 - 맛집
// // //   static const Color foodBg = Color(0xFFFFE5DC);
// // //   static const Color foodFg = Color(0xFFC4471C);

// // //   // 카테고리 - 패션
// // //   static const Color fashionBg = Color(0xFFDDE9FF);
// // //   static const Color fashionFg = Color(0xFF2C5FCC);

// // //   // 카테고리 - 헤어
// // //   static const Color hairBg = Color(0xFFEBE0FF);
// // //   static const Color hairFg = Color(0xFF6B3FCC);

// // //   // 카테고리 - 장학금
// // //   static const Color scholarBg = Color(0xFFDFF2E5);
// // //   static const Color scholarFg = Color(0xFF1F7A3F);

// // //   // 카테고리 - 기프트콘
// // //   static const Color giftBg = Color(0xFFFFF0D6);
// // //   static const Color giftFg = Color(0xFFB87700);

// // //   // 카테고리 - 운동
// // //   static const Color workoutBg = Color(0xFFFFE0EC);
// // //   static const Color workoutFg = Color(0xFFB83267);

// // //   // 카테고리 - 대외활동
// // //   static const Color clubBg = Color(0xFFE0F0F5);
// // //   static const Color clubFg = Color(0xFF0D6A85);

// // //   // 기타 UI에서 사용되는 보조 색상
// // //   static const Color locationBg = Color(0xFFEEF3E9);
// // //   static const Color purple = Color(0xFF7A5AE0);
// // //   static const Color mutedPurple = Color(0xFF49454F);
// // // }

// // // class AppTypography {
// // //   static const String fontFamily = 'Pretendard';

// // //   static const TextStyle display = TextStyle(
// // //     fontSize: 26,
// // //     fontWeight: FontWeight.w700,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.7,
// // //   );

// // //   static const TextStyle pageTitle = TextStyle(
// // //     fontSize: 24,
// // //     fontWeight: FontWeight.w700,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.6,
// // //   );

// // //   static const TextStyle title = TextStyle(
// // //     fontSize: 22,
// // //     fontWeight: FontWeight.w700,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.5,
// // //   );

// // //   static const TextStyle sectionTitle = TextStyle(
// // //     fontSize: 18,
// // //     fontWeight: FontWeight.w700,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.3,
// // //   );

// // //   static const TextStyle bodyLarge = TextStyle(
// // //     fontSize: 14,
// // //     fontWeight: FontWeight.w400,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.2,
// // //   );

// // //   static const TextStyle bodyMedium = TextStyle(
// // //     fontSize: 13.5,
// // //     fontWeight: FontWeight.w600,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.3,
// // //   );

// // //   static const TextStyle body = TextStyle(
// // //     fontSize: 13,
// // //     fontWeight: FontWeight.w400,
// // //     color: AppColors.textPrimary,
// // //     letterSpacing: -0.2,
// // //   );

// // //   static const TextStyle caption = TextStyle(
// // //     fontSize: 12,
// // //     fontWeight: FontWeight.w400,
// // //     color: AppColors.textSecondary,
// // //     letterSpacing: -0.2,
// // //   );

// // //   static const TextStyle small = TextStyle(
// // //     fontSize: 11.5,
// // //     fontWeight: FontWeight.w400,
// // //     color: AppColors.textSecondary,
// // //     letterSpacing: -0.2,
// // //   );

// // //   static const TextStyle tiny = TextStyle(
// // //     fontSize: 10,
// // //     fontWeight: FontWeight.w600,
// // //     color: AppColors.textSecondary,
// // //     letterSpacing: -0.2,
// // //   );

// // //   static const TextStyle dDay = TextStyle(
// // //     fontSize: 18,
// // //     fontWeight: FontWeight.w700,
// // //     letterSpacing: -0.5,
// // //   );
// // // }

// // // class AppSpacing {
// // //   static const double xs = 4;
// // //   static const double sm = 8;
// // //   static const double md = 12;
// // //   static const double lg = 16;
// // //   static const double xl = 20;
// // //   static const double xxl = 24;
// // //   static const double xxxl = 32;
// // // }

// // // class AppRadius {
// // //   static const double xs = 8;
// // //   static const double sm = 10;
// // //   static const double md = 12;
// // //   static const double lg = 14;
// // //   static const double xl = 16;
// // //   static const double xxl = 20;
// // //   static const double pill = 999;
// // // }

// // // class AppShadows {
// // //   static const List<BoxShadow> card = [
// // //     BoxShadow(
// // //       color: Color(0x12000000),
// // //       blurRadius: 10,
// // //       offset: Offset(0, 2),
// // //     ),
// // //   ];
// // // }

// // // class AppDecorations {
// // //   static final BoxDecoration card = BoxDecoration(
// // //     color: AppColors.bg,
// // //     borderRadius: BorderRadius.circular(AppRadius.xl),
// // //   );

// // //   static final BoxDecoration outlinedCard = BoxDecoration(
// // //     color: AppColors.bg,
// // //     borderRadius: BorderRadius.circular(AppRadius.xl),
// // //     border: Border.all(color: AppColors.border),
// // //   );

// // //   static final BoxDecoration softCard = BoxDecoration(
// // //     color: AppColors.bgSoft,
// // //     borderRadius: BorderRadius.circular(AppRadius.lg),
// // //   );

// // //   static final BoxDecoration brandCard = BoxDecoration(
// // //     color: AppColors.brand,
// // //     borderRadius: BorderRadius.circular(AppRadius.lg),
// // //   );

// // //   static final BoxDecoration brandLightCard = BoxDecoration(
// // //     color: AppColors.brandLight,
// // //     borderRadius: BorderRadius.circular(AppRadius.xl),
// // //   );

// // //   static final ButtonStyle primaryButton = ElevatedButton.styleFrom(
// // //     backgroundColor: AppColors.brand,
// // //     foregroundColor: Colors.white,
// // //     elevation: 0,
// // //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
// // //     shape: RoundedRectangleBorder(
// // //       borderRadius: BorderRadius.circular(AppRadius.lg),
// // //     ),
// // //     textStyle: const TextStyle(
// // //       fontSize: 14,
// // //       fontWeight: FontWeight.w600,
// // //       letterSpacing: -0.2,
// // //     ),
// // //   );

// // //   static final ButtonStyle secondaryButton = ElevatedButton.styleFrom(
// // //     backgroundColor: AppColors.bgSoft,
// // //     foregroundColor: AppColors.textPrimary,
// // //     elevation: 0,
// // //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
// // //     shape: RoundedRectangleBorder(
// // //       borderRadius: BorderRadius.circular(AppRadius.md),
// // //     ),
// // //   );
// // // }

// // // /// 앱 카테고리 공통 색상 정보
// // // class AppCategoryStyle {
// // //   final Color background;
// // //   final Color foreground;
// // //   final String name;
// // //   final String icon;

// // //   const AppCategoryStyle({
// // //     required this.background,
// // //     required this.foreground,
// // //     required this.name,
// // //     required this.icon,
// // //   });

// // //   static const food = AppCategoryStyle(
// // //     background: AppColors.foodBg,
// // //     foreground: AppColors.foodFg,
// // //     name: '맛집',
// // //     icon: '🍜',
// // //   );

// // //   static const fashion = AppCategoryStyle(
// // //     background: AppColors.fashionBg,
// // //     foreground: AppColors.fashionFg,
// // //     name: '패션',
// // //     icon: '👗',
// // //   );

// // //   static const hair = AppCategoryStyle(
// // //     background: AppColors.hairBg,
// // //     foreground: AppColors.hairFg,
// // //     name: '헤어',
// // //     icon: '✂️',
// // //   );

// // //   static const scholar = AppCategoryStyle(
// // //     background: AppColors.scholarBg,
// // //     foreground: AppColors.scholarFg,
// // //     name: '장학금',
// // //     icon: '🎓',
// // //   );

// // //   static const gift = AppCategoryStyle(
// // //     background: AppColors.giftBg,
// // //     foreground: AppColors.giftFg,
// // //     name: '기프트콘',
// // //     icon: '🎁',
// // //   );

// // //   static const workout = AppCategoryStyle(
// // //     background: AppColors.workoutBg,
// // //     foreground: AppColors.workoutFg,
// // //     name: '운동',
// // //     icon: '🧘',
// // //   );

// // //   static const club = AppCategoryStyle(
// // //     background: AppColors.clubBg,
// // //     foreground: AppColors.clubFg,
// // //     name: '대외활동',
// // //     icon: '🎯',
// // //   );
// // // }

// // // /// D-Day 상태별 스타일
// // // class AppDDayStyle {
// // //   final Color background;
// // //   final Color foreground;

// // //   const AppDDayStyle({
// // //     required this.background,
// // //     required this.foreground,
// // //   });

// // //   static const urgent = AppDDayStyle(
// // //     background: AppColors.errorBg,
// // //     foreground: AppColors.error,
// // //   );

// // //   static const soon = AppDDayStyle(
// // //     background: AppColors.warningBg,
// // //     foreground: AppColors.warning,
// // //   );

// // //   static const safe = AppDDayStyle(
// // //     background: AppColors.successBg,
// // //     foreground: AppColors.success,
// // //   );
// // // }

// // // /// 전체 앱 테마
// // // class AppTheme {
// // //   static ThemeData get light {
// // //     return ThemeData(
// // //       useMaterial3: true,
// // //       fontFamily: AppTypography.fontFamily,
// // //       scaffoldBackgroundColor: AppColors.bg,
// // //       colorScheme: ColorScheme.fromSeed(
// // //         seedColor: AppColors.brand,
// // //         brightness: Brightness.light,
// // //         primary: AppColors.brand,
// // //         onPrimary: Colors.white,
// // //         surface: AppColors.bg,
// // //         onSurface: AppColors.textPrimary,
// // //         error: AppColors.error,
// // //       ),
// // //       textTheme: const TextTheme(
// // //         displayLarge: AppTypography.display,
// // //         headlineLarge: AppTypography.pageTitle,
// // //         headlineMedium: AppTypography.title,
// // //         titleLarge: AppTypography.sectionTitle,
// // //         bodyLarge: AppTypography.bodyLarge,
// // //         bodyMedium: AppTypography.body,
// // //         bodySmall: AppTypography.caption,
// // //       ),
// // //       dividerTheme: const DividerThemeData(
// // //         color: AppColors.divider,
// // //         thickness: 1,
// // //         space: 1,
// // //       ),
// // //       appBarTheme: const AppBarTheme(
// // //         backgroundColor: AppColors.bg,
// // //         foregroundColor: AppColors.textPrimary,
// // //         elevation: 0,
// // //         centerTitle: false,
// // //         scrolledUnderElevation: 0,
// // //       ),
// // //       elevatedButtonTheme: ElevatedButtonThemeData(
// // //         style: AppDecorations.primaryButton,
// // //       ),
// // //       inputDecorationTheme: InputDecorationTheme(
// // //         filled: true,
// // //         fillColor: AppColors.bgSoft,
// // //         border: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.lg),
// // //           borderSide: BorderSide.none,
// // //         ),
// // //         enabledBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.lg),
// // //           borderSide: BorderSide.none,
// // //         ),
// // //         focusedBorder: OutlineInputBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.lg),
// // //           borderSide: const BorderSide(color: AppColors.brand),
// // //         ),
// // //         hintStyle: AppTypography.caption,
// // //         contentPadding: const EdgeInsets.symmetric(
// // //           horizontal: AppSpacing.lg,
// // //           vertical: AppSpacing.md,
// // //         ),
// // //       ),
// // //       chipTheme: ChipThemeData(
// // //         backgroundColor: AppColors.bgSoft,
// // //         selectedColor: AppColors.brand,
// // //         labelStyle: AppTypography.caption,
// // //         side: BorderSide.none,
// // //         shape: RoundedRectangleBorder(
// // //           borderRadius: BorderRadius.circular(AppRadius.pill),
// // //         ),
// // //         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
// // //       ),
// // //     );
// // //   }
// // // }
