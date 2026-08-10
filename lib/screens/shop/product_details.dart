import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../../widgets/option_selector.dart';
import '../../widgets/app_icons.dart';

/// تفاصيل المنتج — الشاشة التي يظهر فيها النظام المرن بوضوح.
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _service = StoreService();
  Product? _product;
  Map<String, String> _selected = {};
  int _qty = 1;
  bool _loading = true;
  bool _adding = false;
  bool _favorite = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_product == null) {
      final id = ModalRoute.of(context)!.settings.arguments as String;
      _load(id);
    }
  }

  Future<void> _load(String id) async {
    try {
      final results = await Future.wait([
        _service.product(id),
        _service.favoriteIds(),
      ]);
      final p = results[0] as Product;
      final favs = results[1] as Set<String>;
      if (!mounted) return;
      setState(() {
        _product = p;
        _favorite = favs.contains(id);
        for (final t in p.optionTypes) {
          final first = t.values.firstWhere(
            (v) => p.isValueAvailable(v.id, {}),
            orElse: () => t.values.first,
          );
          _selected[t.id] = first.id;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Variant? get _variant => _product?.matchVariant(_selected.values.toSet());

  double get _price => _variant?.price ?? _product?.basePrice ?? 0;

  Future<void> _toggleFavorite() async {
    final p = _product;
    if (p == null) return;
    setState(() => _favorite = !_favorite);
    try {
      await _service.toggleFavorite(p.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _favorite = !_favorite);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر حفظ المفضلة، حاول مجددًا'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addToCart() async {
    final v = _variant;
    if (v == null) return;

    setState(() => _adding = true);
    try {
      await _service.addToCart(v.id, quantity: _qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت الإضافة للسلة'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: AppHeader(title: 'التفاصيل'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final p = _product!;
    final v = _variant;
    final outOfStock = v == null || !v.inStock;
    final maxQty = v?.stock ?? 99;

    return Scaffold(
      appBar: const AppHeader(title: 'التفاصيل'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: AppSpacing.screenPadding,
              child: AspectRatio(
                aspectRatio: 341 / 368.534,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.base),
                        image: p.images.isEmpty
                            ? null
                            : DecorationImage(
                                image: NetworkImage(v?.imageUrl ?? p.images.first),
                                fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 16, left: 16,
                      child: GestureDetector(
                        onTap: _toggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(11.294),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius:
                                BorderRadius.circular(AppRadius.heartLarge),
                            boxShadow: const [kHeartShadowLarge],
                          ),
                          child: AppIcon.heart(
                            size: 25.412,
                            color: _favorite ? AppColors.accent : AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(p.name, style: AppText.h3SemiBold),
                  const SizedBox(height: 13),

                  GestureDetector(
                    onTap: () => Navigator.of(context)
                        .pushNamed('/reviews', arguments: p.id),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${p.ratingAvg.toStringAsFixed(1)}/5 (${p.ratingCount} تقييمًا)',
                          style: AppText.b1Medium.copyWith(
                            color: AppColors.ink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AppIcon.star(),
                      ],
                    ),
                  ),

                  if (p.description != null) ...[
                    const SizedBox(height: 13),
                    Text(
                      p.description!,
                      textAlign: TextAlign.right,
                      style: AppText.b1Regular.copyWith(color: AppColors.body),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),

                  OptionSelector(
                    product: p,
                    selected: _selected,
                    onChanged: (next) => setState(() {
                      _selected = next;
                      _qty = 1;
                    }),
                  ),

                  // محدّد الكمية — يظهر لكل المنتجات ما عدا الرقمية
                  if (!p.isDigital && !outOfStock) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text('الكمية', style: AppText.b1SemiBold),
                        const Spacer(),
                        _QtyStepper(
                          quantity: _qty,
                          max: maxQty,
                          onChanged: (q) => setState(() => _qty = q),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  if (p.isDigital)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.base),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'منتج رقمي — يصلك على بريدك الإلكتروني فور إتمام الدفع، بدون شحن.',
                              textAlign: TextAlign.right,
                              style: AppText.b2Regular,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Icon(Icons.bolt_rounded,
                              size: 22, color: AppColors.accent),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
            child: Row(
              children: [
                SizedBox(
                  width: 215,
                  child: PrimaryButton(
                    label: outOfStock ? 'غير متوفر' : 'أضف للسلة',
                    icon: outOfStock ? null : Icons.shopping_bag_outlined,
                    loading: _adding,
                    onPressed: outOfStock ? null : _addToCart,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('السعر',
                        style: AppText.b1Regular.copyWith(color: AppColors.body)),
                    Text(formatPrice(_price * _qty), style: AppText.h3SemiBold),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// محدّد الكمية — زرّان مربّعان (+ / −) ورقم بينهما.
class _QtyStepper extends StatelessWidget {
  final int quantity;
  final int max;
  final ValueChanged<int> onChanged;

  const _QtyStepper({
    required this.quantity,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        _box(Icons.remove, quantity > 1 ? () => onChanged(quantity - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('$quantity', style: AppText.b1SemiBold),
        ),
        _box(Icons.add, quantity < max ? () => onChanged(quantity + 1) : null),
      ],
    );
  }

  Widget _box(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.heartSmall),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon,
              size: 18, color: onTap == null ? AppColors.line : AppColors.ink),
        ),
      );
}

// ================================================================== التقييمات
class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const distribution = [0.78, 0.47, 0.21, 0.11, 0.05];

    return Scaffold(
      appBar: const AppHeader(title: 'التقييمات'),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: LinearProgressIndicator(
                                value: distribution[i],
                                minHeight: 5,
                                backgroundColor: AppColors.line,
                                valueColor:
                                    const AlwaysStoppedAnimation(AppColors.accent),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Row(
                            children: List.generate(
                              5 - i,
                              (_) => AppIcon.star(size: 15),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('4.0', style: AppText.h3SemiBold.copyWith(fontSize: 42)),
                  Text('1034 تقييم',
                      style: AppText.b2Regular.copyWith(color: AppColors.body)),
                ],
              ),
            ],
          ),

          const Divider(height: 40),

          Row(
            children: [
              const Icon(Icons.expand_more, size: 18, color: AppColors.body),
              Text('الأكثر صلة',
                  style: AppText.b3Regular.copyWith(color: AppColors.body)),
              const Spacer(),
              Text('45 مراجعة', style: AppText.b1SemiBold),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          _review('المنتج ممتاز، ابني عجبه مرة ويلبسه كل يوم.', 'سعود العتيبي', 'قبل 6 أيام', 5),
          _review('البائع سريع جدًا في الشحن، اشتريته ووصلني خلال يوم واحد!', 'فهد القحطاني', 'قبل أسبوع', 5),
          _review('اشتريته للتو والجودة ممتازة! أنصح فيه بشدة!', 'ماجد الشمري', 'قبل أسبوعين', 4),
        ],
      ),
    );
  }

  Widget _review(String text, String author, String when, int stars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: List.generate(
            5,
            (i) => Opacity(
              opacity: i < stars ? 1 : 0.25,
              child: AppIcon.star(size: 17),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(text, textAlign: TextAlign.right, style: AppText.b1Regular),
        const SizedBox(height: AppSpacing.lg),
        Text('$author • $when',
            style: AppText.b3Regular.copyWith(color: AppColors.body)),
        const Divider(height: 40),
      ],
    );
  }
}
