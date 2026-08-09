import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../main_shell.dart' show activeTabNotifier;

/// السلة — بطاقات المنتجات مع عدّاد الكمية وملخّص الحساب.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _settings = {};
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
    // السلة = تبويب 3: أعد التحميل كلما فُتح
    if (activeTabNotifier.value == 3 && mounted) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([_service.cart(), _service.storeSettings()]);
      if (!mounted) return;
      setState(() {
        _items = results[0] as List<Map<String, dynamic>>;
        _settings = results[1] as Map<String, dynamic>;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, item) {
        final v = item['variants'] as Map<String, dynamic>;
        final p = v['products'] as Map<String, dynamic>;
        final price = (v['price'] ?? p['base_price']) as num;
        return sum + price * (item['quantity'] as int);
      });

  bool get _needsShipping => _items.any((item) {
        final v = item['variants'] as Map<String, dynamic>;
        final p = v['products'] as Map<String, dynamic>;
        return p['kind'] == 'physical';
      });

  double get _tax =>
      _subtotal * ((_settings['tax_rate'] as num?)?.toDouble() ?? 0.15);

  double get _shipping => !_needsShipping
      ? 0
      : ((_settings['shipping_flat_fee'] as num?)?.toDouble() ?? 0);

  double get _total => _subtotal + _tax + _shipping;

  Future<void> _changeQuantity(String id, int quantity) async {
    await _service.updateCartQuantity(id, quantity);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'سلّتي'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'سلّتك فارغة!',
                  message: 'لما تضيف منتجات بتظهر هنا.')
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(25, 8, 25, 8),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.lg),
                        itemBuilder: (_, i) => _CartCard(
                          item: _items[i],
                          onQuantity: _changeQuantity,
                        ),
                      ),
                    ),
                    _summary(),
                  ],
                ),
    );
  }

  Widget _summary() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SummaryRow(label: 'المجموع الفرعي', value: _subtotal),
            const SizedBox(height: AppSpacing.lg),
            SummaryRow(label: 'الضريبة (%)', value: _tax),
            const SizedBox(height: AppSpacing.lg),
            SummaryRow(label: 'رسوم الشحن', value: _shipping),
            const Divider(height: 32),
            SummaryRow(label: 'الإجمالي', value: _total, emphasized: true),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'إتمام الشراء',
              onPressed: () => Navigator.of(context).pushNamed('/checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

/// صف في ملخّص الحساب — الاسم يمينًا والقيمة يسارًا.
class SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = emphasized
        ? AppText.b1SemiBold
        : AppText.b1Regular.copyWith(color: AppColors.body);
    final valueStyle = emphasized ? AppText.b1SemiBold : AppText.b1Medium;

    return Row(
      children: [
        Text(formatPrice(value), style: valueStyle),
        const Spacer(),
        Text(label, style: labelStyle),
      ],
    );
  }
}

class _CartCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Future<void> Function(String id, int quantity) onQuantity;

  const _CartCard({required this.item, required this.onQuantity});

  @override
  Widget build(BuildContext context) {
    final v = item['variants'] as Map<String, dynamic>;
    final p = v['products'] as Map<String, dynamic>;
    final price = (v['price'] ?? p['base_price']) as num;
    final quantity = item['quantity'] as int;

    // وصف الخيارات: "مقاس M" أو "الحجم 100 مل"
    final optionValues = (v['variant_option_values'] as List?) ?? [];
    final optionsLabel = optionValues.map((o) {
      final ov = o['option_values'] as Map<String, dynamic>;
      final ot = ov['option_types'] as Map<String, dynamic>;
      return '${ot['name_ar']} ${ov['value_ar']}';
    }).join(' • ');

    return Container(
      height: 107,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: AppColors.line),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // زر الحذف على أقصى اليسار
          GestureDetector(
            onTap: () => onQuantity(item['id'] as String, 0),
            child: const Icon(Icons.delete_outline,
                size: 22, color: AppColors.danger),
          ),
          const SizedBox(width: AppSpacing.sm),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p['name_ar'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.b1SemiBold),
                if (optionsLabel.isNotEmpty)
                  Text(optionsLabel,
                      style: AppText.b3Regular.copyWith(color: AppColors.body)),

                Row(
                  children: [
                    _QuantityStepper(
                      quantity: quantity,
                      onChanged: (q) => onQuantity(item['id'] as String, q),
                    ),
                    const Spacer(),
                    Text(formatPrice(price), style: AppText.b1SemiBold),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),

          Container(
            width: 83, height: 79,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.base),
              image: v['image_url'] == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(v['image_url'] as String),
                      fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;

  const _QuantityStepper({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _box(Icons.add, () => onChanged(quantity + 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$quantity', style: AppText.b1SemiBold),
        ),
        _box(Icons.remove, quantity > 1 ? () => onChanged(quantity - 1) : null),
      ],
    );
  }

  Widget _box(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.heartSmall),
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon,
              size: 16, color: onTap == null ? AppColors.line : AppColors.ink),
        ),
      );
}

