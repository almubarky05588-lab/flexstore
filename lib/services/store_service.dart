import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// طبقة الوصول للبيانات — كل تعامل مع Supabase يمرّ من هنا.
class StoreService {
  final _client = Supabase.instance.client;

  String get _uid => _client.auth.currentUser!.id;

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
  /// الأقسام الرئيسية فقط (بلا تصنيفات فرعية).
  Future<List<Map<String, dynamic>>> categories() async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .isFilter('parent_id', null)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// التصنيفات الفرعية داخل قسم معيّن (بطاقات دائرية/مربعة بصور).
  Future<List<Map<String, dynamic>>> subcategories(String parentId) async {
    final rows = await _client
        .from('categories')
        .select()
        .eq('is_active', true)
        .eq('parent_id', parentId)
        .order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  // ------------------------------------------------------------------ المنتجات
  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    String? search,
  }) async {
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

  Future<Product> product(String id) async {
    final data = await _client.rpc('product_full', params: {'p_product_id': id});
    return Product.fromFullJson(Map<String, dynamic>.from(data as Map));
  }

  // ------------------------------------------------------------------- المفضلة
  Future<Set<String>> favoriteIds() async {
    final rows =
        await _client.from('favorites').select('product_id').eq('user_id', _uid);
    return rows.map((r) => r['product_id'] as String).toSet();
  }

  Future<List<Map<String, dynamic>>> favorites() async {
    final rows = await _client
        .from('favorites')
        .select('product_id, products(*, product_images(url, sort_order))')
        .eq('user_id', _uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> toggleFavorite(String productId) async {
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
            id, price, image_url, stock,
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
  Future<String> placeOrder({String? addressId, required String payMethod}) async {
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
        .select('*, order_items(quantity, unit_price, name_snapshot, options_snapshot)')
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
