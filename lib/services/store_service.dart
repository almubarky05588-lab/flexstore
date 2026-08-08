import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

/// طبقة الوصول للبيانات. كل استدعاء يمر عبر سياسات RLS في الخادم،
/// فلا يمكن للعميل قراءة ما ليس له حتى لو عُدّل التطبيق.
class StoreService {
  final SupabaseClient _db = Supabase.instance.client;

  // ---------------------------------------------------------------- الكتالوج

  /// إعدادات المتجر — منها تُقرأ العملة ونسبة الضريبة واسم المتجر.
  Future<Map<String, dynamic>> storeSettings() async {
    return await _db.from('store_settings').select().eq('id', 1).single();
  }

  Future<List<Map<String, dynamic>>> categories() async {
    return await _db
        .from('categories')
        .select('id, name_ar, slug, image_url')
        .eq('is_active', true)
        .order('sort_order');
  }

  /// قائمة المنتجات مع أول صورة وأقل سعر متاح.
  Future<List<Map<String, dynamic>>> products({
    String? categoryId,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    var query = _db
        .from('products')
        .select(
          'id, name_ar, base_price, compare_at_price, kind, '
          'rating_avg, rating_count, product_images(url)',
        )
        .eq('is_active', true);

    if (categoryId != null) query = query.eq('category_id', categoryId);
    if (search != null && search.trim().isNotEmpty) {
      query = query.ilike('name_ar', '%${search.trim()}%');
    }

    return await query.range(offset, offset + limit - 1);
  }

  /// المنتج كاملًا: خياراته ومتغيّراته وصوره في استدعاء واحد.
  Future<Product> product(String id) async {
    final data = await _db.rpc('product_full', params: {'p_product_id': id});
    if (data == null) throw Exception('المنتج غير موجود');
    return Product.fromFullJson(Map<String, dynamic>.from(data as Map));
  }

  // ------------------------------------------------------------------ السلة

  Future<List<Map<String, dynamic>>> cart() async {
    return await _db.from('cart_items').select(
          'id, quantity, '
          'variants(id, price, stock_qty, image_url, '
          'products(id, name_ar, base_price, kind), '
          'variant_option_values(option_values(value_ar, option_types(name_ar))))',
        );
  }

  Future<void> addToCart(String variantId, {int quantity = 1}) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('سجّل الدخول أولًا');

    // upsert يجمع الكمية إذا كان المتغيّر موجودًا في السلة
    await _db.from('cart_items').upsert(
      {'user_id': userId, 'variant_id': variantId, 'quantity': quantity},
      onConflict: 'user_id,variant_id',
    );
  }

  Future<void> updateCartQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await _db.from('cart_items').delete().eq('id', cartItemId);
      return;
    }
    await _db.from('cart_items').update({'quantity': quantity}).eq('id', cartItemId);
  }

  // ----------------------------------------------------------------- الطلبات

  /// ينشئ الطلب داخل معاملة واحدة على الخادم (تحقّق مخزون + حساب + تفريغ سلة).
  Future<String> placeOrder({
    String? addressId,
    required String payMethod,
    String? notes,
  }) async {
    final orderId = await _db.rpc('place_order', params: {
      'p_address_id': addressId,
      'p_pay_method': payMethod,
      'p_notes': notes,
    });
    return orderId as String;
  }

  /// تُستدعى بعد تأكيد الدفع؛ ترسل الأكواد أو الملفات لبريد العميل.
  Future<void> fulfillDigital(String orderId) async {
    await _db.functions.invoke(
      'fulfill-digital-order',
      body: {'order_id': orderId},
    );
  }

  Future<List<Map<String, dynamic>>> orders({bool ongoing = true}) async {
    final statuses = ongoing
        ? ['pending', 'processing', 'shipped']
        : ['delivered', 'cancelled', 'refunded'];

    return await _db
        .from('orders')
        .select('*, order_items(*)')
        .inFilter('status', statuses)
        .order('created_at', ascending: false);
  }

  // -------------------------------------------------------- العناوين والمفضلة

  Future<List<Map<String, dynamic>>> addresses() async {
    return await _db.from('addresses').select().order('is_default', ascending: false);
  }

  Future<void> toggleFavorite(String productId, bool isFavorite) async {
    final userId = _db.auth.currentUser?.id;
    if (userId == null) throw Exception('سجّل الدخول أولًا');

    if (isFavorite) {
      await _db.from('favorites').insert({'user_id': userId, 'product_id': productId});
    } else {
      await _db
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    }
  }
}
