import 'package:flutter/material.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import 'booking_success_page.dart';

class BookingPage extends StatefulWidget {
  final String salonTitle;
  final List<Service> services;

  const BookingPage({
    super.key,
    required this.salonTitle,
    required this.services,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Set<int> selectedServices = {};

  DateTime? selectedDate;

  final List<String> availableTimes = [
    '10:00 ص',
    '11:00 ص',
    '12:00 ص',
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

            ...widget.services.asMap().entries.map((entry) {
              final index = entry.key;
              final service = entry.value;

              return CheckboxListTile(
                value: selectedServices.contains(index),
                title: Text(service.name),
                subtitle: Text('${service.price}ر.س '),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedServices.add(index);
                    } else {
                      selectedServices.remove(index);
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
                        // Text(
                        //   '$totalPriceر.س ',
                        //   style: const TextStyle(
                        //     fontSize: 18,
                        //     fontWeight: FontWeight.bold
                        //   ),
                        // )
                      ],
                    ) ,
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: confirmBooking,
                      child: const Text('تأكيد الحجز')
                  ),
                ),

              ],
            ),
            Text('عدد الخدمات المختارة: ${selectedServices.length}'),

          ],
        ),
      ),
    ),
    );
  }
// int get totalPrice{
//   int total = 0;
//
//   for(var index in selectedServices){
//     total += widget.services[index].price;
//   }
//   return total;
// }

  void confirmBooking(){
    if(selectedServices.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختاري خدمة واحدة على الاقل')),
      );
      return;
    }

    if (selectedDate == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختاري تاريخ الحجز')),
      );
      return;
    }

    if (selectedTime == null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختاري وقت الحجز')),
      );
      return;
    }

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const BookingSuccessPage(),
        )
    );
  }
}
