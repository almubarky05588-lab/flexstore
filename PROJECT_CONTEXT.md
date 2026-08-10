# FlexStore — سياق المشروع (اقرأ هذا أولاً)

> هذا الملف هو ذاكرة المشروع. أي جلسة عمل جديدة تبدأ بقراءته كاملاً.

---

## ١) الهوية والوصول

| العنصر | القيمة |
|---|---|
| المستودع | `almubarky05588-lab/flexstore` |
| Supabase | مشروع `flexstore`، معرّف `tehygeabpxvggvxdbvmp`، منطقة `eu-central-1` |
| معرّف آبل | `com.flexstore.flexstore` — فريق `5V6TC85KRL` |
| لوحة التحكم | `https://rainbow-mousse-19c213.netlify.app` |
| حساب الأدمن | `nabeel@flexstore.app` |
| فِقما | `RZW8bVJ6QO6KYxvAaey6RM` |

**قيد حاسم:** مستودع `glutpass` خاص بعميل آخر — **لا يُلمس إطلاقاً** (يشترك في نفس حسابي Supabase وآبل).

---

## ٢) قواعد العمل المتفق عليها

1. **قبل كتابة أي ملف، اقرأ كل الملفات التي يستدعيها أو تستدعيه.** لا افتراضات.
2. **الملفات كاملة دائماً** — المستخدم يعمل من الجوال ويلصق الملف كاملاً (Select All ← حذف ← لصق).
3. **لا تحذف رموزاً موجودة** عند إعادة كتابة ملف. تحقق من كل `AppColors.*` و`AppText.*` قبل الإرسال.
4. **بعد الحفظ، تحقق فعلياً** عبر `get_file_contents` — لا تفترض أن اللصقة وصلت.
5. **البناءات الوسطية تُلغى** — الأخير فقط هو المعتمد.
6. **لا تتخذ قرارات معمارية بلا موافقة صريحة.** "تم" أو "كمل" ليست موافقة على قرار جديد.
7. **لو فشل البناء**، المستخدم يرفع ملف السجل (zip) للقراءة الفعلية.
8. **الصراحة أولاً** — لا تَعِد بما لم يُبنَ بعد، ووضّح ما هو جاهز وما هو ناقص.
lib/
core/ config.dart, routes.dart, theme.dart
models/ product.dart (Product.fromFullJson)
services/ store_service.dart ← طبقة البيانات الوحيدة
screens/
splash_onboarding.dart ← يقرأ الشعار والاسم من الإعدادات
main_shell.dart ← activeTabNotifier
auth/auth_screens.dart
shop/home_screen.dart ← الرئيسية + البحث + المفضلة
shop/categories_screen.dart ← تبويب الأقسام
shop/product_list_screen.dart ← صفحة قائمة منتجات (من البنرات)
shop/product_details.dart
cart/cart_checkout.dart
orders/orders_screens.dart
account/account_screens.dart
account/new_address_screen.dart
widgets/ common.dart, app_icons.dart, bottom_nav.dart, option_selector.dart
.github/workflows/build.yml ← fastlane match + Xcode 26

**مبدأ معماري:** كل الشاشات تتكلم مع `store_service.dart` فقط. تغيير مصدر البيانات = تغيير هذا الملف وحده.

---

## ٤) خط البناء (مستقر — لا تعبث به)

