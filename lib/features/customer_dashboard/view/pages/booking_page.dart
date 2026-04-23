import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/controller/booking_controller.dart';
import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';
import 'package:lamsa/features/customer_dashboard/service/booking_service.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import 'booking_success_page.dart';

class BookingPage extends StatefulWidget {
  final String salonId;
  final String salonTitle;
  final List<Service> services;

  final BookingController _controller = BookingController(BookingService());

  const BookingPage({
    super.key,
    required this.salonId,
    required this.salonTitle,
    required this.services,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Set<String> selectedServiceIds = {};

  DateTime? selectedDate;

  final List<String> availableTimes = [
    '10:00 ص',
    '11:00 ص',
    '12:00 م',
    '1:00 م',
    '2:00 م',
    '3:00 م',
    '4:00 م',
    '5:00 م',
  ];

  String? selectedTime;

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('الحجز - ${widget.salonTitle}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'أهلاً بك في ${widget.salonTitle}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'اختاري الخدمات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            ...widget.services.map((service) {
              return CheckboxListTile(
                value: selectedServiceIds.contains(service.id),
                title: Text(service.name),
                subtitle: Text('${service.price} ر.س'),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedServiceIds.add(service.id);
                    } else {
                      selectedServiceIds.remove(service.id);
                    }
                  });
                },
              );
            }),

            const SizedBox(height: 20),
            Column(
              children: [
                const SizedBox(height: 20),

                const Text(
                  'اختاري التاريخ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: pickDate,
                    child: Text(
                      selectedDate == null
                          ? 'اختاري يوم الحجز'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'اختاري وقت',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'اختاري وقتًا متاحًا',
                  ),
                  items: availableTimes.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedTime = value;
                    });
                  },
                ),

                const SizedBox(height: 12),
                Text(
                  selectedTime == null
                      ? 'لم يتم اختيار وقت بعد'
                      : 'الوقت المختار: $selectedTime',
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الإجمالي',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$totalPrice ر.س',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ) ,
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(

                      onPressed: () async {
                        final error = await _controller.confirmBooking(
                          customerId: 'currentUserId',
                          salonId: widget.salonId,
                          serviceIds: selectedServiceIds.toList(),
                          totalPrice: totalPrice,
                          selectedDate: selectedDate,
                          selectedTime: selectedTime,
                        );

                        if (!context.mounted) return;

                        if (error != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BookingSuccessPage(),
                          ),
                        );
                      },

                      child: const Text('تأكيد الحجز')
                  ),
                ),

              ],
            ),
            Text('عدد الخدمات المختارة: ${selectedServiceIds.length}'),

          ],
        ),
      ),
    ),
    );
  }
  double get totalPrice {
    double total = 0;

    for (final service in widget.services) {
      if (selectedServiceIds.contains(service.id)) {
        total += service.price;
      }
    }

    return total;
  }

  // Future<void> confirmBooking() async {
  //   if (selectedServiceIds.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('اختاري خدمة واحدة على الأقل')),
  //     );
  //     return;
  //   }
  //
  //   if (selectedDate == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('اختاري تاريخ الحجز')),
  //     );
  //     return;
  //   }
  //
  //   if (selectedTime == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('اختاري وقت الحجز')),
  //     );
  //     return;
  //   }
  //
  //   final appointmentAt = _combineDateAndTime(selectedDate!, selectedTime!);
  //
  //   final booking = BookingModel(
  //     id: '',
  //     customerId: 'currentUserId',
  //     salonId: widget.salonId,
  //     serviceIds: selectedServiceIds.toList(),
  //     totalPrice: totalPrice,
  //     bankReceiptNumber: null,
  //     appointmentAt: appointmentAt,
  //     status: 'pending',
  //     createdAt: DateTime.now(),
  //   );
  //
  //   await FirebaseFirestore.instance
  //       .collection('bookings')
  //       .add(booking.toMap());
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => const BookingSuccessPage(),
  //     ),
  //   );
  // }

  // DateTime _combineDateAndTime(DateTime date, String time) {
  //   final parts = time.split(' ');
  //   final clock = parts[0];
  //   final period = parts[1];
  //
  //   final hourMinute = clock.split(':');
  //   int hour = int.parse(hourMinute[0]);
  //   final minute = int.parse(hourMinute[1]);
  //
  //   if (period == 'م' && hour != 12) {
  //     hour += 12;
  //   } else if (period == 'ص' && hour == 12) {
  //     hour = 0;
  //   }
  //
  //   return DateTime(
  //     date.year,
  //     date.month,
  //     date.day,
  //     hour,
  //     minute,
  //   );
  // }
}
