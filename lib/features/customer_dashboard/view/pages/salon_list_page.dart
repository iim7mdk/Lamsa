import 'package:flutter/material.dart';
import '../widgets/salon_card.dart';

import '../../model/salon_model.dart';
import '../../model/service_model.dart';

class SalonListPage extends StatelessWidget {
  const SalonListPage({super.key});

  static const List<SalonModel> salons = [
    SalonModel(
      title: 'صالون لمسات',
      description: 'لخدمات المكياج والتنظيف',
      services: [
        ServiceModel(
            name: 'مكياج',
            price: 90
        ),
        ServiceModel(
            name: 'تسريحة شعر',
            price: 150
        ),
        ServiceModel(
            name: 'قص شعر',
            price: 150
        ),
      ],
    ),
    SalonModel(
      title: 'صالون مكة',
      description: 'لخدمات القص',
      services: [
        ServiceModel(
            name: 'تنظيف البشرة',
            price: 10
        ),
        ServiceModel(
            name: 'تسريحة شعر',
            price: 50
        ),
      ],
    ),
    SalonModel(
      title: 'صالون المدينة',
      description: 'لخدمات المكياج والتنظيف',
      services: [
        ServiceModel(
            name: 'تنظيف البشرة',
            price: 30
        ),
        ServiceModel(
            name: 'تسريحة شعر',
            price: 70
        ),
      ],
      // services: [
      //   'تنظيف البشرة - 30 ر.س',
      //   'تسريحة شعر - 70 ر.س',
      // ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: salons.length,
      itemBuilder: (context, index) {
        return SalonCard(salon: salons[index]);
      },
    );
  }
}