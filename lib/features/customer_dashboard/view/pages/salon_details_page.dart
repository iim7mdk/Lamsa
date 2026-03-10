import 'package:flutter/material.dart';
import '../../model/salon_model.dart';

import 'booking_page.dart';

class SalonDetailsPage extends StatelessWidget {
  final SalonModel salon;

  const SalonDetailsPage({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(salon.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                salon.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                salon.description,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'الخدمات المتاحة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...salon.services.map(
                    (service) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.content_cut),
                    title: Text(service.name),
                    trailing: Text(
                      '${service.price} ر.س',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                  onPressed: (){
                    //صفحة الحجز
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingPage(
                          salonTitle: salon.title,
                          services: salon.services,
                        ),
                      ),
                    );
                  },

                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'احجزي الان',
                      style: TextStyle(fontSize: 16),
                    ),
                  )

              ),
            ],
          ),
        ),
      ),
    );
  }

}
