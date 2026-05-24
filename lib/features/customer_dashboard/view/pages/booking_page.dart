import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/controller/booking_controller.dart';
import 'package:lamsa/features/customer_dashboard/service/booking_service.dart';
import 'package:lamsa/features/customer_dashboard/view/widgets/booking_summary_row.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import 'payment_page.dart';
import '../widgets/booking_header_card.dart';
import '../widgets/booking_section_title.dart';
import '../widgets/empty_services_card.dart';

class BookingPage extends StatefulWidget {
  final String salonId;
  final String salonTitle;
  final List<Service> services;

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
  final BookingController _controller = BookingController(BookingService());

  final List<Service> selectedServices = [];
  DateTime? selectedDate;
  String? selectedTime;
  List<String> bookedSlots = [];
  bool isLoadingBookedSlots = false;

  final List<String> availableTimes = [
    '9:00 ص',
    '10:00 ص',
    '11:00 ص',
    '12:00 م',
    '4:00 م',
    '5:00 م',
    '6:00 م',
    '7:00 م',
  ];

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
        selectedTime = null;
      });

      await loadBookedSlots(pickedDate);
    }
  }

  double get totalPrice => _controller.calculateTotalPrice(selectedServices);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('الحجز'),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              try {
                final bookingId =
                await _controller.createBookingAndValidate(
                  salonId: widget.salonId,
                  selectedServices:
                  selectedServices.map((s) => s.name).toList(),
                  totalPrice: totalPrice,
                  selectedDate: selectedDate,
                  selectedTime: selectedTime,
                );

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(
                      bookingId: bookingId,
                    ),
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                totalPrice == 0 ? 'اختاري خدمة أولاً' : 'المتابعة للدفع - $totalPrice ر.س',
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookingHeaderCard(
                salonTitle: widget.salonTitle,
                selectedCount: selectedServices.length,
                totalPrice: totalPrice,
              ),

              const SizedBox(height: 20),

              BookingSectionTitle(
                title: 'اختاري الخدمات',
                icon: Icons.spa_outlined,
              ),

              const SizedBox(height: 12),

              if (widget.services.isEmpty)
                const EmptyServicesCard()
              else
                ...widget.services.map(
                      (service) {
                    final isSelected = selectedServices.contains(service);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: CheckboxListTile(
                        value: isSelected,
                        activeColor: theme.colorScheme.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text('${service.price} ر.س'),
                        secondary: CircleAvatar(
                          backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.12),
                          child: Icon(
                            Icons.content_cut,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              selectedServices.add(service);
                            } else {
                              selectedServices.remove(service);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),

              BookingSectionTitle(
                title: 'اختاري التاريخ',
                icon: Icons.calendar_month_outlined,
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: pickDate,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    selectedDate == null
                        ? 'اختاري يوم الحجز'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              BookingSectionTitle(
                title: 'اختاري الوقت',
                icon: Icons.access_time,
              ),

              const SizedBox(height: 12),

              if (isLoadingBookedSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: selectedTime,
                  decoration: const InputDecoration(
                    hintText: 'اختاري وقتًا متاحًا',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                  items: _controller.getAvailableTimes(
                    availableTimes: availableTimes,
                    selectedDate: selectedDate,
                    bookedSlots: bookedSlots,
                  ).map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Text(time),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedTime = value);
                  },
                ),

              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      BookingSummaryRow(
                        title: 'عدد الخدمات',
                        value: '${selectedServices.length}',
                      ),
                      const Divider(),
                      BookingSummaryRow(
                        title: 'الإجمالي',
                        value: '$totalPrice ر.س',
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  // String _slotKey(DateTime date, String time) {
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
  //   final appointmentAt = DateTime(
  //     date.year,
  //     date.month,
  //     date.day,
  //     hour,
  //     minute,
  //   );
  //
  //   final year = appointmentAt.year.toString();
  //   final month = appointmentAt.month.toString().padLeft(2, '0');
  //   final day = appointmentAt.day.toString().padLeft(2, '0');
  //   final hourText = appointmentAt.hour.toString().padLeft(2, '0');
  //   final minuteText = appointmentAt.minute.toString().padLeft(2, '0');
  //
  //   return '${year}${month}${day}_${hourText}${minuteText}';
  // }

  Future<void> loadBookedSlots(DateTime date) async {
    setState(() {
      isLoadingBookedSlots = true;
      selectedTime = null;
    });

    try {
      final slots = await _controller.getBookedSlots(
        salonId: widget.salonId,
        selectedDate: date,
      );

      if (!mounted) return;

      setState(() {
        bookedSlots = slots;
        isLoadingBookedSlots = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        bookedSlots = [];
        isLoadingBookedSlots = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

}


