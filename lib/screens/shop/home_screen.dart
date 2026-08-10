import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../../widgets/app_icons.dart';
import '../main_shell.dart' show activeTabNotifier;

/// الرئيسية "اكتشف".
/// وضع شامل: شريط الأقسام الرئيسية.
/// وضع قسم واحد: تصنيفات ذلك القسم (بطاقات/نصوص) مكان شريط الأقسام.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _promoBanners = [];
  List<Map<String, dynamic>> _categoryBanners = [];
  Set<String> _favoriteIds = {};
  String? _selectedCategory;
  String? _selectedSub;
  String? _lockedCategory;
  bool _loading = true;

  bool get _isSingleMode => _lockedCategory != null;

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
    if (activeTabNotifier.value == 0 && mounted) _loadFavorites();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final locked = await _service.singleCategoryId();

      // في وضع القسم الواحد: نعرض تصنيفاته، وننتقي منتجات التصنيف المختار أو القسم كله
      final subs = locked != null ? await _service.subcategories(locked) : <Map<String, dynamic>>[];
      final target = _selectedSub ?? locked ?? _selectedCategory;

      final results = await Future.wait([
        _service.categories(),
        _service.products(categoryId: target),
        _service.favoriteIds(),
        _service.promoBanners(),
        _service.categoryBanners(),
      ]);
      if (!mounted) return;
      setState(() {
        _lockedCategory = locked;
        _subcategories = subs;
        _categories = results[0] as List<Map<String, dynamic>>;
        _products = results[1] as List<Map<String, dynamic>>;
        _favoriteIds = results[2] as Set<String>;
        _promoBanners = results[3] as List<Map<String, dynamic>>;
        _categoryBanners = results[4] as List<Map<String, dynamic>>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFavorites() async {
    final ids = await _service.favoriteIds();
    if (!mounted) return;
    setState(() => _favoriteIds = ids);
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

  void _selectSub(String? id) {
    setState(() => _selectedSub = id);
    _load();
  }

  void _onCategoryBannerTap(Map<String, dynamic> banner) {
    if (_isSingleMode) return;
    final categoryId = banner['category_id'] as String?;
    if (categoryId != null) {
      setState(() => _selectedCategory = categoryId);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSubs = _subcategories
        .where((s) => (s['shape'] as String? ?? 'circle') == 'text')
        .toList();
    final cardSubs = _subcategories
        .where((s) => (s['shape'] as String? ?? 'circle') != 'text')
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
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

                    Padding(
                      padding: AppSpacing.screenPadding,
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: SearchField(
                              readOnly: true,
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/search'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          GestureDetector(
                            onTap: () => _openFilters(context),
                            child: Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                gradient: kAccentGradient,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.base),
                                boxShadow: const [kAccentShadow],
                              ),
                              child: Center(
                                  child:
                                      AppIcon.filter(color: AppColors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (_promoBanners.isNotEmpty) ...[
                      _PromoCarousel(banners: _promoBanners),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // وضع شامل: شريط الأقسام الرئيسية
                    if (!_isSingleMode) ...[
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          padding: AppSpacing.screenPadding,
                          children: [
                            _smallChip('الكل', _selectedCategory == null, () {
                              setState(() => _selectedCategory = null);
                              _load();
                            }),
                            for (final c in _categories) ...[
                              const SizedBox(width: AppSpacing.sm),
                              _smallChip(
                                c['name_ar'] as String,
                                _selectedCategory == c['id'],
                                () {
                                  setState(() =>
                                      _selectedCategory = c['id'] as String);
                                  _load();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // ★ وضع القسم الواحد: تصنيفات القسم مكان شريط الأقسام ★
                    if (_isSingleMode && _subcategories.isNotEmpty) ...[
                      if (textSubs.isNotEmpty) ...[
                        SizedBox(
                          height: 44,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            padding: AppSpacing.screenPadding,
                            children: [
                              _smallChip('الكل', _selectedSub == null,
                                  () => _selectSub(null)),
                              for (final s in textSubs) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _smallChip(
                                  s['name_ar'] as String,
                                  _selectedSub == s['id'],
                                  () => _selectSub(s['id'] as String),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (cardSubs.isNotEmpty) ...[
                        Padding(
                          padding: AppSpacing.screenPadding,
                          child: _SubcategoryRow(
                            items: cardSubs,
                            selectedId: _selectedSub,
                            onSelect: _selectSub,
                            showAllTile: textSubs.isEmpty,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],

                    if (_categoryBanners.isNotEmpty) ...[
                      Padding(
                        padding: AppSpacing.screenPadding,
                        child: Column(
                          children: [
                            for (final b in _categoryBanners) ...[
                              _CategoryBannerCard(
                                banner: b,
                                onTap: () => _onCategoryBannerTap(b),
                              ),
                              const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    Padding(
                      padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                      child: _products.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: EmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: 'لا توجد منتجات!',
                                message: 'ما فيه منتجات هنا حاليًا.',
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                                final images =
                                    (p['product_images'] as List?) ?? [];
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
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _smallChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? null : AppColors.white,
          gradient: selected ? kAccentGradient : null,
          borderRadius: BorderRadius.circular(AppRadius.base),
          border:
              Border.all(color: selected ? Colors.transparent : AppColors.line),
        ),
        child: Text(
          label,
          style: AppText.b2Medium.copyWith(
            color: selected ? AppColors.white : AppColors.ink,
          ),
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

/// صف أفقي لبطاقات التصنيفات (دائرية/مربعة) بالصور.
class _SubcategoryRow extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final bool showAllTile;

  const _SubcategoryRow({
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.showAllTile = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 106,
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: EdgeInsets.zero,
        children: [
          if (showAllTile) ...[
            _tile(
              label: 'الكل',
              imageUrl: null,
              circle: true,
              selected: selectedId == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: 12),
          ],
          for (final s in items) ...[
            _tile(
              label: s['name_ar'] as String,
              imageUrl: s['image_url'] as String?,
              circle: (s['shape'] as String? ?? 'circle') == 'circle',
              selected: selectedId == s['id'],
              onTap: () => onSelect(s['id'] as String),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _tile({
    required String label,
    required String? imageUrl,
    required bool circle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const size = 72.0;
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
                              Icon(Icons.apps, size: 24, color: AppColors.body))
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_outlined,
                                size: 20, color: AppColors.body),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
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

/// الكاروسيل الإعلاني — يتنقّل تلقائيًا كل 4 ثوانٍ.
class _PromoCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const _PromoCarousel({required this.banners});

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_page + 1) % widget.banners.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: widget.banners.length,
            itemBuilder: (_, i) {
              final b = widget.banners[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.base),
                  child: Container(
                    color: AppColors.surface,
                    child: Image.network(
                      b['image_url'] as String,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(b['title_ar'] as String? ?? '',
                            style: AppText.b1SemiBold),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _page == i ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.accent : AppColors.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CategoryBannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final VoidCallback onTap;

  const _CategoryBannerCard({required this.banner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.base),
        child: SizedBox(
          height: 110,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                color: AppColors.surface,
                child: Image.network(
                  banner['image_url'] as String,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
              if (banner['title_ar'] != null)
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppRadius.heartSmall),
                    ),
                    child: Text(banner['title_ar'] as String,
                        style: AppText.b1SemiBold),
                  ),
                ),
            ],
          ),
        ),
      ),
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
                    color: AppColors.alert, shape: BoxShape.circle),
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
class SavedItemsScreen extends StatefulWidget {
  const SavedItemsScreen({super.key});

  @override
  State<SavedItemsScreen> createState() => _SavedItemsScreenState();
}

class _SavedItemsScreenState extends State<SavedItemsScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

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
    if (activeTabNotifier.value == 2 && mounted) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _service.favorites();
      if (!mounted) return;
      setState(() => _items = items);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _remove(String productId) async {
    setState(() =>
        _items.removeWhere((f) => (f['products'] as Map)['id'] == productId));
    await _service.toggleFavorite(productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'المحفوظات'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.favorite_border,
                  title: 'لا توجد عناصر محفوظة!',
                  message: 'ما عندك عناصر محفوظة. ارجع للرئيسية وأضف بعضها.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(25, 8, 25, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 16,
                      childAspectRatio: 161 / 210,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final p = _items[i]['products'] as Map<String, dynamic>;
                      final images = (p['product_images'] as List?) ?? [];
                      final id = p['id'] as String;
                      return ProductGridCard(
                        name: p['name_ar'] as String,
                        price: p['base_price'] as num,
                        compareAt: p['compare_at_price'] as num?,
                        imageUrl: images.isEmpty
                            ? null
                            : images.first['url'] as String,
                        isFavorite: true,
                        onFavorite: () => _remove(id),
                        onTap: () => Navigator.of(context)
                            .pushNamed('/product', arguments: id),
                      );
                    },
                  ),
                ),
    );
  }
}
