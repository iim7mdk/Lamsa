import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [

          const CircleAvatar(
            radius: 50,
            child: Icon(
              Icons.person_2,
              size: 50,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "حواء",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "user@email.com",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 30),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("تعديل الملف الشخصي"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("حجوزاتي"),
            onTap: () {},
          ),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("تسجيل الخروج"),
            onTap: () {},
          ),
        ],
      ),
    ),
    );
  }
}