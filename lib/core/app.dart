import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/view/decide_role.dart';
import 'package:lamsa/features/auth/view/login_page.dart';
import 'package:lamsa/features/auth/view/register_page.dart';
import 'package:lamsa/features/owner_dashboard/view/AddSalonScreen.dart';
import 'package:lamsa/features/owner_dashboard/view/add_services_screen.dart';
import 'package:lamsa/features/owner_dashboard/view/add_bank_screen.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_profile_page.dart';

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
      initialRoute: '/decide',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/decide': (context) => const DecidePage(),
        '/addSalon': (context) => AddSalonScreen(),
        '/ownerProfile': (context) => const OwnerProfileScreen(),  // إضافة هذا المسار
        '/addService': (context) => const AddServicesScreen(),
        '/addBank': (context) => const AddBankScreen(),
      },
    );
  }
}