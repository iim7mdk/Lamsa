import 'package:flutter/material.dart';

class OwnerDashboardScreen  extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  final List<Map<String, String>> bookings = const [
    {
      "name": "حواء ادم",
      "date": "2026-03-15",
      "time": "10:00 AM",
      "receipt": "BNK123456",
      "phone": "789899899"
    },
    {
      "name": "سارة محمد",
      "date": "2026-03-16",
      "time": "12:30 PM",
      "receipt": "BNK789654",
      "phone": "780000009"
    },
    {
      "name": "امل خالد",
      "date": "2026-03-17",
      "time": "04:00 PM",
      "receipt": "BNK456987",
      "phone": "789899119"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Owner Dashboard"),
      // ),
      body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'مرحبًا أيها المالك 👋',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade100,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    'عدد طلبات الحجز: ${bookings.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                    child: ListView.builder(
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          final booking = bookings[index];


                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "الاسم: ${booking["name"]}",
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),

                                  const SizedBox(height: 6),

                                  Text("التاريخ: ${booking["date"]}"),
                                  Text("الوقت: ${booking["time"]}"),

                                  const SizedBox(height: 6),

                                  Text(
                                    "رقم الإيصال البنكي: ${booking["receipt"]}",
                                    style: const TextStyle(color: Colors.blue),
                                  ),

                                  const SizedBox(height: 12),

                                  Text(
                                    "رقم الجوال: ${booking["phone"]}",
                                    style: const TextStyle(color: Colors.blue),
                                  ),

                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [

                                      ElevatedButton(
                                          onPressed: (){
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                  content: Text("تم قبول الحجز"),
                                              )
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('قبول',
                                              style: TextStyle(
                                                color: Colors.white,
                                              )
                                          )
                                      ),

                                      const SizedBox(width: 10),

                                      ElevatedButton(
                                          onPressed: (){
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text("تم رفض الحجز"),
                                                  )
                                              );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                              'رفض',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          )
                                      )
                                    ],
                                  )
                                ],
                              ),

                            )
                          );
                        }
                    )
                )


              ],
          ),
      )
    );
  }
}