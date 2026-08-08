import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// شاشة البداية — الشعار في المنتصف مع أشكال دائرية خلفية.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNext();
  }

  Future<void> _decideNext() async {
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    Navigator.of(context)
        .pushReplacementNamed(session != null ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // أشكال زخرفية كما في التصميم
          Positioned(
            top: 250, right: 25,
            child: _circle(340, AppColors.accent.withValues(alpha: 0.06)),
          ),
          Positioned(
            top: 500, left: -50,
            child: _circle(200, AppColors.accent.withValues(alpha: 0.10)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 134, height: 133,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(Icons.shopping_bag_outlined,
                      size: 68, color: AppColors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('متجري',
                    style: AppText.h3SemiBold.copyWith(fontSize: 28)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// شاشة التعريف — صورة كبيرة، عنوان بثلاثة أسطر (الأوسط برتقالي)، وزر متدرّج.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // الصورة تملأ الشاشة خلف النص
          Positioned(
            top: 147, right: 0, left: 32, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.sheet),
                ),
                image: DecorationImage(
                  image: AssetImage('assets/images/onboarding.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: RichText(
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    text: TextSpan(
                      style: AppText.h3SemiBold.copyWith(
                        fontSize: 34,
                        height: 1.5,
                        color: AppColors.ink,
                      ),
                      children: [
                        const TextSpan(text: 'عبّر عن نفسك\n'),
                        TextSpan(
                          text: 'بأسلوبك\n',
                          style: const TextStyle(color: AppColors.accent),
                        ),
                        const TextSpan(text: 'الخاص'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 22),
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'ابدأ الآن',
                      gradient: true,
                      onPressed: () =>
                          Navigator.of(context).pushReplacementNamed('/signup'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
