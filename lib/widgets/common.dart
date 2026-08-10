import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import 'app_icons.dart';

/// ملف المكوّنات المشتركة — يقابل الـ Components في فِقما.

// ---------------------------------------------------------------- تنسيق السعر
final _priceFormat = NumberFormat('#,##0', 'en');

String formatPrice(num value, {String symbol = 'ر.س'}) =>
    '${_priceFormat.format(value)} $symbol';

// ------------------------------------------------------- شريط علوي (Arrow/Bell)
/// سهم الرجوع يمين، الجرس يسار، العنوان في المنتصف. نفرض RTL صراحةً.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final bool showBell;
  final int unreadCount;
  final VoidCallback? onBell;
  final VoidCallback? onBack;
  final Widget? trailing;

  const AppHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.showBell = true,
    this.unreadCount = 0,
    this.onBell,
    this.onBack,
    this.trailing,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Row(
            textDirection: ui.TextDirection.rtl,
            children: [
              if (showBack)
                BackArrow(onTap: onBack)
              else
                const SizedBox(width: 24),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppText.h3SemiBold.copyWith(color: AppColors.ink),
                ),
              ),
              if (showBell)
                _BellButton(count: unreadCount, onTap: onBell)
              else
                trailing ?? const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;
  const _BellButton({required this.count, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 24,
        height: 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppIcon.bell(color: AppColors.ink),
            if (count > 0)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.alert,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------- الزر الأساسي الداكن
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool gradient;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = loading
        ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                AppIcon.bag(size: 24, color: AppColors.white),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label,
                  style: AppText.b1Medium.copyWith(color: AppColors.white)),
            ],
          );

    if (!gradient) {
      return ElevatedButton(onPressed: loading ? null : onPressed, child: content);
    }

    return GestureDetector(
      onTap: loading ? null : onPressed,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.base),
          gradient: kAccentGradient,
          boxShadow: const [kAccentShadow],
        ),
        child: Center(child: content),
      ),
    );
  }
}

// ------------------------------------------------------------ حبّة التصنيف
class CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? null : AppColors.white,
          gradient: selected ? kAccentGradient : null,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(color: selected ? Colors.transparent : AppColors.line),
        ),
        child: Text(
          label,
          style: AppText.b1Medium.copyWith(
            color: selected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------- بطاقة المنتج في الشبكة
class ProductGridCard extends StatelessWidget {
  final String name;
  final num price;
  final num? compareAt;
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const ProductGridCard({
    super.key,
    required this.name,
    required this.price,
    this.compareAt,
    this.imageUrl,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
  });

  int get _discount => (compareAt != null && compareAt! > price)
      ? (((compareAt! - price) / compareAt!) * 100).round()
      : 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 161 / 174,
          child: Stack(
            children: [
              // الصورة قابلة للضغط لفتح المنتج
              Positioned.fill(
                child: GestureDetector(
                  onTap: onTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.base),
                      image: imageUrl == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(imageUrl!), fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              // القلب فوق الصورة — منطقة لمس واسعة ومستقلة
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: onFavorite,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppRadius.heartSmall),
                        boxShadow: const [kHeartShadow],
                      ),
                      child: AppIcon.heart(
                        size: 18,
                        color: isFavorite ? AppColors.alert : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppText.b1SemiBold.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_discount > 0) ...[
                    Text('-$_discount%',
                        style:
                            AppText.b3Medium.copyWith(color: AppColors.alert)),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(formatPrice(price),
                      style: AppText.b3Medium.copyWith(color: AppColors.ink)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------ حقل البحث
class SearchField extends StatelessWidget {
  final String hint;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchField({
    super.key,
    this.hint = 'ابحث عن منتج...',
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        textAlign: TextAlign.right,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 22, color: AppColors.body),
          suffixIcon: const Icon(Icons.mic_none_rounded, size: 22, color: AppColors.body),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- الحالة الفارغة
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.body.withValues(alpha: 0.35)),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: AppText.h4SemiBold),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.b1Regular.copyWith(color: AppColors.body),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------- نافذة النجاح المنبثقة
Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'تم',
  VoidCallback? onDone,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => Dialog(
      backgroundColor: AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sheet)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 42, color: AppColors.success),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppText.h4SemiBold),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.b1Regular.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: buttonLabel,
                onPressed: () {
                  Navigator.of(context).pop();
                  onDone?.call();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ------------------------------------------------------------ صف قائمة الحساب
/// في RTL: الأيقونة يمين، ثم النص، ثم سهم "‹" على أقصى اليسار.
class AccountRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  const AccountRow({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          textDirection: ui.TextDirection.rtl,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppText.b1Medium.copyWith(color: color)),
            const Spacer(),
            if (!danger)
              const Icon(Icons.chevron_left, size: 24, color: AppColors.body),
          ],
        ),
      ),
    );
  }
}
