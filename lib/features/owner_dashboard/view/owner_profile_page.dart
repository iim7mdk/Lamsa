import 'package:flutter/material.dart';
import 'widgets/profle_info_row.dart';

class OwnerProfileScreen extends StatelessWidget {
  const OwnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    // const String ownerName = "فاطمة";
    const String salonName = "صالون لمسات";
    const String phone = "+967 777 123 456";
    const String email = "owner@lamsa.com";
    const String location = "حضرموت - سيئون";
    const String workingHours = "9:00 صباحاً - 9:00 مساءً";

    return Scaffold(

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    ProfileInfoRow(
                      icon: Icons.person_2,
                      title: "اسم الصالون",
                      value: salonName,
                    ),

                    const Divider(),

                    ProfileInfoRow(
                      icon: Icons.phone,
                      title: "رقم الجوال",
                      value: phone,
                    ),

                    const Divider(),

                    ProfileInfoRow(
                      icon: Icons.email,
                      title: "الإيميل",
                      value: email,
                    ),

                    const Divider(),

                    ProfileInfoRow(
                      icon: Icons.location_on,
                      title: "الموقع",
                      value: location,
                    ),

                    const Divider(),

                    ProfileInfoRow(
                      icon: Icons.access_time,
                      title: "ساعات العمل",
                      value: workingHours,
                    ),

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

