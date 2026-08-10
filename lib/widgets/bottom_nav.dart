import 'package:flutter/material.dart';
import '../core/theme.dart';

/// شريط التنقّل السفلي — خمسة عناصر، الترتيب من اليمين:
/// الرئيسية، الأقسام، المفضلة، السلة، حسابي.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  static const _items = [
    (_NavIcon(Icons.home_outlined, Icons.home_rounded), 'الرئيسية'),
    (_NavIcon(Icons.grid_view_outlined, Icons.grid_view_rounded), 'الأقسام'),
    (_NavIcon(Icons.favorite_border, Icons.favorite), 'المفضلة'),
    (_NavIcon(Icons.shopping_cart_outlined, Icons.shopping_cart), 'السلة'),
    (_NavIcon(Icons.person_outline, Icons.person), 'حسابي'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              final (icons, label) = _items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            selected ? icons.filled : icons.outlined,
                            size: 24,
                            color: selected ? AppColors.accent : AppColors.body,
                          ),
                          if (i == 3 && cartCount > 0)
                            Positioned(
                              right: -6,
                              top: -4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.alert,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$cartCount',
                                  style: AppText.b3Medium
                                      .copyWith(color: AppColors.white),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: AppText.b3Medium.copyWith(
                          color: selected ? AppColors.accent : AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavIcon {
  final IconData outlined;
  final IconData filled;
  const _NavIcon(this.outlined, this.filled);
}
