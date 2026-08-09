import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'shop/home_screen.dart';
import 'cart/cart_checkout.dart';
import 'account/account_screens.dart';

/// إشعار عام تستمع له التبويبات لإعادة تحميل بياناتها عند تفعيلها.
/// القيمة تحمل رقم التبويب النشط حاليًا.
final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);

/// الهيكل الرئيسي — يحتضن التبويبات الخمسة ويحافظ على حالة كل تبويب.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // الترتيب يطابق شريط التنقل: الرئيسية، بحث، المحفوظات، السلة، حسابي
  final _screens = const [
    HomeScreen(),
    SearchScreen(),
    SavedItemsScreen(),
    CartScreen(),
    AccountScreen(),
  ];

  void _onTab(int i) {
    setState(() => _index = i);
    activeTabNotifier.value = i; // تبليغ التبويب الجديد ليعيد تحميل بياناته
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _onTab,
      ),
    );
  }
}
