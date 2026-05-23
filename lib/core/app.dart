import 'package:flutter/material.dart';
import 'package:lamsa/core/theme/app_theme.dart';
import 'package:lamsa/core/theme/theme_controller.dart';
import 'package:lamsa/features/auth/view/decide_role.dart';
import 'package:lamsa/features/auth/view/login_page.dart';
import 'package:lamsa/features/auth/view/register_page.dart';
import 'package:lamsa/features/owner_dashboard/view/AddSalonScreen.dart';
import 'package:lamsa/features/owner_dashboard/view/add_services_screen.dart';
import 'package:lamsa/features/owner_dashboard/view/add_bank_screen.dart';
import 'package:lamsa/features/owner_dashboard/view/owner_profile_page.dart';

final ThemeController themeController = ThemeController();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    themeController.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'منصة لمسة',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            );
          },
          initialRoute: '/decide',
          routes: {
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/decide': (context) => const DecidePage(),
            '/addSalon': (context) => AddSalonScreen(),
            '/ownerProfile': (context) => const OwnerProfileScreen(),
            '/addService': (context) => const AddServicesScreen(),
            '/addBank': (context) => const AddBankScreen(),
          },
        );
      },
    );
  }
}