// ================================================================ إتمام الشراء
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _service = StoreService();
  String _payMethod = 'card';
  bool _placing = false;
  Map<String, dynamic>? _address;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.cart(),
      _service.storeSettings(),
      _service.addresses(),
    ]);
    if (!mounted) return;
    setState(() {
      _items = results[0] as List<Map<String, dynamic>>;
      _settings = results[1] as Map<String, dynamic>;
      final addresses = results[2] as List<Map<String, dynamic>>;
      _address = addresses.isEmpty ? null : addresses.first;
    });
  }

  double get _subtotal => _items.fold(0.0, (sum, item) {
        final v = item['variants'] as Map<String, dynamic>;
        final p = v['products'] as Map<String, dynamic>;
        return sum +
            ((v['price'] ?? p['base_price']) as num) * (item['quantity'] as int);
      });

  bool get _needsShipping => _items.any((item) =>
      ((item['variants'] as Map)['products'] as Map)['kind'] == 'physical');

  double get _tax => _subtotal * ((_settings['tax_rate'] as num?)?.toDouble() ?? 0.15);
  double get _shipping =>
      !_needsShipping ? 0 : ((_settings['shipping_flat_fee'] as num?)?.toDouble() ?? 0);
  double get _total => _subtotal + _tax + _shipping;

  Future<void> _placeOrder() async {
    setState(() => _placing = true);
    try {
      final orderId = await _service.placeOrder(
        addressId: _address?['id'] as String?,
        payMethod: _payMethod,
      );

      // الطلبات الرقمية تُسلَّم فور تأكيد الدفع
      final hasDigital = _items.any((item) =>
          ((item['variants'] as Map)['products'] as Map)['kind'] == 'digital');
      if (hasDigital) await _service.fulfillDigital(orderId);

      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'مبروك!',
        message: hasDigital
            ? 'تم تنفيذ طلبك، وأرسلنا منتجك الرقمي على بريدك.'
            : 'تم تنفيذ طلبك.',
        buttonLabel: 'تتبّع الطلب',
        onDone: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/orders', (r) => r.settings.name == '/home'),
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
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'إتمام الشراء'),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // عنوان التوصيل — يُخفى تمامًا للطلبات الرقمية
          if (_needsShipping) ...[
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/addresses'),
                  child: Text('تغيير',
                      style: AppText.b2Regular.copyWith(
                        color: AppColors.ink,
                        decoration: TextDecoration.underline,
                      )),
                ),
                const Spacer(),
                Text('عنوان التوصيل', style: AppText.b1SemiBold),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_address?['label'] as String? ?? 'أضف عنوانًا',
                          style: AppText.b1SemiBold),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _address?['full_text'] as String? ?? 'لم تضف عنوانًا بعد',
                        textAlign: TextAlign.right,
                        style: AppText.b2Regular.copyWith(color: AppColors.body),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                const Icon(Icons.location_on_outlined, size: 24),
              ],
            ),
            const Divider(height: 40),
          ],

          // طريقة الدفع
          Align(
            alignment: Alignment.centerRight,
            child: Text('طريقة الدفع', style: AppText.b1SemiBold),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _payChip('card', 'بطاقة', Icons.credit_card),
              const SizedBox(width: AppSpacing.sm),
              _payChip('cash', 'نقدًا', Icons.payments_outlined),
              const SizedBox(width: AppSpacing.sm),
              _payChip('apple_pay', 'Pay', Icons.apple),
            ],
          ),

          if (_payMethod == 'card') ...[
            const SizedBox(height: AppSpacing.lg),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed('/payment-methods'),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.base),
                  border: Border.all(color: AppColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined, size: 22, color: AppColors.body),
                    const Spacer(),
                    Text('**** **** **** 2512', style: AppText.b1Regular),
                    const SizedBox(width: AppSpacing.lg),
                    Text('VISA',
                        style: AppText.b1SemiBold.copyWith(
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF1A1F71),
                        )),
                  ],
                ),
              ),
            ),
          ],

          const Divider(height: 40),

          Align(
            alignment: Alignment.centerRight,
            child: Text('ملخّص الطلب', style: AppText.b1SemiBold),
          ),
          const SizedBox(height: AppSpacing.lg),
          SummaryRow(label: 'المجموع الفرعي', value: _subtotal),
          const SizedBox(height: AppSpacing.lg),
          SummaryRow(label: 'الضريبة (%)', value: _tax),
          const SizedBox(height: AppSpacing.lg),
          SummaryRow(label: 'رسوم الشحن', value: _shipping),
          const Divider(height: 32),
          SummaryRow(label: 'الإجمالي', value: _total, emphasized: true),

          const SizedBox(height: AppSpacing.xl),

          // كود الخصم
          Row(
            children: [
              SizedBox(
                width: 84,
                child: PrimaryButton(label: 'إضافة', onPressed: () {}),
              ),
              const SizedBox(width: AppSpacing.md),
              const Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'أدخل كود الخصم',
                      suffixIcon: Icon(Icons.local_offer_outlined,
                          size: 22, color: AppColors.body),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),
          PrimaryButton(
            label: 'تأكيد الطلب',
            loading: _placing,
            onPressed: _items.isEmpty ? null : _placeOrder,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _payChip(String value, String label, IconData icon) {
    final selected = _payMethod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _payMethod = value),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.base),
            border: Border.all(color: selected ? AppColors.ink : AppColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: AppText.b2Medium.copyWith(
                    color: selected ? AppColors.white : AppColors.ink,
                  )),
              const SizedBox(width: 6),
              Icon(icon,
                  size: 18, color: selected ? AppColors.white : AppColors.ink),
            ],
          ),
        ),
      ),
    );
  }
}
