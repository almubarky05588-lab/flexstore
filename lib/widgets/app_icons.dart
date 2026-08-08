import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme.dart';

/// أيقونات التصميم الأصلية المصدّرة من فِقما.
/// تُستخدم بدل أيقونات Material لضمان مطابقة الشكل تمامًا.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;

  const AppIcon(this.name, {super.key, this.size = 24, this.color});

  static Widget bell({double size = 24, Color? color}) =>
      AppIcon('bell', size: size, color: color);
  static Widget heart({double size = 24, Color? color}) =>
      AppIcon('heart', size: size, color: color);
  static Widget star({double size = 18.852, Color? color}) =>
      AppIcon('star', size: size, color: color);
  static Widget bag({double size = 24, Color? color}) =>
      AppIcon('bag', size: size, color: color);
  static Widget arrow({double size = 24, Color? color}) =>
      AppIcon('arrow', size: size, color: color);
  static Widget filter({double size = 24, Color? color}) =>
      AppIcon('filter', size: size, color: color);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

/// سهم الرجوع — في التصميم يتجه لليمين (لأن الواجهة RTL).
/// يرجع للصفحة السابقة إن وُجدت، وإلا يرجع للرئيسية بدل أن يعلّق بلا فائدة.
class BackArrow extends StatelessWidget {
  final VoidCallback? onTap;
  const BackArrow({super.key, this.onTap});

  void _defaultBack(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushNamedAndRemoveUntil('/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _defaultBack(context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 24,
        height: 24,
        // الأصل يشير لليسار، فنعكسه أفقيًا ليتّجه يمينًا كما في فِقما
        child: Transform.flip(
          flipX: true,
          child: AppIcon.arrow(color: AppColors.ink),
        ),
      ),
    );
  }
}
