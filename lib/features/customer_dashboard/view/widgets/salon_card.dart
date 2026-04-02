import 'package:flutter/material.dart';
import 'package:lamsa/features/owner_dashboard/model/salon_model.dart';
import '../pages/salon_details_page.dart';

class SalonCard extends StatelessWidget {
  final SalonModel salon;

  const SalonCard({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    print('Salon Name: ${salon.salonName}');  // طباعة اسم الصالون
    print('Number of services: ${salon.services.length}');  // طباعة عدد الخدمات

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalonDetailsPage(salon: salon),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.salonName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // const SizedBox(height: 8),
                // Text(
                //   salon.description,
                //   style: const TextStyle(fontSize: 14),
                // ),
                const SizedBox(height: 10),
                Text(
                  'عدد الخدمات: ${salon.services.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}