- Runner: `macos-15`, Xcode 26
- التوقيع: fastlane match، الشهادات في `almubarky05588-lab/ios-certs`
- خطوة حرجة: `Set Development Team` تحقن `DEVELOPMENT_TEAM` في `project.pbxproj`
- الأسرار: `ASC_ISSUER_ID`, `ASC_KEY_ID`, `ASC_KEY_P8`, `TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `MATCH_GIT_TOKEN`, `MATCH_PASSWORD`

---

## ٥) قاعدة البيانات

**جداول المتجر:** store_settings, categories, products, variants, product_images, option_types, option_values, variant_option_values, product_option_types, cart_items, orders, order_items, order_tracking, addresses, favorites, digital_assets, reviews, notifications, faqs, profiles, payment_cards, coupons, integrations, promo_banners, category_banners, category_parents, category_products

**جداول سلة:** salla_stores (التوكنات), salla_events (سجل الأحداث), salla_config (المفاتيح السرية — بلا سياسات قراءة إطلاقاً)

**دوال مهمة:**
- `admin_save_product(payload jsonb)` — حفظ منتج بصوره وفاريانتساته
- `admin_dashboard()` — إحصائيات اللوحة
- `category_products_list(uuid)` — منتجات تصنيف حسب نوعه
- `is_admin()` — التحقق من الصلاحية

**حقول مفتاحية:**
- `categories.shape` = circle | square | text
- `categories.source_type` = normal | best_sellers | manual
- `store_settings.store_mode` = all | single_category
- `store_settings.data_source` = supabase | salla ← **مفتاح الازدواجية**
- `variants.stock_qty` (ليس `stock`)

---

## ٦) حالة ربط سلة

**ما تم:**
- تطبيق خاص في Salla Partners باسم "فلكس ستور" رقم `1101880761`
- Edge Function `salla-webhook` — تستقبل الأحداث وتحفظ التوكن
- Edge Function `salla-api` — تقرأ من API سلة بأمان (التوكن لا يصل التطبيق أبداً)
- متجر تجريبي مربوط `1115717887` بصلاحيات: products.read, categories.read, orders.read, carts.read, customers.read, brands.read, webhooks.read_write
- **تم التحقق فعلياً:** قراءة منتجات حقيقية من سلة (status 200)

**روابط الوسطاء:**
https://tehygeabpxvggvxdbvmp.supabase.co/functions/v1/salla-webhook
https://tehygeabpxvggvxdbvmp.supabase.co/functions/v1/salla-api?resource=products

**الباقي:**
1. تحويل بنية منتجات سلة لبنية التطبيق (الخيارات، النسخ، الصور)
2. طبقة اختيار المصدر في `store_service.dart` حسب `data_source`
3. السلة والشراء — يحتاج ترقية `carts` و`orders` إلى read_write
4. Webhooks للإشعارات

**تنبيه:** التوكن يحمل الصلاحيات وقت إصداره. أي تغيير في الصلاحيات يتطلب إعادة تثبيت التطبيق على المتجر.

---

## ٧) النموذج التجاري المقصود

- **نسخة مستقلة لكل عميل** (وليس تطبيقاً واحداً متعدد المتاجر)
- كل عميل يحتاج **حساب مطوّر خاص به** — قاعدة آبل 4.2.6 تمنع نشر تطبيقات من قالب واحد من حساب واحد
- عميل بلا سلة → `data_source = supabase` (التطبيق كما هو اليوم)
- عميل بسلة → `data_source = salla`
- الإشعارات والبنرات والتصنيفات تبقى في Supabase في الحالتين

---

## ٨) النواقص المعروفة

- [ ] شاشة "بطاقة جديدة" (القاعدة جاهزة: جدول `payment_cards`)
- [ ] صورة `assets/images/onboarding.jpg`
- [ ] أيقونة التطبيق الحقيقية (حالياً افتراضية Flutter)
- [ ] بناء أندرويد
- [ ] الدفع الفعلي للعملاء بلا سلة (الخانات جاهزة في `integrations`، الربط البرمجي لم يتم)
- [ ] القولبة الكاملة (الألوان لا تزال في الكود، ليست في الإعدادات)

---

## ٩) أخطاء وقعت — لا تتكرر

1. **حذف رموز عند إعادة كتابة `theme.dart`** ← فشل بناء. الحل: افحص كل مستخدمي الملف أولاً.
2. **افتراض أن اللصقة وصلت** ← اكتُشف أن ملفين لم يُحفظا. الحل: تحقق دائماً.
3. **`GestureDetector` خارجي يبتلع ضغطة القلب** ← الحل: `behavior: HitTestBehavior.opaque` لكل منطقة مستقلة.
4. **استعلام `categories(name_ar)` بعلاقتين متضاربتين** ← فشل صامت. الحل: اقرأ الأقسام منفصلة واربطها في الكود.
5. **حفظ منتج قبل اكتمال رفع الصور** ← صور مفقودة. الحل: قفل زر الحفظ أثناء الرفع.

---

## ٣) البنية الحالية
