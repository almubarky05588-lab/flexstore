import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';

/// طلباتي — تبويبان: الجارية والمكتملة.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = StoreService();
  bool _ongoing = true;
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.orders(ongoing: _ongoing);
      if (mounted) setState(() => _orders = r);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'طلباتي'),
      body: Column(
        children: [
          // مبدّل التبويبات
          Padding(
            padding: AppSpacing.screenPadding,
            child: Container(
              height: 54,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.base),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  _tab('الجارية', _ongoing, () {
                    setState(() => _ongoing = true);
                    _load();
                  }),
                  _tab('المكتملة', !_ongoing, () {
                    setState(() => _ongoing = false);
                    _load();
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? EmptyState(
                        icon: Icons.inventory_2_outlined,
                        title: _ongoing
                            ? 'لا توجد طلبات جارية!'
                            : 'لا توجد طلبات مكتملة!',
                        message: _ongoing
                            ? 'ما عندك أي طلبات جارية حاليًا.'
                            : 'ما عندك طلبات مكتملة بعد.')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 24),
                        itemCount: _orders.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (_, i) => _OrderCard(
                          order: _orders[i],
                          ongoing: _ongoing,
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.heartSmall),
          ),
          child: Center(
            child: Text(
              label,
              style: selected
                  ? AppText.b1SemiBold
                  : AppText.b1Regular.copyWith(color: AppColors.body),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool ongoing;

  const _OrderCard({required this.order, required this.ongoing});

  static const _statusLabels = {
    'pending': 'قيد التجهيز',
    'processing': 'قيد التجهيز',
    'shipped': 'في الطريق',
    'delivered': 'تم التوصيل',
    'cancelled': 'ملغي',
    'refunded': 'مسترجع',
  };

  @override
  Widget build(BuildContext context) {
    final items = (order['order_items'] as List?) ?? [];
    final first = items.isEmpty ? null : items.first as Map<String, dynamic>;
    final options = (first?['options_snapshot'] as Map?) ?? {};
    final optionsLabel =
        options.entries.map((e) => '${e.key} ${e.value}').join(' • ');
    final status = order['status'] as String;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.base),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    _statusPill(status),
                    const Spacer(),
                    Expanded(
                      flex: 3,
                      child: Text(
                        first?['name_snapshot'] as String? ?? 'طلب',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.b1SemiBold,
                      ),
                    ),
                  ],
                ),
                if (optionsLabel.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(optionsLabel,
                      style: AppText.b3Regular.copyWith(color: AppColors.body)),
                ],
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    SizedBox(
                      height: 32,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          side: const BorderSide(color: AppColors.line),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.heartSmall)),
                        ),
                        onPressed: () => Navigator.of(context).pushNamed(
                            ongoing ? '/track' : '/reviews',
                            arguments: order['id']),
                        child: Text(
                          ongoing ? 'تتبّع الطلب' : 'أضف تقييمًا',
                          style: AppText.b3Medium.copyWith(color: AppColors.ink),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(formatPrice(order['total'] as num),
                        style: AppText.b1SemiBold),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final delivered = status == 'delivered';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (delivered ? AppColors.success : AppColors.accent)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.heartSmall),
      ),
      child: Text(
        _statusLabels[status] ?? status,
        style: AppText.b3Medium.copyWith(
          color: delivered ? AppColors.success : AppColors.accent,
        ),
      ),
    );
  }
}

// ============================================================== تتبّع الطلب
class TrackOrderScreen extends StatelessWidget {
  const TrackOrderScreen({super.key});

  static const _steps = [
    ('قيد التجهيز', 'طريق الملك فهد، حي الملقا، الرياض', true),
    ('تم الاستلام', 'شارع التحلية، حي الروضة، جدة', true),
    ('في الطريق', 'شارع الأربعين، حي الشاطئ، جدة', false),
    ('تم التوصيل', 'شارع الأمير سلطان، حي العليا، الرياض 12211', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'تتبّع الطلب'),
      body: Stack(
        children: [
          // مكان الخريطة — تُستبدل بـ GoogleMap عند إضافة المفتاح
          Container(
            color: AppColors.surface,
            child: const Center(
              child: Icon(Icons.map_outlined, size: 64, color: AppColors.primary200),
            ),
          ),

          // درج حالة الطلب
          DraggableScrollableSheet(
            initialChildSize: 0.52,
            minChildSize: 0.52,
            maxChildSize: 0.85,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(25, 10, 25, 24),
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
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 24),
                      ),
                      const Spacer(),
                      Text('حالة الطلب', style: AppText.h4SemiBold),
                    ],
                  ),
                  const Divider(height: 32),

