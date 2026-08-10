import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../main_shell.dart' show activeTabNotifier;

/// شاشة الأقسام — قائمة تصنيفات جانبية يمين + شبكة منتجات القسم يسار.
/// التصنيفات ديناميكية من القاعدة: أي إضافة/حذف من لوحة التحكم يظهر هنا.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  Set<String> _favoriteIds = {};
  String? _selectedId;
  bool _loading = true;
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    _load();
    activeTabNotifier.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    activeTabNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    // الأقسام = تبويب 1: نحدّث التصنيفات والمفضلة عند فتحه
    if (activeTabNotifier.value == 1 && mounted) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.categories(),
        _service.favoriteIds(),
      ]);
      if (!mounted) return;
      final cats = results[0] as List<Map<String, dynamic>>;
      setState(() {
        _categories = cats;
        _favoriteIds = results[1] as Set<String>;
        // اختر أول تصنيف تلقائيًا إن لم يكن مختارًا
        _selectedId ??= cats.isEmpty ? null : cats.first['id'] as String;
      });
      if (_selectedId != null) await _loadProducts(_selectedId!);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadProducts(String categoryId) async {
    setState(() => _loadingProducts = true);
    try {
      final r = await _service.products(categoryId: categoryId);
      if (!mounted) return;
      setState(() => _products = r);
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  void _select(String id) {
    if (_selectedId == id) return;
    setState(() => _selectedId = id);
    _loadProducts(id);
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
      appBar: const AppHeader(title: 'الأقسام', showBack: false),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const EmptyState(
                  icon: Icons.category_outlined,
                  title: 'لا توجد أقسام!',
                  message: 'ما فيه أقسام مضافة حاليًا.')
              : Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // القائمة الجانبية — على اليمين
                    Container(
                      width: 108,
                      color: AppColors.surface.withValues(alpha: 0.45),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final c = _categories[i];
                          final id = c['id'] as String;
                          final selected = _selectedId == id;
                          return GestureDetector(
                            onTap: () => _select(id),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 16),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.white
                                    : Colors.transparent,
                                border: Border(
                                  right: BorderSide(
                                    color: selected
                                        ? AppColors.accent
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Text(
                                c['name_ar'] as String,
                                textAlign: TextAlign.center,
                                style: selected
                                    ? AppText.b2Medium
                                        .copyWith(color: AppColors.ink)
                                    : AppText.b2Regular
                                        .copyWith(color: AppColors.body),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // شبكة منتجات القسم — على اليسار
                    Expanded(
                      child: _loadingProducts
                          ? const Center(child: CircularProgressIndicator())
                          : _products.isEmpty
                              ? const EmptyState(
                                  icon: Icons.inventory_2_outlined,
                                  title: 'لا توجد منتجات!',
                                  message: 'ما فيه منتجات في هذا القسم حاليًا.')
                              : GridView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 12, 24),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 14,
                                    childAspectRatio: 120 / 168,
                                  ),
                                  itemCount: _products.length,
                                  itemBuilder: (_, i) {
                                    final p = _products[i];
                                    final images =
                                        (p['product_images'] as List?) ?? [];
                                    final id = p['id'] as String;
                                    return ProductGridCard(
                                      name: p['name_ar'] as String,
                                      price: p['base_price'] as num,
                                      compareAt:
                                          p['compare_at_price'] as num?,
                                      imageUrl: images.isEmpty
                                          ? null
                                          : images.first['url'] as String,
                                      isFavorite: _favoriteIds.contains(id),
                                      onFavorite: () => _toggleFavorite(id),
                                      onTap: () => Navigator.of(context)
                                          .pushNamed('/product',
                                              arguments: id),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
    );
  }
}
