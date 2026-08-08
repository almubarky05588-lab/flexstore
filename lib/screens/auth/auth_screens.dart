import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';

/// حقل نصي بعنوان فوقه — يطابق مكوّن Text Field في فِقما.
class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscure;
  final String? error;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final Widget? suffix;

  const LabeledField({
    super.key,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.error,
    this.keyboardType,
    this.controller,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, textAlign: TextAlign.right, style: AppText.b1Medium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

/// أزرار الدخول عبر Google و Facebook.
class SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.base),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 12),
            Text(label, style: AppText.b1Medium),
          ],
        ),
      ),
    );
  }
}

/// الفاصل "أو" بين النموذج وأزرار التواصل.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('أو', style: AppText.b1Regular.copyWith(color: AppColors.body)),
        ),
        const Expanded(child: Divider(color: AppColors.line)),
      ],
    );
  }
}

// ===================================================================== إنشاء حساب
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _emailError;

  Future<void> _submit() async {
    setState(() { _loading = true; _emailError = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        data: {'full_name': _name.text.trim()},
      );
      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'مرحبًا بك!',
        message: 'تم إنشاء حسابك بنجاح.',
        buttonLabel: 'ابدأ التسوّق',
        onDone: () => Navigator.of(context).pushReplacementNamed('/home'),
      );
    } on AuthException catch (e) {
      setState(() => _emailError = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('إنشاء حساب',
                  textAlign: TextAlign.center, style: AppText.h3SemiBold),
              const SizedBox(height: AppSpacing.sm),
              Text('لننشئ حسابك.',
                  textAlign: TextAlign.center,
                  style: AppText.b1Regular.copyWith(color: AppColors.body)),
              const SizedBox(height: AppSpacing.xl),

              LabeledField(label: 'الاسم الكامل', hint: 'أدخل اسمك', controller: _name),
              const SizedBox(height: AppSpacing.lg),
              LabeledField(
                label: 'البريد الإلكتروني',
                hint: 'example@mail.com',
                controller: _email,
                error: _emailError,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledField(
                label: 'كلمة المرور',
                hint: '••••••••',
                controller: _password,
                obscure: _hidePassword,
                suffix: IconButton(
                  icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: AppColors.body),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text(
                'بإنشائك حسابًا فأنت توافق على الشروط وسياسة الخصوصية واستخدام ملفات الارتباط',
                textAlign: TextAlign.center,
                style: AppText.b2Regular.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(label: 'إنشاء حساب', loading: _loading, onPressed: _submit),
              const SizedBox(height: AppSpacing.xl),
              const OrDivider(),
              const SizedBox(height: AppSpacing.xl),

              const SocialButton(
                  label: 'المتابعة عبر Google',
                  icon: Icons.g_mobiledata,
                  iconColor: Color(0xFFDB4437)),
              const SizedBox(height: AppSpacing.lg),
              const SocialButton(
                  label: 'المتابعة عبر Facebook',
                  icon: Icons.facebook,
                  iconColor: Color(0xFF1877F2)),

              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacementNamed('/login'),
                child: Text.rich(
                  TextSpan(
                    style: AppText.b1Regular,
                    children: [
                      const TextSpan(
                          text: 'لديك حساب؟ ',
                          style: TextStyle(color: AppColors.body)),
                      TextSpan(
                          text: 'سجّل الدخول',
                          style: AppText.b1SemiBold
                              .copyWith(color: AppColors.accent)),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================== تسجيل الدخول
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Text('سجّل الدخول لحسابك',
                  textAlign: TextAlign.center, style: AppText.h3SemiBold),
              const SizedBox(height: AppSpacing.sm),
              Text('سعداء برؤيتك مجددًا.',
                  textAlign: TextAlign.center,
                  style: AppText.b1Regular.copyWith(color: AppColors.body)),
              const SizedBox(height: AppSpacing.xl),

              LabeledField(
                label: 'البريد الإلكتروني',
                hint: 'example@mail.com',
                controller: _email,
                error: _error,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppSpacing.lg),
              LabeledField(
                label: 'كلمة المرور',
                hint: '••••••••',
                controller: _password,
                obscure: _hidePassword,
                suffix: IconButton(
                  icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility,
                      size: 20, color: AppColors.body),
                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/forgot'),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'نسيت كلمة المرور؟ ',
                        style: AppText.b2Regular.copyWith(color: AppColors.body)),
                    TextSpan(
                        text: 'أعد تعيينها',
                        style: AppText.b2Medium.copyWith(color: AppColors.accent)),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              PrimaryButton(label: 'تسجيل الدخول', loading: _loading, onPressed: _submit),
              const SizedBox(height: AppSpacing.xl),
              const OrDivider(),
              const SizedBox(height: AppSpacing.xl),

              const SocialButton(
                  label: 'المتابعة عبر Google',
                  icon: Icons.g_mobiledata,
                  iconColor: Color(0xFFDB4437)),
              const SizedBox(height: AppSpacing.lg),
              const SocialButton(
                  label: 'المتابعة عبر Facebook',
                  icon: Icons.facebook,
                  iconColor: Color(0xFF1877F2)),

              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacementNamed('/signup'),
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'ما عندك حساب؟ ',
                        style: AppText.b1Regular.copyWith(color: AppColors.body)),
                    TextSpan(
                        text: 'انضم',
                        style: AppText.b1SemiBold.copyWith(color: AppColors.accent)),
                  ]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================ نسيت كلمة المرور
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(_email.text.trim());
      if (mounted) {
        Navigator.of(context).pushNamed('/verify', arguments: _email.text.trim());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: '', showBell: false),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('نسيت كلمة المرور',
                  textAlign: TextAlign.center, style: AppText.h3SemiBold),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أدخل بريدك الإلكتروني لإتمام التحقق. سنرسل لك رمزًا من 4 أرقام.',
                textAlign: TextAlign.center,
                style: AppText.b1Regular.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledField(
                label: 'البريد الإلكتروني',
                hint: 'example@mail.com',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              PrimaryButton(label: 'إرسال الرمز', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================== رمز التحقق (4 خانات)
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _controllers = List.generate(4, (_) => TextEditingController());
  final _focusNodes = List.generate(4, (_) => FocusNode());

  String get _code => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final email = ModalRoute.of(context)?.settings.arguments as String? ?? '';

    return Scaffold(
      appBar: const AppHeader(title: '', showBell: false),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('أدخل الرمز المكوّن من 4 أرقام',
                  textAlign: TextAlign.center,
                  style: AppText.h3SemiBold.copyWith(height: 1.4)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'أدخل الرمز الذي وصلك على بريدك ($email).',
                textAlign: TextAlign.center,
                style: AppText.b1Regular.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: AppSpacing.xl),

              // الخانات تُملأ من اليسار لليمين (أرقام)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: List.generate(4, (i) {
                  return Container(
                    width: 64, height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    child: TextField(
                      controller: _controllers[i],
                      focusNode: _focusNodes[i],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: AppText.h3SemiBold,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (v) {
                        if (v.isNotEmpty && i < 3) _focusNodes[i + 1].requestFocus();
                        if (v.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                        setState(() {});
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.lg),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'ما وصلك الرمز؟ ',
                      style: AppText.b1Regular.copyWith(color: AppColors.body)),
                  TextSpan(
                      text: 'إعادة الإرسال',
                      style: AppText.b1SemiBold.copyWith(color: AppColors.accent)),
                ]),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
              PrimaryButton(
                label: 'تحقّق',
                onPressed: _code.length == 4
                    ? () => Navigator.of(context).pushNamed('/reset')
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================== إعادة تعيين كلمة المرور
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _error = 'كلمتا المرور غير متطابقتين');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Supabase.instance.client.auth
          .updateUser(UserAttributes(password: _password.text));
      if (!mounted) return;
      await showSuccessDialog(
        context,
        title: 'تم تغيير كلمة المرور!',
        message: 'تقدر الآن تستخدم كلمة المرور الجديدة لتسجيل الدخول.',
        buttonLabel: 'تسجيل الدخول',
        onDone: () => Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (_) => false),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: '', showBell: false),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center, style: AppText.h3SemiBold),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'عيّن كلمة مرور جديدة لحسابك حتى تتمكن من الدخول واستخدام كل الميزات.',
                textAlign: TextAlign.center,
                style: AppText.b1Regular.copyWith(color: AppColors.body),
              ),
              const SizedBox(height: AppSpacing.xl),

              LabeledField(
                  label: 'كلمة المرور الجديدة',
                  hint: '••••••••',
                  obscure: true,
                  controller: _password),
              const SizedBox(height: AppSpacing.lg),
              LabeledField(
                  label: 'تأكيد كلمة المرور',
                  hint: '••••••••',
                  obscure: true,
                  controller: _confirm,
                  error: _error),

              const SizedBox(height: 32),
              PrimaryButton(label: 'حفظ', loading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
