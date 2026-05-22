import 'package:flutter/material.dart';
import 'screens/salon_approval_screen.dart';
import 'screens/admin_users_screen.dart';
import 'screens/admin_salons_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamsa/features/auth/view/login_page.dart';

class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int currentIndex = 0;

  final pages = const [
    SalonApprovalScreen(),
    AdminUsersScreen(),
    AdminSalonsScreen(),
  ];

  final titles = const [
    'اعتماد الصوالين',
    'جميع المستخدمين',
    'جميع الصوالين',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[currentIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginPage(),
                  ),
                      (route) => false,
                );
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            setState(() => currentIndex = index);
          },
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.verified_outlined),
              activeIcon: Icon(Icons.verified),
              label: 'الاعتماد',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'المستخدمين',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'الصوالين',
            ),
          ],
        ),
      ),
    );
  }
}