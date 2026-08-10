import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// رموز التصميم المستخرجة من ملف فِقما — مصدر الحقيقة الوحيد للألوان والقياسات.
class AppColors {
  /// لون الهوية — أسود (كان برتقاليًا سابقًا)
  static const accent = Color(0xFF111111);
  static const accentEnd = Color(0xFF3A3A3A);

  /// درجة باهتة تُستخدم للعناصر غير المتاحة
  static const primary200 = Color(0xFFBDBDBD);

  /// لون التنبيهات فقط (نقطة الجرس، شارة السلة) — يبقى بارزًا
  static const alert = Color(0xFFFF3B30);

  static const ink = Color(0xFF111111);
  static const body = Color(0xFF8A8A8E);
  static const line = Color(0xFFE6E6E6);
  static const surface = Color(0xFFF2F2F2);
  static const white = Color(0xFFFFFFFF);
  static const success = Color(0xFF1BA672);
  static const danger = Color(0xFFE53935);
}

/// التدرّج الأساسي — أسود ناعم بدل البرتقالي
const kAccentGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [AppColors.accent, AppColors.accentEnd],
);

const kAccentShadow = BoxShadow(
  color: Color(0x33111111),
  blurRadius: 14,
  offset: Offset(0, 6),
);

const kHeartShadow = BoxShadow(
  color: Color(0x14000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

const kHeartShadowLarge = BoxShadow(
  color: Color(0x1A000000),
  blurRadius: 12,
  offset: Offset(0, 4),
);

/// الانحناءات — موحّدة على 10 كما في التصميم
class AppRadius {
  static const base = 10.0;
  static const sheet = 20.0;
  static const heartSmall = 8.0;
  static const heartLarge = 12.0;
}

/// المسافات — الهامش الجانبي 25
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const screenPadding = EdgeInsets.symmetric(horizontal: 25);
}

/// أنماط النص — خط Cairo
class AppText {
  static TextStyle get h3SemiBold => GoogleFonts.cairo(
      fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.ink);
  static TextStyle get h4SemiBold => GoogleFonts.cairo(
      fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink);
  static TextStyle get h4Medium => GoogleFonts.cairo(
      fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.ink);

  static TextStyle get b1SemiBold => GoogleFonts.cairo(
      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink);
  static TextStyle get b1Medium => GoogleFonts.cairo(
      fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.ink);
  static TextStyle get b1Regular => GoogleFonts.cairo(
      fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink);

  static TextStyle get b2Medium => GoogleFonts.cairo(
      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static TextStyle get b2Regular => GoogleFonts.cairo(
      fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.ink);

  static TextStyle get b3Medium => GoogleFonts.cairo(
      fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink);
  static TextStyle get b3Regular => GoogleFonts.cairo(
      fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.ink);
}

/// ثيم التطبيق
ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.white,
    primaryColor: AppColors.accent,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.white,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 24,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.base),
        ),
        textStyle: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: GoogleFonts.cairo(fontSize: 16, color: AppColors.body),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.ink, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
      ),
    ),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: AppColors.accent),
  );
}
