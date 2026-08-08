/// نماذج البيانات — مصممة بحيث لا تعرف شيئًا عن "المقاس" أو "الحجم".
/// كل خصائص المنتج تأتي من الخادم كبيانات، لا كحقول ثابتة.

enum ProductKind { physical, digital }

enum OptionDisplay { chip, colorSwatch, dropdown, image }

OptionDisplay _displayFrom(String? v) => switch (v) {
      'color_swatch' => OptionDisplay.colorSwatch,
      'dropdown' => OptionDisplay.dropdown,
      'image' => OptionDisplay.image,
      _ => OptionDisplay.chip,
    };

/// قيمة خيار واحدة: "M" أو "100 مل" أو "أسود".
class OptionValue {
  final String id;
  final String label;
  final double? numericValue;
  final String? hexColor;
  final String? imageUrl;

  const OptionValue({
    required this.id,
    required this.label,
    this.numericValue,
    this.hexColor,
    this.imageUrl,
  });

  factory OptionValue.fromJson(Map<String, dynamic> j) => OptionValue(
        id: j['id'] as String,
        label: j['value_ar'] as String,
        numericValue: (j['numeric_value'] as num?)?.toDouble(),
        hexColor: j['hex_color'] as String?,
        imageUrl: j['image_url'] as String?,
      );
}

/// نوع خيار: "المقاس" أو "الحجم" أو "اللون".
class OptionType {
  final String id;
  final String name;
  final String code;
  final OptionDisplay display;
  final String? unit;
  final List<OptionValue> values;

  const OptionType({
    required this.id,
    required this.name,
    required this.code,
    required this.display,
    required this.values,
    this.unit,
  });

  factory OptionType.fromJson(Map<String, dynamic> j) => OptionType(
        id: j['id'] as String,
        name: j['name_ar'] as String,
        code: j['code'] as String,
        display: _displayFrom(j['display_as'] as String?),
        unit: j['unit'] as String?,
        values: ((j['values'] as List?) ?? const [])
            .map((v) => OptionValue.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

/// متغيّر = تركيبة محددة من قيم الخيارات، ولها سعر ومخزون مستقلان.
class Variant {
  final String id;
  final String? sku;
  final double price;
  final int stock;
  final String? imageUrl;
  final Set<String> optionValueIds;

  const Variant({
    required this.id,
    required this.price,
    required this.stock,
    required this.optionValueIds,
    this.sku,
    this.imageUrl,
  });

  bool get inStock => stock > 0;

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        id: j['id'] as String,
        sku: j['sku'] as String?,
        price: (j['price'] as num).toDouble(),
        stock: (j['stock_qty'] as num?)?.toInt() ?? 0,
        imageUrl: j['image_url'] as String?,
        optionValueIds:
            ((j['option_value_ids'] as List?) ?? const []).cast<String>().toSet(),
      );
}

class Product {
  final String id;
  final String name;
  final String? description;
  final ProductKind kind;
  final double basePrice;
  final double? compareAtPrice;
  final double ratingAvg;
  final int ratingCount;
  final List<String> images;
  final List<OptionType> optionTypes;
  final List<Variant> variants;

  const Product({
    required this.id,
    required this.name,
    required this.kind,
    required this.basePrice,
    required this.images,
    required this.optionTypes,
    required this.variants,
    this.description,
    this.compareAtPrice,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  bool get isDigital => kind == ProductKind.digital;
  bool get hasDiscount =>
      compareAtPrice != null && compareAtPrice! > basePrice;
  int get discountPercent => hasDiscount
      ? (((compareAtPrice! - basePrice) / compareAtPrice!) * 100).round()
      : 0;

  /// نتيجة استدعاء دالة `product_full` في Supabase.
  factory Product.fromFullJson(Map<String, dynamic> j) {
    final p = j['product'] as Map<String, dynamic>;
    return Product(
      id: p['id'] as String,
      name: p['name_ar'] as String,
      description: p['description_ar'] as String?,
      kind: p['kind'] == 'digital' ? ProductKind.digital : ProductKind.physical,
      basePrice: (p['base_price'] as num).toDouble(),
      compareAtPrice: (p['compare_at_price'] as num?)?.toDouble(),
      ratingAvg: (p['rating_avg'] as num?)?.toDouble() ?? 0,
      ratingCount: (p['rating_count'] as num?)?.toInt() ?? 0,
      images: ((j['images'] as List?) ?? const []).cast<String>(),
      optionTypes: ((j['option_types'] as List?) ?? const [])
          .map((o) => OptionType.fromJson(o as Map<String, dynamic>))
          .toList(),
      variants: ((j['variants'] as List?) ?? const [])
          .map((v) => Variant.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }

  /// يجد المتغيّر المطابق للاختيارات الحالية.
  /// منتج بلا خيارات (رقمي غالبًا) يُرجع متغيّره الوحيد مباشرة.
  Variant? matchVariant(Set<String> selectedValueIds) {
    if (optionTypes.isEmpty) {
      return variants.isEmpty ? null : variants.first;
    }
    if (selectedValueIds.length != optionTypes.length) return null;
    for (final v in variants) {
      if (v.optionValueIds.containsAll(selectedValueIds)) return v;
    }
    return null;
  }

  /// هل هذه القيمة متاحة بالنظر لبقية الاختيارات؟
  /// تُستخدم لتعطيل "مقاس M" مثلًا إذا نفد مع اللون المختار.
  bool isValueAvailable(String valueId, Set<String> otherSelected) {
    return variants.any((v) =>
        v.inStock &&
        v.optionValueIds.contains(valueId) &&
        v.optionValueIds.containsAll(otherSelected));
  }
}
