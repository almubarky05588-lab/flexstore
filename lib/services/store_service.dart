import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// طبقة الوصول للبيانات — كل تعامل مع Supabase (وسلة) يمرّ من هنا.
///
/// مصدر البيانات يُقرأ من `store_settings.data_source`:
///   supabase (افتراضي) | salla
/// في وضع سلة: المنتجات والأقسام تأتي من سلة عبر وسيط `salla-api`.
/// الإعدادات والبنرات والإشعارات تبقى على Supabase.
class StoreService {
  final _client = Supabase.instance.client;

  String get _uid => _client.auth.currentUser!.id;

  // ============================================================ مصدر البيانات
  String? _cachedSource;

  Future<String> _source() async {
    if (_cachedSource != null) return _cachedSource!;
    final s = await storeSettings();
    _cachedSource =
        (s['data_source'] as String?) == 'salla' ? 'salla' : 'supabase';
    return _cachedSource!;
  }

  // ----------------------------------------------------- نداء وسيط سلة الآمن
  /// ينادي دالة `salla-api` (GET). الرد مغلّف: { store, status, data }.
  Future<dynamic> _sallaGet(String resource,
      {Map<String, String>? params}) async {
    final res = await _client.functions.invoke(
      'salla-api',
      method: HttpMethod.get,
      queryParameters: {'resource': resource, ...?params},
    );
    final body = res.data;
    if (body is Map && body.containsKey('data')) return body['data'];
    return body;
  }

