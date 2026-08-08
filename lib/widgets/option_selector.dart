import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/product.dart';

/// ★ القطعة المحورية في الواجهة ★
///
/// تعرض خيارات المنتج أيًّا كانت: مقاسات ملابس، أحجام عطور، ألوان...
/// لا تحتوي على أي منطق خاص بنوع متجر معيّن — تقرأ `display_as` من
/// الخادم وترسم الشكل المناسب. إضافة نوع خيار جديد من لوحة التحكم
/// تظهر هنا فورًا بلا تعديل كود.
class OptionSelector extends StatelessWidget {
  final Product product;
  final Map<String, String> selected; // optionTypeId -> optionValueId
  final ValueChanged<Map<String, String>> onChanged;

  const OptionSelector({
    super.key,
    required this.product,
    required this.selected,
    required this.onChanged,
  });

  void _pick(String typeId, String valueId) {
    final next = Map<String, String>.from(selected);
    // الضغط على قيمة مختارة يلغي اختيارها
    if (next[typeId] == valueId) {
      next.remove(typeId);
    } else {
      next[typeId] = valueId;
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    if (product.optionTypes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final type in product.optionTypes) ...[
          _label(type),
          const SizedBox(height: 12),
          _valuesFor(type),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }

  Widget _label(OptionType type) {
    final chosen = selected[type.id];
    final chosenLabel = chosen == null
        ? null
        : type.values.firstWhere((v) => v.id == chosen).label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (chosenLabel != null)
          Text(chosenLabel,
              style: AppText.b1Regular.copyWith(color: AppColors.body)),
        if (chosenLabel != null) const SizedBox(width: AppSpacing.sm),
        Text('اختر ${type.name}',
            style: AppText.h4SemiBold.copyWith(color: AppColors.ink)),
      ],
    );
  }

  Widget _valuesFor(OptionType type) {
    final others = selected.entries
        .where((e) => e.key != type.id)
        .map((e) => e.value)
        .toSet();

    final children = type.values.map((value) {
      final isSelected = selected[type.id] == value.id;
      final isAvailable = product.isValueAvailable(value.id, others);

      return switch (type.display) {
        OptionDisplay.colorSwatch =>
          _swatch(type, value, isSelected, isAvailable),
        OptionDisplay.image => _imageChip(type, value, isSelected, isAvailable),
        _ => _chip(type, value, isSelected, isAvailable),
      };
    }).toList();

    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        textDirection: TextDirection.rtl,
        children: children,
      ),
    );
  }

  /// شكل الحبّة — يخدم المقاسات (S/M/L) وأحجام العطور (50 مل) معًا.
  Widget _chip(OptionType type, OptionValue value, bool selected, bool available) {
    return _Tappable(
      enabled: available,
      onTap: () => _pick(type.id, value.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        // قياس فِقما: 50 × 47.083 ، حشو 12.5 ، حد 1.351
        constraints: const BoxConstraints(minWidth: 50),
        height: 47.083,
        padding: const EdgeInsets.symmetric(horizontal: 12.5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
            width: 1.351,
          ),
        ),
        child: Text(
          value.label,
          textAlign: TextAlign.center,
          style: AppText.h4Medium.copyWith(
            color: !available
                ? AppColors.primary200
                : selected
                    ? AppColors.white
                    : AppColors.ink,
            decoration: available ? null : TextDecoration.lineThrough,
          ),
        ),
      ),
    );
  }

  Widget _swatch(OptionType type, OptionValue value, bool selected, bool available) {
    final color = _parseHex(value.hexColor) ?? AppColors.surface;
    return _Tappable(
      enabled: available,
      onTap: () => _pick(type.id, value.id),
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: available
              ? null
              : const Icon(Icons.close, size: 18, color: AppColors.white),
        ),
      ),
    );
  }

  Widget _imageChip(OptionType type, OptionValue value, bool selected, bool available) {
    return _Tappable(
      enabled: available,
      onTap: () => _pick(type.id, value.id),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.line,
            width: selected ? 2 : 1.351,
          ),
          image: value.imageUrl == null
              ? null
              : DecorationImage(
                  image: NetworkImage(value.imageUrl!),
                  fit: BoxFit.cover,
                ),
        ),
      ),
    );
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return null;
    return Color(cleaned.length == 6 ? 0xFF000000 | value : value);
  }
}

class _Tappable extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _Tappable({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: child,
      ),
    );
  }
}
