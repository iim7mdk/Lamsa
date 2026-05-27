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

  final TextEditingController couponController = TextEditingController();

  String? appliedCouponCode;
  double discountAmount = 0;
  double finalPrice = 0;
  bool isApplyingCoupon = false;

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
                final bookingId = await _controller.createBookingAndValidate(
                  salonId: widget.salonId,
                  selectedServices: selectedServices.map((s) => s.name).toList(),
                  totalPrice: totalPrice,
                  selectedDate: selectedDate,
                  selectedTime: selectedTime,
                  couponCode: appliedCouponCode,
                  discountAmount: discountAmount,
                  finalPrice: payablePrice,
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
                totalPrice == 0 ? 'اختاري خدمة أولاً' : 'المتابعة للدفع - $payablePrice ر.س',
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

                            appliedCouponCode = null;
                            discountAmount = 0;
                            finalPrice = 0;
                            couponController.clear();
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'كود الخصم',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: couponController,
                              decoration: const InputDecoration(
                                hintText: 'مثال: LAMSA20',
                                prefixIcon: Icon(Icons.discount_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: isApplyingCoupon
                                ? null
                                : () async {
                              try {
                                setState(() => isApplyingCoupon = true);

                                final coupon = await _controller.applyCoupon(
                                  code: couponController.text,
                                  salonId: widget.salonId,
                                  totalPrice: totalPrice,
                                );

                                setState(() {
                                  appliedCouponCode = coupon.code;
                                  discountAmount = coupon.discountAmount;
                                  finalPrice = coupon.finalPrice;
                                  isApplyingCoupon = false;
                                });

                                if (!context.mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم تطبيق الخصم: ${coupon.discountAmount.toStringAsFixed(2)} ر.س',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  appliedCouponCode = null;
                                  discountAmount = 0;
                                  finalPrice = 0;
                                  isApplyingCoupon = false;
                                });

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
                            child: Text(isApplyingCoupon ? '...' : 'تطبيق'),
                          ),
                        ],
                      ),
                      if (appliedCouponCode != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          'تم تطبيق الكوبون: $appliedCouponCode',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
                        title: 'السعر قبل الخصم',
                        value: '$totalPrice ر.س',
                      ),
                      const Divider(),
                      BookingSummaryRow(
                        title: 'الخصم',
                        value: '- $discountAmount ر.س',
                      ),
                      const Divider(),
                      BookingSummaryRow(
                        title: 'المبلغ النهائي',
                        value: '$payablePrice ر.س',
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

  double get payablePrice {
    final price = totalPrice - discountAmount;
    return price < 0 ? 0 : price;
  }

  @override
  void dispose() {
    couponController.dispose();
    super.dispose();
  }

}


