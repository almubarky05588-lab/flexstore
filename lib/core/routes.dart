import 'package:flutter/material.dart';
import '../screens/splash_onboarding.dart';
import '../screens/main_shell.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/shop/home_screen.dart';
import '../screens/shop/product_details.dart';
import '../screens/cart/cart_checkout.dart';
import '../screens/orders/orders_screens.dart';
import '../screens/account/account_screens.dart';

/// خريطة المسارات — كل شاشة في فِقما لها مسار هنا.
final appRoutes = <String, WidgetBuilder>{
  // البداية والتعريف
  '/':            (_) => const SplashScreen(),
  '/onboarding':  (_) => const OnboardingScreen(),

  // المصادقة
  '/signup':      (_) => const SignUpScreen(),
  '/login':       (_) => const LoginScreen(),
  '/forgot':      (_) => const ForgotPasswordScreen(),
  '/verify':      (_) => const VerificationScreen(),
  '/reset':       (_) => const ResetPasswordScreen(),

  // التسوّق
  '/home':        (_) => const MainShell(),
  '/search':      (_) => const SearchScreen(),
  '/saved':       (_) => const SavedItemsScreen(),
  '/product':     (_) => const ProductDetailsScreen(),
  '/reviews':     (_) => const ReviewsScreen(),

  // السلة والشراء
  '/cart':            (_) => const CartScreen(),
  '/checkout':        (_) => const CheckoutScreen(),
  '/addresses':       (_) => const AddressesScreen(),
  '/payment-methods': (_) => const PaymentMethodsScreen(),

  // الطلبات
  '/orders':      (_) => const OrdersScreen(),
  '/track':       (_) => const TrackOrderScreen(),

  // الحساب
  '/account':               (_) => const AccountScreen(),
  '/my-details':            (_) => const MyDetailsScreen(),
  '/notifications':         (_) => const NotificationsScreen(),
  '/notification-settings': (_) => const NotificationSettingsScreen(),
  '/faqs':                  (_) => const FaqsScreen(),
  '/help':                  (_) => const HelpCenterScreen(),
  '/support':               (_) => const SupportChatScreen(),
};
