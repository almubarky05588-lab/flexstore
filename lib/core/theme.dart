import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ★ رموز التصميم — مستخرجة حرفيًا من متغيّرات فِقما، لا بالتقدير ★
class AppColors {
  // سُلّم الرمادي الرسمي (Primary/0 … Primary/900)
  static const primary0   = Color(0xFFFFFFFF);
  static const primary100 = Color(0xFFE6E6E6); // الحدود وخلفية الصور
  static const primary200 = Color(0xFFCCCCCC); // نص باهت
  static const primary500 = Color(0xFF808080); // النص الثانوي
  static const primary900 = Color(0xFF1A1A1A); // النص والأزرار

  /// اللون البرتقالي الفعلي.
  /// تنبيه: قياس البكسل من لقطة الشاشة يعطي #FF7A2C وهي نقطة وسط
  /// التدرّج وليست اللون الأساسي. القيمة من متغيّرات فِقما:
  static const accent    = Color(0xFFFF4D2E);
  static const accentEnd = Color(0xFFFF9E2B);

  // أسماء مختصرة
  static const white   = primary0;
  static const ink     = primary900;
  static const body    = primary500;
  static const line    = primary100;
  static const surface = primary100;

  static const success = Color(0xFF23A26D);
  static const danger  = Color(0xFFE5484D);
}

/// من فِقما: linear-gradient(135deg, #FF4D2E 0%, #FF9E2B 71.429%)
const kAccentGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.accent, AppColors.accentEnd],
  stops: [0.0, 0.714],
);

/// ظل الزر البرتقالي: 0 6px 16px rgba(255,77,46,0.35)
const kAccentShadow = BoxShadow(
  color: Color(0x59FF4D2E), offset: Offset(0, 6), blurRadius: 16);

/// ظل زر القلب في البطاقة: 0 8px 10px rgba(82,82,82,0.25)
const kHeartShadow = BoxShadow(
  color: Color(0x40525252), offset: Offset(0, 8), blurRadius: 10);

/// ظل زر القلب في التفاصيل: 0 11.294px 14.118px
const kHeartShadowLarge = BoxShadow(
  color: Color(0x40525252), offset: Offset(0, 11.294), blurRadius: 14.118);

/// الانحناء موحّد على 10 في كل التصميم — لا تنويع فيه.
class AppRadius {
  static const base        = 10.0;
  static const heartSmall  = 8.0;
  static const heartLarge  = 11.294;
  static const sheet       = 20.0;
}

class AppSpacing {
  static const xs = 3.0;
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 16.0;
  static const xl = 24.0;

  /// الهامش الجانبي: العناصر تبدأ عند 25 وتنتهي عند 366.
  static const screenPadding = EdgeInsets.symmetric(horizontal: 25);
}

/// سُلّم الخطوط كما هو مُسمّى في فِقما (H3، H4، B1، B2، B3).
class AppText {
  /// الخط في التصميم: Cairo. تُنزّله حزمة google_fonts تلقائيًا
  /// أول تشغيل ثم تخزّنه، فلا حاجة لملفات خطوط داخل المستودع.
  static TextStyle _cairo(double size, FontWeight weight, double height) =>
      GoogleFonts.cairo(fontSize: size, fontWeight: weight, height: height);

  // العناوين — ارتفاع السطر 1.2
  static TextStyle get h3SemiBold => _cairo(24, FontWeight.w600, 1.2);
  static TextStyle get h4SemiBold => _cairo(20, FontWeight.w600, 1.2);
  static TextStyle get h4Medium   => _cairo(20, FontWeight.w500, 1.2);

  // النصوص — ارتفاع السطر 1.4
  static TextStyle get b1SemiBold => _cairo(16, FontWeight.w600, 1.4);
  static TextStyle get b1Medium   => _cairo(16, FontWeight.w500, 1.4);
  static TextStyle get b1Regular  => _cairo(16, FontWeight.w400, 1.4);

  static TextStyle get b2Medium   => _cairo(14, FontWeight.w500, 1.4);
  static TextStyle get b2Regular  => _cairo(14, FontWeight.w400, 1.4);

  static TextStyle get b3Medium   => _cairo(12, FontWeight.w500, 1.4);
  static TextStyle get b3Regular  => _cairo(12, FontWeight.w400, 1.4);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      primary: AppColors.accent,
      surface: AppColors.white,
    ),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.ink),
      titleTextStyle: AppText.h3SemiBold.copyWith(color: AppColors.ink),
    ),
    textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.white,
        minimumSize: const Size.fromHeight(54),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.base)),
        textStyle: AppText.b1Medium,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.35)),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.base),
        borderSide: const BorderSide(color: AppColors.danger)),
      hintStyle: AppText.b1Regular.copyWith(color: AppColors.body),
    ),
  );
}
