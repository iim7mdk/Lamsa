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

                return const Scaffold(
                  body: Center(
                    child: Text(
                      'حسابك كمالك قيد المراجعة.\nلا يمكنك استقبال الحجوزات حتى يتم التحقق من الصالون.',
                      textAlign: TextAlign.center,
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