                  for (var i = 0; i < _steps.length; i++)
                    _stepRow(_steps[i], isLast: i == _steps.length - 1),

                  const Divider(height: 32),

                  // بيانات المندوب
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.base),
                        ),
                        child: const Icon(Icons.phone,
                            size: 22, color: AppColors.accent),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('أحمد الزهراني', style: AppText.b1SemiBold),
                            Text('مندوب التوصيل',
                                style: AppText.b2Regular
                                    .copyWith(color: AppColors.body)),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Container(
                        width: 48, height: 48,
                        decoration: const BoxDecoration(
                            color: AppColors.surface, shape: BoxShape.circle),
                        child: const Icon(Icons.person, color: AppColors.body),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepRow((String, String, bool) step, {required bool isLast}) {
    final (title, location, done) = step;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // الخط الرأسي والدائرة على اليسار في RTL
          Column(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.accent : AppColors.white,
                  border: Border.all(
                      color: done ? AppColors.accent : AppColors.line, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: AppColors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.accent : AppColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(title,
                      style: AppText.b1SemiBold.copyWith(
                        color: done ? AppColors.ink : AppColors.body,
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  Text(location,
                      textAlign: TextAlign.right,
                      style: AppText.b3Regular.copyWith(color: AppColors.body)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================ دفتر العناوين
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _service = StoreService();
  List<Map<String, dynamic>> _addresses = [];
  String? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await _service.addresses();
    if (!mounted) return;
    setState(() {
      _addresses = r;
      _selected = r.isEmpty ? null : r.first['id'] as String;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'العنوان'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('العناوين المحفوظة', style: AppText.b1SemiBold),
            ),
          ),
          Expanded(
            child: _addresses.isEmpty
                ? const EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'لا توجد عناوين!',
                    message: 'أضف عنوانك الأول ليصلك طلبك.')
                : ListView.separated(
                    padding: AppSpacing.screenPadding,
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final a = _addresses[i];
                      final selected = _selected == a['id'];
                      return GestureDetector(
                        onTap: () => setState(() => _selected = a['id'] as String),
                        child: Container(
                          height: 76,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.base),
                            border: Border.all(
                              color: selected ? AppColors.accent : AppColors.line,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                size: 20,
                                color: selected ? AppColors.accent : AppColors.line,
                              ),
                              const Spacer(),
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(a['label'] as String,
                                        style: AppText.b1SemiBold),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      a['full_text'] as String,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: AppText.b3Regular
                                          .copyWith(color: AppColors.body),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              const Icon(Icons.location_on_outlined, size: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.base)),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/new-address'),
                    child: Text('إضافة عنوان جديد',
                        style: AppText.b1Medium.copyWith(color: AppColors.ink)),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                      label: 'تطبيق', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================== طرق الدفع
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selected = 0;

  static const _cards = [
    ('**** **** **** 2512', 'VISA'),
    ('**** **** **** 5421', 'MC'),
    ('**** **** **** 8834', 'VISA'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'طريقة الدفع'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('البطاقات المحفوظة', style: AppText.b1SemiBold),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: AppSpacing.screenPadding,
              itemCount: _cards.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final (number, brand) = _cards[i];
                final selected = _selected == i;
                return GestureDetector(
                  onTap: () => setState(() => _selected = i),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.base),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.line,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: selected ? AppColors.accent : AppColors.line,
                        ),
                        const Spacer(),
                        Text(number, style: AppText.b1Regular),
                        const SizedBox(width: AppSpacing.lg),
                        Text(brand,
                            style: AppText.b2Medium.copyWith(
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF1A1F71),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 16, 25, 16),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.base)),
                    ),
                    onPressed: () => Navigator.of(context).pushNamed('/new-card'),
                    child: Text('إضافة بطاقة جديدة',
                        style: AppText.b1Medium.copyWith(color: AppColors.ink)),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                      label: 'تطبيق', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
