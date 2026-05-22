import 'package:flutter/material.dart';
import 'package:lamsa/features/customer_dashboard/controller/booking_controller.dart';
import 'package:lamsa/features/customer_dashboard/service/booking_service.dart';
import 'package:lamsa/features/owner_dashboard/model/service_model.dart';
import 'payment_page.dart';

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

  Future<void> pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
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
              _HeaderCard(
                salonTitle: widget.salonTitle,
                selectedCount: selectedServices.length,
                totalPrice: totalPrice,
              ),

              const SizedBox(height: 20),

              _SectionTitle(
                title: 'اختاري الخدمات',
                icon: Icons.spa_outlined,
              ),

              const SizedBox(height: 12),

              if (widget.services.isEmpty)
                const _EmptyServicesCard()
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

              _SectionTitle(
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

              _SectionTitle(
                title: 'اختاري الوقت',
                icon: Icons.access_time,
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedTime,
                decoration: const InputDecoration(
                  hintText: 'اختاري وقتًا متاحًا',
                  prefixIcon: Icon(Icons.schedule),
                ),
                items: availableTimes.map((time) {
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
                      _SummaryRow(
                        title: 'عدد الخدمات',
                        value: '${selectedServices.length}',
                      ),
                      const Divider(),
                      _SummaryRow(
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
}

class _HeaderCard extends StatelessWidget {
  final String salonTitle;
  final int selectedCount;
  final double totalPrice;

  const _HeaderCard({
    required this.salonTitle,
    required this.selectedCount,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.event_available,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salonTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الخدمات المختارة: $selectedCount | الإجمالي: $totalPrice ر.س',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isBold;

  const _SummaryRow({
    required this.title,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: isBold ? 17 : 15,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _EmptyServicesCard extends StatelessWidget {
  const _EmptyServicesCard();

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