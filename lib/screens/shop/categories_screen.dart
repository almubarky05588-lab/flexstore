import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../main_shell.dart' show activeTabNotifier;

/// شاشة الأقسام — قائمة أقسام جانبية يمين، ومحتوى القسم يسار:
/// تصنيفات فرعية (نصية / دائرية / مربعة) ثم منتجات القسم.
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _products = [];
  Set<String> _favoriteIds = {};
  String? _selectedId;
  String? _selectedSubId;
  bool _loading = true;
  bool _loadingContent = false;

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
        _selectedId ??= cats.isEmpty ? null : cats.first['id'] as String;
      });
      if (_selectedId != null) await _loadContent(_selectedId!);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadContent(String categoryId) async {
    setState(() => _loadingContent = true);
    try {
      final subs = await _service.subcategories(categoryId);
      final targetId = _selectedSubId ?? categoryId;
      final prods = await _service.products(categoryId: targetId);
      if (!mounted) return;
      setState(() {
        _subcategories = subs;
        _products = prods;
      });
    } finally {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  void _selectCategory(String id) {
    if (_selectedId == id) return;
    setState(() {
      _selectedId = id;
      _selectedSubId = null;
      _subcategories = [];
    });
    _loadContent(id);
  }

  void _selectSub(String? subId) {
    setState(() => _selectedSubId = subId);
    if (_selectedId != null) _loadContent(_selectedId!);
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
    // فصل التصنيفات النصية عن المصوّرة
    final textSubs = _subcategories
        .where((s) => (s['shape'] as String? ?? 'circle') == 'text')
        .toList();
    final cardSubs = _subcategories
        .where((s) => (s['shape'] as String? ?? 'circle') != 'text')
        .toList();

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
                    // القائمة الجانبية — يمين
                    Container(
                      width: 104,
                      color: AppColors.surface.withValues(alpha: 0.45),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final c = _categories[i];
                          final id = c['id'] as String;
                          final selected = _selectedId == id;
                          return GestureDetector(
                            onTap: () => _selectCategory(id),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 16),
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

                    // المحتوى — يسار
                    Expanded(
                      child: _loadingContent
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 12, 12, 24),
                              children: [
                                // التصنيفات النصية — حبّات بلا صور
                                if (textSubs.isNotEmpty) ...[
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      textDirection: TextDirection.rtl,
                                      children: [
                                        _textChip('الكل', _selectedSubId == null,
                                            () => _selectSub(null)),
                                        for (final s in textSubs)
                                          _textChip(
                                            s['name_ar'] as String,
                                            _selectedSubId == s['id'],
                                            () => _selectSub(s['id'] as String),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],

                                // التصنيفات المصوّرة — بطاقات دائرية/مربعة
                                if (cardSubs.isNotEmpty) ...[
                                  _SubcategoryGrid(
                                    items: cardSubs,
                                    selectedId: _selectedSubId,
                                    onSelect: _selectSub,
                                    showAllTile: textSubs.isEmpty,
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                ],

                                if (_subcategories.isNotEmpty) ...[
                                  const Divider(height: 1),
                                  const SizedBox(height: AppSpacing.lg),
                                ],

                                // المنتجات
                                if (_products.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 30),
                                    child: EmptyState(
                                      icon: Icons.inventory_2_outlined,
                                      title: 'لا توجد منتجات!',
                                      message: 'ما فيه منتجات هنا حاليًا.',
                                    ),
                                  )
                                else
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                              ],
                            ),
                    ),
                  ],
                ),
    );
  }

  /// حبّة تصنيف نصية — بلا صورة ولا بطاقة.
  Widget _textChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(
              color: selected ? AppColors.ink : AppColors.line),
        ),
        child: Text(
          label,
          style: AppText.b3Medium.copyWith(
            color: selected ? AppColors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// شبكة التصنيفات المصوّرة — بطاقات دائرية أو مربعة.
class _SubcategoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final bool showAllTile;

  const _SubcategoryGrid({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.showAllTile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 16,
      alignment: WrapAlignment.start,
      textDirection: TextDirection.rtl,
      children: [
        if (showAllTile)
          _tile(
            label: 'الكل',
            imageUrl: null,
            circle: true,
            selected: selectedId == null,
            onTap: () => onSelect(null),
          ),
        for (final s in items)
          _tile(
            label: s['name_ar'] as String,
            imageUrl: s['image_url'] as String?,
            circle: (s['shape'] as String? ?? 'circle') == 'circle',
            selected: selectedId == s['id'],
            onTap: () => onSelect(s['id'] as String),
          ),
      ],
    );
  }

  Widget _tile({
    required String label,
    required String? imageUrl,
    required bool circle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const size = 74.0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: size,
              height: size,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: circle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius:
                    circle ? null : BorderRadius.circular(AppRadius.base),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.line,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: circle
                    ? BorderRadius.circular(size)
                    : BorderRadius.circular(AppRadius.heartSmall),
                child: Container(
                  color: AppColors.surface,
                  child: imageUrl == null
                      ? const Center(
                          child:
                              Icon(Icons.apps, size: 26, color: AppColors.body))
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_outlined,
                                size: 22, color: AppColors.body),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: AppText.b3Medium.copyWith(
                color: selected ? AppColors.ink : AppColors.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
