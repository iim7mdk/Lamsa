import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lamsa/features/customer_dashboard/view/pages/profile_page.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/salon_list_page.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/my_bookings.dart';

// عدّلي هذا المسار حسب مكان LoginPage عندك
import 'package:lamsa/features/auth/view/login_page.dart';

class CustomerNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const CustomerNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<CustomerNavigationScreen> createState() =>
      _CustomerNavigationScreenState();
}

class _CustomerNavigationScreenState extends State<CustomerNavigationScreen> {
  late int currentIndex;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    currentIndex = widget.initialIndex;

    pages = const [
      SalonListPage(),
      MyBookingsPage(showAppBar: false),
      ProfilePage(),
    ];
  }

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    if (currentIndex == 2) {
      return AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      );
    }

    return AppBar(
      title: Text(
        currentIndex == 0
            ? 'الصفحة الرئيسية'
            : currentIndex == 1
            ? 'حجوزاتي'
            : 'الملف الشخصي',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: _buildAppBar(),

        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: changePage,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'الصفحة الرئيسية',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'حجوزاتي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined),
              activeIcon: Icon(Icons.person_2),
              label: 'الملف الشخصي',
            ),
          ],
        ),
      ),
    );
  }
}