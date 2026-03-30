import 'package:flutter/material.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
            child: Column(
                children: [

                  const SizedBox(height: 439),

                  Text(
                    'No bookings',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                      // fontWeight: FontWeight.bold,
                    ),
                  ),


                ]
            )
        )
    );
  }
}

//