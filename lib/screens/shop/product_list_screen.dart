import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';

/// صفحة قائمة منتجات — تفتح من البنرات أو التصنيفات.
/// تعرض منتجات التصنيف حسب نوعه: عادي، الأكثر مبيعًا، أو قائمة يدوية.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _products = [];
  Set<String> _favoriteIds = {};
  String _title = 'المنتجات';
  bool _loading = true;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    String? categoryId;
    if (args is String) {
      categoryId = args;
    } else if (args is Map) {
      categoryId = args['categoryId'] as String?;
      _title = (args['title'] as String?) ?? _title;
    }
    if (categoryId != null) {
      _load(categoryId);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _load(String categoryId) async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.categoryProducts(categoryId),
        _service.favoriteIds(),
        _service.category(categoryId),
      ]);
      if (!mounted) return;
      final cat = results[2] as Map<String, dynamic>?;
      setState(() {
        _products = results[0] as List<Map<String, dynamic>>;
        _favoriteIds = results[1] as Set<String>;
        if (cat != null && (cat['name_ar'] as String?)?.isNotEmpty == true) {
          _title = cat['name_ar'] as String;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorite(String productId) async {
    setState(() {
      if (_favoriteIds.contains(productId)) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
    });
    try {
      await _service.toggleFavorite(productId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_favoriteIds.contains(productId)) {
          _favoriteIds.remove(productId);
        } else {
          _favoriteIds.add(productId);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: _title),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'لا توجد منتجات!',
                  message: 'ما فيه منتجات هنا حاليًا.')
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(25, 12, 25, 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 16,
                    childAspectRatio: 161 / 210,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (_, i) {
                    final p = _products[i];
                    final images = (p['product_images'] as List?) ?? [];
                    final id = p['id'] as String;
                    return ProductGridCard(
                      name: p['name_ar'] as String,
                      price: p['base_price'] as num,
                      compareAt: p['compare_at_price'] as num?,
                      imageUrl: images.isEmpty
                          ? null
                          : images.first['url'] as String,
                      isFavorite: _favoriteIds.contains(id),
                      onFavorite: () => _toggleFavorite(id),
                      onTap: () => Navigator.of(context)
                          .pushNamed('/product', arguments: id),
                    );
                  },
                ),
    );
  }
}
