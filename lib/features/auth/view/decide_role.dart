import 'package:flutter/material.dart';
import 'package:lamsa/features/admin_dashboard/view/admin_navigation_screen.dart';
import 'package:lamsa/features/auth/view/login_page.dart';
import '../auth_service.dart';
import '../../customer_dashboard/view/pages/customer_navigation_screen.dart';
import '../../owner_dashboard/view/owner_navigation_screen.dart';


class DecidePage extends StatelessWidget {
  const DecidePage({super.key});



  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return FutureBuilder<String?>(
      future: authService.getUserRole(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (authService.currentUser == null) {
            return const LoginPage();
          }

          final role = snapshot.data;

          if (role == 'admin') {
            return const AdminNavigationScreen();
          } else if (role == 'owner') {

            return FutureBuilder<String?>(
              future: authService.getOwnerStatus(),
              builder: (context, statusSnapshot) {
                if (statusSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                final ownerStatus = statusSnapshot.data;

                if (ownerStatus == 'approved') {
                  final salonId = authService.currentUser!.uid;

                  return OwnerNavigationScreen(
                    salonId: salonId,
                  );
                }

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('حساب قيد المراجعة'),
                    centerTitle: true,
                    automaticallyImplyLeading: false,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'تسجيل الخروج',
                        onPressed: () async {
                          await authService.signOut();

                          if (!context.mounted) return;

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                                (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.hourglass_top,
                            size: 70,
                            color: Colors.orange,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'حسابك كمالك قيد المراجعة.\nلا يمكنك استقبال الحجوزات حتى يتم التحقق من الصالون.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.logout),
                              label: const Text('تسجيل الخروج'),
                              onPressed: () async {
                                await authService.signOut();

                                if (!context.mounted) return;

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginPage()),
                                      (route) => false,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (role == 'customer') {
            return const CustomerNavigationScreen();
          } else {
            Future.microtask(() {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            });
            return const Scaffold(
              body: Center(child: Text('Role not found. Redirecting to login page...')),
            );
          }
        },
    );
  }
}
