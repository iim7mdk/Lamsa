import 'package:flutter/material.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_dashboard_screen.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_navigation_screen.dart';
import 'features/customer_dashboard/view/pages/salon_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منصة لمسة',
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      home: const MyHomePage(title: 'منصة لمسة'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      // body: const SalonListPage(), // for customer
      // body: const OwnerDashboardScreen(), //for dashboard screen
      body: const OwnerNavigationScreen(), // to navigate
    );
  }
}

// 172.20.10.2


//✔ قائمة الصالونات
// ✔ صفحة تفاصيل الصالون
// ✔ عرض الخدمات
// ✔ اختيار الخدمات
// ✔ اختيار التاريخ
// ✔ اختيار الوقت
// ✔ حساب السعر
// ✔ تأكيد الحجز