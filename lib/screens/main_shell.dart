import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'shop/home_screen.dart';
import 'cart/cart_checkout.dart';
import 'account/account_screens.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