  // ------------------------------------------------------- أدوات تحويل سلة
  /// سلة ترسل السعر ككائن { amount, currency }.
  double? _amount(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is Map) {
      final a = v['amount'];
      if (a is num) return a.toDouble();
      if (a is String) return double.tryParse(a);
    }
    if (v is String) return double.tryParse(v);
    return null;
  }

  List<String> _images(Map s) {
    final out = <String>[];
    final imgs = s['images'];
    if (imgs is List) {
      for (final im in imgs) {
        if (im is Map && im['url'] != null) {
          out.add('${im['url']}');
        } else if (im is String) {
          out.add(im);
        }
      }
    }
    for (final k in const ['main_image', 'thumbnail']) {
      if (out.isEmpty && s[k] != null) {
        final im = s[k];
        out.add(im is Map ? '${im['url']}' : '$im');
      }
    }
    return out;
  }

  String _display(String t) {
    final x = t.toLowerCase();
    if (x.contains('color')) return 'color_swatch';
    if (x.contains('image')) return 'image';
    return 'chip';
  }

  String? _stripHtml(String? html) {
    if (html == null || html.isEmpty) return null;
    final t = html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return t.isEmpty ? null : t;
  }

  /// السعر الحالي والسعر قبل الخصم.
  /// في سلة: price/sale_price = الحالي، regular_price = قبل الخصم.
  ({double current, double? before}) _prices(Map s) {
    final price = _amount(s['price']) ?? 0;
    final sale = _amount(s['sale_price']);
    final regular = _amount(s['regular_price']);
    final current = (sale != null && sale > 0) ? sale : price;
    final before = (regular != null && regular > current) ? regular : null;
    return (current: current, before: before);
  }

  /// منتج سلة → شكل القائمة الذي تقرأه كروت المنتجات.
  Map<String, dynamic> _sallaListItem(Map s) {
    final p = _prices(s);
    return {
      'id': '${s['id']}',
      'name_ar': (s['name'] ?? '').toString(),
      'base_price': p.current,
      'compare_at_price': p.before,
      'product_images': _images(s).map((u) => {'url': u}).toList(),
    };
  }

  /// منتج سلة → شكل `Product.fromFullJson` الكامل (خيارات/نسخ/صور).
  Map<String, dynamic> _sallaFullJson(Map s) {
    final p = _prices(s);

    final rating = s['rating'];
    final ratingAvg = rating is Map ? (_amount(rating['rate']) ?? 0) : 0;
    final ratingCount =
        rating is Map ? ((rating['count'] as num?)?.toInt() ?? 0) : 0;

    // في سلة نوع المنتج الرقمي: digital / codes / file
    final rawType = '${s['type'] ?? ''}'.toLowerCase();
    final kind =
        (rawType == 'digital' || rawType == 'codes' || rawType == 'file')
            ? 'digital'
            : 'physical';

    final unlimited = s['unlimited_quantity'] == true;
    final available = s['is_available'] != false;

    // الخيارات
    final optionTypes = <Map<String, dynamic>>[];
    final outOfStockValues = <String>{};
    final opts = s['options'];
    if (opts is List) {
      for (final o in opts) {
        if (o is! Map) continue;
        final values = <Map<String, dynamic>>[];
        final vs = o['values'];
        if (vs is List) {
          for (final v in vs) {
            if (v is! Map) continue;
            final vid = '${v['id']}';
            if (v['is_out_of_stock'] == true) outOfStockValues.add(vid);
            final vImg = v['image_url'] ?? v['image'];
            values.add({
              'id': vid,
              'value_ar': (v['name'] ?? v['display_value'] ?? '').toString(),
              'hex_color': v['hex_color'] ?? v['color'],
              'image_url': vImg is Map ? '${vImg['url']}' : vImg,
            });
          }
        }
        if (values.isEmpty) continue;
        optionTypes.add({
          'id': '${o['id']}',
          'name_ar': (o['name'] ?? '').toString(),
          'code': '${o['id']}',
          'display_as': _display('${o['display_type'] ?? o['type'] ?? ''}'),
          'values': values,
        });
      }
    }

    /// المخزون في سلة قد يكون 0 مع كون المنتج متاحًا (كمية غير محدودة).
    int stockOf(Map? sku) {
      final skuUnlimited = sku?['unlimited_quantity'] == true;
      final q = (sku?['stock_quantity'] as num?)?.toInt() ??
          (s['quantity'] as num?)?.toInt();
      if (q != null && q > 0) return q;
      if (skuUnlimited || unlimited) return 99;
      if (q == null && available) return 99;
      return q ?? 0;
    }

    // النسخ (skus). منتج بلا خيارات → نسخة واحدة مركّبة.
    final variants = <Map<String, dynamic>>[];
    final skus = s['skus'];
    if (skus is List && skus.isNotEmpty && optionTypes.isNotEmpty) {
      for (final k in skus) {
        if (k is! Map) continue;
        final ids = ((k['related_option_values'] as List?) ?? const [])
            .map((e) => '$e')
            .toList();
        final kSale = _amount(k['sale_price']);
        final kPrice = _amount(k['price']);
        final kCurrent =
            (kSale != null && kSale > 0) ? kSale : (kPrice ?? p.current);
        final soldOut = ids.any(outOfStockValues.contains);
        variants.add({
          'id': '${k['id']}',
          'sku': k['sku'] ?? k['barcode'],
          'price': kCurrent,
          'stock_qty': soldOut ? 0 : stockOf(k),
          'image_url': null,
          'option_value_ids': ids,
        });
      }
    }
    if (variants.isEmpty) {
      variants.add({
        'id': '${s['id']}',
        'sku': s['sku'] ?? s['barcode'],
        'price': p.current,
        'stock_qty': stockOf(null),
        'image_url': null,
        'option_value_ids': const [],
      });
    }

    return {
      'product': {
        'id': '${s['id']}',
        'name_ar': (s['name'] ?? '').toString(),
        'description_ar': _stripHtml(s['description']?.toString()),
        'kind': kind,
        'base_price': p.current,
        'compare_at_price': p.before,
        'rating_avg': ratingAvg,
        'rating_count': ratingCount,
      },
      'images': _images(s),
      'option_types': variants.length > 1 ? optionTypes : const [],
      'variants': variants,
    };
  }

  /// أقسام سلة تُسحب مرة وتُسطّح (جذور + أبناء) مع ربط الأب.
  /// ملاحظة: سلة ترسل parent_id = 0 للأقسام الرئيسية.
  List<Map<String, dynamic>>? _catCache;

  Future<List<Map<String, dynamic>>> _sallaFlatCategories() async {
    if (_catCache != null) return _catCache!;
    final data = await _sallaGet('categories');
    final out = <Map<String, dynamic>>[];

    void walk(dynamic node, String? parent) {
      if (node is List) {
        for (final n in node) {
          walk(n, parent);
        }
        return;
      }
      if (node is! Map) return;
      final id = '${node['id']}';
      final raw = node['parent_id'];
      final isRoot = raw == null || raw == 0 || '$raw' == '0';
      final pid = isRoot ? parent : '$raw';
      final m = Map<String, dynamic>.from(node);
      m['_id'] = id;
      m['_parent'] = pid;
      out.add(m);
      if (node['sub_categories'] is List) walk(node['sub_categories'], id);
    }

    walk(data, null);
    _catCache = out;
    return out;
  }

  Map<String, dynamic> _sallaCategory(Map c) {
    final img = c['image'];
    final url = img is Map ? '${img['url']}' : img?.toString();
    return {
      'id': c['_id'] ?? '${c['id']}',
      'name_ar': (c['name'] ?? '').toString(),
      'shape': 'circle',
      'image_url': (url == null || url.isEmpty || url == 'null') ? null : url,
      'parent_id': c['_parent'],
      'is_active': (c['status']?.toString() ?? 'active') == 'active',
    };
  }

  List<Map<String, dynamic>> _sallaProductList(dynamic data) {
    final list = (data is List) ? data : const [];
    return list
        .whereType<Map>()
        .where((m) => m['status']?.toString() != 'hidden')
        .map((m) => _sallaListItem(m))
        .toList();
  }

  // ------------------------------------------------------------ إعدادات المتجر
  Future<Map<String, dynamic>> storeSettings() async {
    final rows = await _client.from('store_settings').select().limit(1);
    return rows.isEmpty ? {} : rows.first;
  }

  Future<String?> singleCategoryId() async {
    final s = await storeSettings();
    if (s['store_mode'] == 'single_category') {
      return s['single_category_id'] as String?;
    }
    return null;
  }

  // ------------------------------------------------------------------- البنرات
  Future<List<Map<String, dynamic>>> promoBanners() async {
    final rows = await _client
        .from('promo_banners')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> categoryBanners() async {
    final rows = await _client
        .from('category_banners')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  // ----------------------------------------------------------------- التصنيفات
  Future<List<Map<String, dynamic>>> categories() async {
    if (await _source() == 'salla') {
      final flat = await _sallaFlatCategories();
      return flat
          .where((c) => c['_parent'] == null)
          .map(_sallaCategory)
          .where((c) => c['is_active'] == true)
          .toList();
    }
    final rows = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .isFilter('parent_id', null)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> subcategories(String parentId) async {
    if (await _source() == 'salla') {
      final flat = await _sallaFlatCategories();
      return flat
          .where((c) => c['_parent'] == parentId)
          .map(_sallaCategory)
          .where((c) => c['is_active'] == true)
          .toList();
    }
    final rows = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .eq('parent_id', parentId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// بيانات تصنيف واحد (للعنوان في صفحة القائمة).
  Future<Map<String, dynamic>?> category(String id) async {
    if (await _source() == 'salla') {
      final flat = await _sallaFlatCategories();
      final c = flat.firstWhere(
        (e) => e['_id'] == id,
        orElse: () => <String, dynamic>{},
      );
      return c.isEmpty ? null : _sallaCategory(c);
    }
    final row =
        await _client.from('categories').select().eq('id', id).maybeSingle();
    return row;
  }

  // ------------------------------------------------------------------ المنتجات
  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    String? search,
  }) async {
    if (await _source() == 'salla') {
      final params = <String, String>{};
      if (search != null && search.trim().isNotEmpty) {
        params['keyword'] = search.trim();
      }
      if (categoryId != null) params['category'] = categoryId;
      final data = await _sallaGet('products', params: params);
      return _sallaProductList(data);
    }

    var query = _client
        .from('products')
        .select('*, product_images(url, sort_order)')
        .eq('is_active', true);

    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name_ar', '%${search.trim()}%');
    }

    final rows = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// منتجات تصنيف حسب نوعه (عادي / الأكثر مبيعًا / يدوي) عبر دالة القاعدة.
  Future<List<Map<String, dynamic>>> categoryProducts(String categoryId) async {
    if (await _source() == 'salla') {
      final data =
          await _sallaGet('products', params: {'category': categoryId});
      return _sallaProductList(data);
    }

    final data = await _client
        .rpc('category_products_list', params: {'p_category_id': categoryId});
    final list = List<Map<String, dynamic>>.from(data as List);
    if (list.isEmpty) return list;

    // نجلب صور هذه المنتجات ونضمّها
    final ids = list.map((p) => p['id'] as String).toList();
    final imgs = await _client
        .from('product_images')
        .select('product_id, url, sort_order')
        .inFilter('product_id', ids)
        .order('sort_order');

    final byProduct = <String, List<Map<String, dynamic>>>{};
    for (final img in List<Map<String, dynamic>>.from(imgs)) {
      (byProduct[img['product_id'] as String] ??= []).add(img);
    }
    for (final p in list) {
      p['product_images'] = byProduct[p['id']] ?? [];
    }
    return list;
  }

  Future<Product> product(String id) async {
    if (await _source() == 'salla') {
      final data = await _sallaGet('product', params: {'id': id});
      final map = (data is Map && data['id'] != null)
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{'id': id};
      return Product.fromFullJson(_sallaFullJson(map));
    }
    final data = await _client.rpc('product_full', params: {'p_product_id': id});
    return Product.fromFullJson(Map<String, dynamic>.from(data as Map));
  }

  // ------------------------------------------------------------------- المفضلة
  Future<Set<String>> favoriteIds() async {
    if (await _source() == 'salla') return <String>{};
    final rows = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', _uid);
    return rows.map((r) => r['product_id'] as String).toSet();
  }

  Future<List<Map<String, dynamic>>> favorites() async {
    if (await _source() == 'salla') return <Map<String, dynamic>>[];
    final rows = await _client
        .from('favorites')
        .select('product_id, products(*, product_images(url, sort_order))')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> toggleFavorite(String productId) async {
    if (await _source() == 'salla') return;
    final existing = await _client
        .from('favorites')
        .select('product_id')
        .eq('user_id', _uid)
        .eq('product_id', productId)
        .maybeSingle();

    if (existing == null) {
      await _client
          .from('favorites')
          .insert({'user_id': _uid, 'product_id': productId});
    } else {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', _uid)
          .eq('product_id', productId);
    }
  }

  // -------------------------------------------------------------------- السلة
  Future<List<Map<String, dynamic>>> cart() async {
    final rows = await _client
        .from('cart_items')
        .select('''
          id, quantity,
          variants(
            id, price, image_url, stock_qty,
            products(id, name_ar, base_price, kind),
            variant_option_values(
              option_values(value_ar, option_types(name_ar))
            )
          )
        ''')
        .eq('user_id', _uid)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addToCart(String variantId, {int quantity = 1}) async {
    if (await _source() == 'salla') {
      throw Exception('الشراء من متجر سلة غير مفعّل بعد');
    }
    final existing = await _client
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', _uid)
        .eq('variant_id', variantId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('cart_items').insert({
        'user_id': _uid,
        'variant_id': variantId,
        'quantity': quantity,
      });
    } else {
      await _client.from('cart_items').update({
        'quantity': (existing['quantity'] as int) + quantity,
      }).eq('id', existing['id'] as String);
    }
  }

  Future<void> updateCartQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await _client.from('cart_items').delete().eq('id', cartItemId);
    } else {
      await _client
          .from('cart_items')
          .update({'quantity': quantity}).eq('id', cartItemId);
    }
  }

  // ------------------------------------------------------------------ العناوين
  Future<List<Map<String, dynamic>>> addresses() async {
    final rows = await _client
        .from('addresses')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addAddress({
    required String label,
    required String fullText,
    String? city,
    bool isDefault = false,
  }) async {
    await _client.from('addresses').insert({
      'user_id': _uid,
      'label': label,
      'full_text': fullText,
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      'is_default': isDefault,
    });
  }

  Future<void> deleteAddress(String addressId) async {
    await _client.from('addresses').delete().eq('id', addressId);
  }

  // ------------------------------------------------------------ بطاقات الدفع
  Future<List<Map<String, dynamic>>> paymentCards() async {
    final rows = await _client
        .from('payment_cards')
        .select()
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> addPaymentCard({
    required String last4,
    required String brand,
    required int expMonth,
    required int expYear,
    String? holderName,
    bool isDefault = false,
  }) async {
    await _client.from('payment_cards').insert({
      'user_id': _uid,
      'last4': last4,
      'brand': brand,
      'exp_month': expMonth,
      'exp_year': expYear,
      if (holderName != null && holderName.trim().isNotEmpty)
        'holder_name': holderName.trim(),
      'is_default': isDefault,
    });
  }

  Future<void> deletePaymentCard(String cardId) async {
    await _client.from('payment_cards').delete().eq('id', cardId);
  }

  // ------------------------------------------------------------------- الطلبات
  Future<String> placeOrder(
      {String? addressId, required String payMethod}) async {
    final data = await _client.rpc('place_order', params: {
      'p_address_id': addressId,
      'p_pay_method': payMethod,
    });
    return data as String;
  }

  Future<void> fulfillDigital(String orderId) async {
    await _client.functions.invoke('fulfill-digital-order', body: {
      'order_id': orderId,
    });
  }

  Future<List<Map<String, dynamic>>> orders({bool ongoing = true}) async {
    final statuses = ongoing
        ? ['pending', 'processing', 'shipped']
        : ['delivered', 'cancelled', 'refunded'];
    final rows = await _client
        .from('orders')
        .select(
            '*, order_items(quantity, unit_price, name_snapshot, options_snapshot)')
        .eq('user_id', _uid)
        .inFilter('status', statuses)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> orderTracking(String orderId) async {
    final rows = await _client
        .from('order_tracking')
        .select()
        .eq('order_id', orderId)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }
}
