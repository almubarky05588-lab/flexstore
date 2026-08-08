import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../auth/auth_screens.dart';

/// حسابي — قائمة الأقسام مع فواصل رمادية عريضة كما في التصميم.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'حسابي'),
      body: ListView(
        children: [
          Padding(
            padding: AppSpacing.screenPadding,
            child: AccountRow(
                icon: Icons.inventory_2_outlined,
                label: 'طلباتي',
                onTap: () => Navigator.of(context).pushNamed('/orders')),
          ),
          const _ThickDivider(),

          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                AccountRow(
                    icon: Icons.badge_outlined,
                    label: 'بياناتي',
                    onTap: () => Navigator.of(context).pushNamed('/my-details')),
                const Divider(),
                AccountRow(
                    icon: Icons.home_outlined,
                    label: 'دفتر العناوين',
                    onTap: () => Navigator.of(context).pushNamed('/addresses')),
                const Divider(),
                AccountRow(
                    icon: Icons.credit_card,
                    label: 'طرق الدفع',
                    onTap: () =>
                        Navigator.of(context).pushNamed('/payment-methods')),
                const Divider(),
                AccountRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'الإشعارات',
                    onTap: () => Navigator.of(context)
                        .pushNamed('/notification-settings')),
              ],
            ),
          ),
          const _ThickDivider(),

          Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                AccountRow(
                    icon: Icons.help_outline,
                    label: 'الأسئلة الشائعة',
                    onTap: () => Navigator.of(context).pushNamed('/faqs')),
                const Divider(),
                AccountRow(
                    icon: Icons.headset_mic_outlined,
                    label: 'مركز المساعدة',
                    onTap: () => Navigator.of(context).pushNamed('/help')),
              ],
            ),
          ),
          const _ThickDivider(),

          Padding(
            padding: AppSpacing.screenPadding,
            child: AccountRow(
              icon: Icons.logout,
              label: 'تسجيل الخروج',
              danger: true,
              onTap: () => _confirmLogout(context),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78, height: 78,
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 42, color: AppColors.danger),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('تسجيل الخروج؟', style: AppText.h4SemiBold),
              const SizedBox(height: AppSpacing.sm),
              Text('متأكد أنك تبي تسجّل خروج؟',
                  style: AppText.b1Regular.copyWith(color: AppColors.body)),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'نعم، سجّل خروجي',
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.base)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('تراجع',
                      style: AppText.b1Medium.copyWith(color: AppColors.ink)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThickDivider extends StatelessWidget {
  const _ThickDivider();

  @override
  Widget build(BuildContext context) =>
      Container(height: 8, color: AppColors.surface);
}

// ================================================================== بياناتي
class MyDetailsScreen extends StatefulWidget {
  const MyDetailsScreen({super.key});

  @override
  State<MyDetailsScreen> createState() => _MyDetailsScreenState();
}

class _MyDetailsScreenState extends State<MyDetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _email.text = user?.email ?? '';
    _name.text = user?.userMetadata?['full_name'] as String? ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _name.text.trim(),
        'phone': _phone.text.trim(),
      }).eq('id', Supabase.instance.client.auth.currentUser!.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ بياناتك'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'بياناتي'),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          LabeledField(label: 'الاسم الكامل', hint: 'أدخل اسمك', controller: _name),
          const SizedBox(height: AppSpacing.lg),
          LabeledField(
              label: 'البريد الإلكتروني',
              hint: 'example@mail.com',
              controller: _email),
          const SizedBox(height: AppSpacing.lg),
          LabeledField(
            label: 'رقم الجوال',
            hint: '+966 55 123 4567',
            controller: _phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 32),
          PrimaryButton(label: 'حفظ التغييرات', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

// ============================================================== قائمة الإشعارات
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'الإشعارات', showBell: false),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('notifications')
            .select()
            .order('created_at', ascending: false)
            .then((r) => List<Map<String, dynamic>>.from(r)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'ما وصلك أي إشعار حتى الآن!',
              message: 'بننبّهك أول ما يصير شي مهم.',
            );
          }
          return ListView.separated(
            padding: AppSpacing.screenPadding,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (_, i) {
              final n = items[i];
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(n['title_ar'] as String, style: AppText.b1SemiBold),
                        if (n['body_ar'] != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(n['body_ar'] as String,
                              textAlign: TextAlign.right,
                              style: AppText.b3Regular
                                  .copyWith(color: AppColors.body)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.base),
                    ),
                    child: Icon(_iconFor(n['icon'] as String?),
                        size: 22, color: AppColors.accent),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  IconData _iconFor(String? icon) => switch (icon) {
        'check' => Icons.check_circle_outline,
        'warning' => Icons.warning_amber_rounded,
        'wallet' => Icons.account_balance_wallet_outlined,
        'card' => Icons.credit_card,
        'discount' => Icons.local_offer_outlined,
        'location' => Icons.location_on_outlined,
        _ => Icons.notifications_none_rounded,
      };
}

// ========================================================== إعدادات الإشعارات
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final _settings = <String, bool>{
    'الإشعارات العامة': true,
    'الصوت': true,
    'الاهتزاز': false,
    'عروض خاصة': true,
    'العروض والخصومات': false,
    'المدفوعات': true,
    'استرداد نقدي': true,
    'تحديثات التطبيق': true,
    'خدمة جديدة متاحة': false,
    'نصائح جديدة متاحة': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'الإشعارات', showBell: false),
      body: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: _settings.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final key = _settings.keys.elementAt(i);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Switch(
                  value: _settings[key]!,
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.accent,
                  onChanged: (v) => setState(() => _settings[key] = v),
                ),
                const Spacer(),
                Text(key, style: AppText.b1Regular),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================ الأسئلة الشائعة
class FaqsScreen extends StatefulWidget {
  const FaqsScreen({super.key});

  @override
  State<FaqsScreen> createState() => _FaqsScreenState();
}

class _FaqsScreenState extends State<FaqsScreen> {
  String _category = 'الكل';
  int? _expanded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'الأسئلة الشائعة'),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Supabase.instance.client
            .from('faqs')
            .select()
            .eq('is_active', true)
            .order('sort_order')
            .then((r) => List<Map<String, dynamic>>.from(r)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data!;
          final categories = [
            'الكل',
            ...{for (final f in all) f['category'] as String}
          ];
          final visible = _category == 'الكل'
              ? all
              : all.where((f) => f['category'] == _category).toList();

          return Column(
            children: [
              SizedBox(
                height: 54,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  padding: AppSpacing.screenPadding,
                  children: [
                    for (final c in categories) ...[
                      CategoryChip(
                        label: c,
                        selected: _category == c,
                        onTap: () => setState(() => _category = c),
                      ),
                      const SizedBox(width: AppSpacing.md),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Padding(
                padding: AppSpacing.screenPadding,
                child: SearchField(hint: 'ابحث في الأسئلة...'),
              ),
              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final f = visible[i];
                    final open = _expanded == i;
                    return GestureDetector(
                      onTap: () => setState(() => _expanded = open ? null : i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.base),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Icon(open ? Icons.expand_less : Icons.expand_more,
                                    size: 24, color: AppColors.body),
                                const Spacer(),
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    f['question_ar'] as String,
                                    textAlign: TextAlign.right,
                                    style: AppText.b1Medium,
                                  ),
                                ),
                              ],
                            ),
                            if (open) ...[
                              const SizedBox(height: 12),
                              Text(
                                f['answer_ar'] as String,
                                textAlign: TextAlign.right,
                                style: AppText.b2Regular
                                    .copyWith(color: AppColors.body),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================== مركز المساعدة
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _channels = [
    ('خدمة العملاء', Icons.headset_mic_outlined, '/support'),
    ('واتساب', Icons.chat_bubble_outline, null),
    ('الموقع الإلكتروني', Icons.language, null),
    ('فيسبوك', Icons.facebook, null),
    ('تويتر', Icons.alternate_email, null),
    ('إنستقرام', Icons.camera_alt_outlined, null),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'مركز المساعدة'),
      body: ListView.separated(
        padding: AppSpacing.screenPadding,
        itemCount: _channels.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) {
          final (label, icon, route) = _channels[i];
          return GestureDetector(
            onTap: route == null
                ? null
                : () => Navigator.of(context).pushNamed(route),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.base),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chevron_left, size: 22, color: AppColors.body),
                  const Spacer(),
                  Text(label, style: AppText.b1Regular),
                  const SizedBox(width: AppSpacing.lg),
                  Icon(icon, size: 22, color: AppColors.ink),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================== دردشة الدعم
class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _controller = TextEditingController();
  final _messages = <(String text, bool fromAgent, String time)>[
    ('مرحبًا، صباح الخير.', true, '10:41 م'),
    ('معك خدمة العملاء، كيف أقدر أساعدك؟', true, '10:41 م'),
    ('مرحبًا، عندي مشكلة في طلبي والدفع.', false, '10:50 م'),
    ('ممكن تساعدني؟', false, '10:50 م'),
    ('أكيد...', true, '10:51 م'),
    ('ممكن توضّح لي المشكلة اللي تواجهها؟ عشان أقدر أساعدك في حلها', true, '10:51 م'),
  ];

  void _send() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add((_controller.text.trim(), false, 'الآن'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'خدمة العملاء', showBell: false),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: AppSpacing.screenPadding,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final (text, fromAgent, time) = _messages[i];
                return Align(
                  alignment:
                      fromAgent ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 255),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: fromAgent ? AppColors.surface : AppColors.ink,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(AppRadius.base),
                        topRight: const Radius.circular(AppRadius.base),
                        bottomLeft: Radius.circular(fromAgent ? 4 : AppRadius.base),
                        bottomRight: Radius.circular(fromAgent ? AppRadius.base : 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          text,
                          textAlign: TextAlign.right,
                          style: AppText.b1Regular.copyWith(
                            color: fromAgent ? AppColors.ink : AppColors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(time,
                            style: AppText.b3Regular.copyWith(
                              color: fromAgent
                                  ? AppColors.body
                                  : AppColors.white.withValues(alpha: 0.7),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(25, 12, 25, 12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: kAccentGradient,
                        borderRadius: BorderRadius.circular(AppRadius.base),
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: AppColors.white, size: 22),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (_) => _send(),
                        decoration:
                            const InputDecoration(hintText: 'اكتب رسالتك...'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
