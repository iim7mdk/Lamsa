import 'package:flutter/material.dart';
import 'package:lamsa/features/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lamsa/core/model/user_model.dart';
import 'package:lamsa/features/auth/view/login_page.dart';
import 'package:lamsa/features/customer_dashboard/view/pages/my_bookings.dart';
import 'edit_profile_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<UserModel?> getUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data()!);

  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
        
      body: FutureBuilder<UserModel?>(
        future: getUserData(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('لم يتم العثور على بيانات المستخدم'),
            );
          }

          final user = snapshot.data!;

          return Center(
              // padding: const EdgeInsets.all(16),
              child: Column(
                children: [

                  const SizedBox(height: 50),

                  const CircleAvatar(
                    radius: 50,
                    child: Icon(
                      Icons.person_2,
                    size: 50,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 30),

                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text("تعديل الملف الشخصي"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text("حجوزاتي"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyBookingsPage(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text("اعدادات متقدمة"),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
                        ),
                      );
                    },
                  ),

                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text("تسجيل الخروج"),
                    onTap: () async {
                      Navigator.pop(context);

                      await AuthService().signOut();

                      if (!context.mounted) return;

                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/decide',
                            (route) => false,
                      );
                    },
                  ),

                ]
              )
          );
        }
      )

    );
  }
}