import 'package:flutter/material.dart';

class EmptyServicesCard extends StatelessWidget {
  const EmptyServicesCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: Text('لا توجد خدمات متاحة حالياً'),
        ),
      ),
    );
  }
}