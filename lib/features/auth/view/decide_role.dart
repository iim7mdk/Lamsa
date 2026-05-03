import 'package:flutter/material.dart';
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

          if (role == 'owner') {
            final salonId = authService.currentUser!.uid;

            return OwnerNavigationScreen(
              salonId: salonId,
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
