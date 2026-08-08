import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../../widgets/app_icons.dart';

/// الرئيسية "اكتشف" — بحث + فلتر + حبّات التصنيفات + شبكة منتجات عمودين.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _products = [];
  String? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.categories(),
        _service.products(categoryId: _selectedCategory),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0];
        _products = results[1];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // "اكتشف" على اليمين والجرس على اليسار
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 12, 25, 0),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Text('اكتشف', style: AppText.h3SemiBold),
                  const Spacer(),
                  const _NotificationBell(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // شريط البحث + زر الفلاتر
            Padding(
              padding: AppSpacing.screenPadding,
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: SearchField(
                      readOnly: true,
                      onTap: () => Navigator.of(context).pushNamed('/search'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: () => _openFilters(context),
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: kAccentGradient,
                        borderRadius: BorderRadius.circular(AppRadius.base),
                        boxShadow: const [kAccentShadow],
                      ),
                      child: Center(child: AppIcon.filter(color: AppColors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // حبّات التصنيفات — تمرير أفقي يبدأ من اليمين
            SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: AppSpacing.screenPadding,
                children: [
                  CategoryChip(
                    label: 'الكل',
                    selected: _selectedCategory == null,
                    onTap: () {
                      setState(() => _selectedCategory = null);
                      _load();
                    },
                  ),
                  for (final c in _categories) ...[
                    const SizedBox(width: AppSpacing.md),
                    CategoryChip(
                      label: c['name_ar'] as String,
                      selected: _selectedCategory == c['id'],
                      onTap: () {
                        setState(() => _selectedCategory = c['id'] as String);
                        _load();
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'لا توجد منتجات!',
                          message: 'ما فيه منتجات في هذا التصنيف حاليًا.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 17,
                              mainAxisSpacing: 20,
                              childAspectRatio: 161 / 232,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (_, i) {
                              final p = _products[i];
                              final images = (p['product_images'] as List?) ?? [];
                              return ProductGridCard(
                                name: p['name_ar'] as String,
                                price: p['base_price'] as num,
                                compareAt: p['compare_at_price'] as num?,
                                imageUrl: images.isEmpty
                                    ? null
                                    : images.first['url'] as String,
                                onTap: () => Navigator.of(context)
                                    .pushNamed('/product', arguments: p['id']),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FiltersSheet(),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/notifications'),
      child: SizedBox(
        width: 24, height: 24,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AppIcon.bell(color: AppColors.ink),
            Positioned(
              right: -1, top: -1,
              child: Container(
                width: 9, height: 9,
                decoration: const BoxDecoration(
                    color: AppColors.accent, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================= درج الفلاتر
class FiltersSheet extends StatefulWidget {
  const FiltersSheet({super.key});

  @override
  State<FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<FiltersSheet> {
  RangeValues _price = const RangeValues(0, 2000);
  String _sort = 'الأحدث';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 64, height: 6,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text('الفلاتر', style: AppText.h4SemiBold),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 24),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.lg),

            Align(
              alignment: Alignment.centerRight,
              child: Text('نطاق السعر', style: AppText.b1SemiBold),
            ),
            RangeSlider(
              values: _price,
              min: 0, max: 2000, divisions: 40,
              activeColor: AppColors.accent,
              inactiveColor: AppColors.line,
              labels: RangeLabels(
                formatPrice(_price.start.round()),
                formatPrice(_price.end.round()),
              ),
              onChanged: (v) => setState(() => _price = v),
            ),
            const SizedBox(height: AppSpacing.lg),

            Align(
              alignment: Alignment.centerRight,
              child: Text('الترتيب حسب', style: AppText.b1SemiBold),
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                textDirection: TextDirection.rtl,
                children: ['الأحدث', 'الأقل سعرًا', 'الأعلى سعرًا', 'الأعلى تقييمًا']
                    .map((s) => CategoryChip(
                          label: s,
                          selected: _sort == s,
                          onTap: () => setState(() => _sort = s),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 32),
            PrimaryButton(
                label: 'تطبيق الفلاتر', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ==================================================================== البحث
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = StoreService();
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searched = false;

  final _recent = ['جينز', 'ملابس كاجوال', 'هودي', 'أحذية سوداء', 'تيشيرت بياقة V'];

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = []; _searched = false; });
      return;
    }
    final r = await _service.products(search: q);
    if (!mounted) return;
    setState(() { _results = r; _searched = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'بحث'),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.screenPadding,
              child: SearchField(controller: _controller, onChanged: _search),
            ),
            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: !_searched
                  ? _recentSearches()
                  : _results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          title: 'لا توجد نتائج!',
                          message: 'جرّب كلمة مشابهة أو أعم.')
                      : ListView.separated(
                          padding: AppSpacing.screenPadding,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) => const Divider(height: 32),
                          itemBuilder: (_, i) {
                            final p = _results[i];
                            final images = (p['product_images'] as List?) ?? [];
                            return _ResultRow(
                              name: p['name_ar'] as String,
                              price: p['base_price'] as num,
                              imageUrl: images.isEmpty
                                  ? null
                                  : images.first['url'] as String,
                              onTap: () => Navigator.of(context)
                                  .pushNamed('/product', arguments: p['id']),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentSearches() {
    return ListView(
      padding: AppSpacing.screenPadding,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Text('عمليات البحث الأخيرة', style: AppText.b1SemiBold),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(_recent.clear),
              child: Text('مسح الكل',
                  style: AppText.b2Medium.copyWith(color: AppColors.accent)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final term in _recent) ...[
          Row(
            textDirection: TextDirection.rtl,
            children: [
              GestureDetector(
                onTap: () {
                  _controller.text = term;
                  _search(term);
                },
                child: Text(term, style: AppText.b1Regular),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _recent.remove(term)),
                child: const Icon(Icons.cancel_outlined,
                    size: 22, color: AppColors.body),
              ),
            ],
          ),
          const Divider(height: 32),
        ],
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String name;
  final num price;
  final String? imageUrl;
  final VoidCallback onTap;

  const _ResultRow({
    required this.name,
    required this.price,
    required this.onTap,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 53, height: 53,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.base),
              image: imageUrl == null
                  ? null
                  : DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(name, style: AppText.b1SemiBold),
                const SizedBox(height: AppSpacing.xs),
                Text(formatPrice(price),
                    style: AppText.b3Medium.copyWith(color: AppColors.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================= المحفوظات
class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'المحفوظات'),
      body: const EmptyState(
        icon: Icons.favorite_border,
        title: 'لا توجد عناصر محفوظة!',
        message: 'ما عندك عناصر محفوظة. ارجع للرئيسية وأضف بعضها.',
      ),
    );
  }
}
