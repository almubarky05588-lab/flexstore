import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/store_service.dart';
import '../../widgets/common.dart';
import '../auth/auth_screens.dart' show LabeledField;

/// شاشة إضافة عنوان جديد لدفتر العناوين.
class NewAddressScreen extends StatefulWidget {
  const NewAddressScreen({super.key});

  @override
  State<NewAddressScreen> createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<NewAddressScreen> {
  final _service = StoreService();
  final _fullText = TextEditingController();
  final _city = TextEditingController();

  String _label = 'الرئيسية';
  bool _isDefault = false;
  bool _saving = false;
  String? _error;

  static const _labels = ['الرئيسية', 'المنزل', 'العمل', 'أخرى'];

  @override
  void dispose() {
    _fullText.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_fullText.text.trim().isEmpty) {
      setState(() => _error = 'اكتب تفاصيل العنوان');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.addAddress(
        label: _label,
        fullText: _fullText.text.trim(),
        city: _city.text.trim(),
        isDefault: _isDefault,
      );
      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'تمت الإضافة!',
        message: 'تم حفظ عنوانك بنجاح.',
        buttonLabel: 'تم',
        onDone: () => Navigator.of(context).pop(true),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'عنوان جديد', showBell: false),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // نوع العنوان
          Align(
            alignment: Alignment.centerRight,
            child: Text('نوع العنوان', style: AppText.b1Medium),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              textDirection: TextDirection.rtl,
              children: _labels
                  .map((l) => CategoryChip(
                        label: l,
                        selected: _label == l,
                        onTap: () => setState(() => _label = l),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          LabeledField(
            label: 'العنوان بالتفصيل',
            hint: 'الحي، الشارع، رقم المبنى',
            controller: _fullText,
            error: _error,
          ),
          const SizedBox(height: AppSpacing.lg),

          LabeledField(
            label: 'المدينة',
            hint: 'الرياض، جدة، خميس مشيط...',
            controller: _city,
          ),
          const SizedBox(height: AppSpacing.lg),

          // اجعله الافتراضي
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text('اجعله العنوان الافتراضي', style: AppText.b1Regular),
              const Spacer(),
              Switch(
                value: _isDefault,
                activeThumbColor: AppColors.white,
                activeTrackColor: AppColors.accent,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
            ],
          ),

          const SizedBox(height: 32),
          PrimaryButton(
            label: 'حفظ العنوان',
            loading: _saving,
            onPressed: _save,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
