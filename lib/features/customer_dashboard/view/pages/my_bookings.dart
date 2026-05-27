import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lamsa/features/customer_dashboard/controller/booking_controller.dart';
import 'package:lamsa/features/customer_dashboard/service/booking_service.dart';

class MyBookingsPage extends StatefulWidget {
  final bool showAppBar;

  const MyBookingsPage({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}


class _MyBookingsPageState extends State<MyBookingsPage> {

  @override
  void initState() {
    super.initState();

    _bookingController.deleteExpiredUnpaidBookings();
  }


  final BookingController _bookingController =
  BookingController(BookingService());

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: widget.showAppBar
            ? AppBar(
          title: const Text('حجوزاتي'),
          centerTitle: true,
        )
            : null,
        body: user == null
            ? const Center(
          child: Text(
            'يجب تسجيل الدخول لعرض الحجوزات',
            style: TextStyle(fontSize: 16),
          ),
        )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _bookingController.getMyBookings(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'حدث خطأ أثناء تحميل الحجوزات:\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                    ),
                  ),
                ),
              );
            }

            final docs = [...(snapshot.data?.docs ?? [])];

            docs.sort((a, b) {
              final aDate = _bookingController.toDate(a.data()['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);
              final bDate = _bookingController.toDate(b.data()['createdAt']) ??
                  DateTime.fromMillisecondsSinceEpoch(0);

              return bDate.compareTo(aDate);
            });

            if (docs.isEmpty) {
              return const _EmptyBookingsView();
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final doc = docs[index];

                return _BookingCard(
                  bookingId: doc.id,
                  data: doc.data(),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> data;

  const _BookingCard({
    required this.bookingId,
    required this.data,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  late Future<BookingExtraData> _extraDataFuture;
  bool isExpanded = false;

  final BookingController _bookingController =
  BookingController(BookingService());

  @override
  void initState() {
    super.initState();
    _extraDataFuture = _bookingController.loadExtraData(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    final appointmentAt =
    _bookingController.toDate(widget.data['appointmentAt']);

    final createdAt = _bookingController.toDate(widget.data['createdAt']);
    final totalPrice =
    _bookingController.formatPrice(widget.data['totalPrice']);

    final finalPrice =
    _bookingController.formatPrice(widget.data['finalPrice']);

    final bookingStatus = widget.data['status']?.toString() ?? 'pending';
    final bankReceiptNumber =
        widget.data['bankReceiptNumber']?.toString() ?? '';
    final selectedBankName =
        widget.data['selectedBankName']?.toString() ?? '';

    return FutureBuilder<BookingExtraData>(
      future: _extraDataFuture,
      builder: (context, snapshot) {
        final extraData = snapshot.data;
        final salonName = extraData?.salonName ?? 'جاري تحميل الصالون...';

        final servicesText = snapshot.connectionState == ConnectionState.waiting
            ? 'جاري تحميل الخدمات...'
            : (extraData?.serviceNames.isNotEmpty == true
            ? extraData!.serviceNames.join('، ')
            : 'لا توجد خدمات');

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.12),
                          child: Icon(
                            Icons.spa,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            salonName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    _InfoRow(
                      title: 'التاريخ',
                      value: appointmentAt == null
                          ? 'غير محدد'
                          : _bookingController.formatDate(appointmentAt),
                    ),

                    _InfoRow(
                      title: 'الوقت',
                      value: appointmentAt == null
                          ? 'غير محدد'
                          : _bookingController.formatTime(appointmentAt),
                    ),

                    _InfoRow(
                      title: 'الحالة',
                      value:
                      _bookingController.getBookingStatusText(bookingStatus),
                      color: _bookingController.getStatusColor(bookingStatus),
                    ),

                    if (isExpanded) ...[
                      const Divider(height: 22),

                      _InfoRow(
                        title: 'الخدمات',
                        value: servicesText,
                      ),

                      _InfoRow(
                        title: 'الإجمالي',
                        value: totalPrice,
                      ),

                      _InfoRow(
                        title: 'الإجمالي بعد الخصم',
                        value: finalPrice,
                      ),

                      if (bankReceiptNumber.isNotEmpty)
                        _InfoRow(
                          title: 'رقم السند',
                          value: bankReceiptNumber,
                        ),

                      if (selectedBankName.isNotEmpty)
                        _InfoRow(
                          title: 'البنك',
                          value: selectedBankName,
                        ),

                      if (createdAt != null)
                        _InfoRow(
                          title: 'تاريخ إنشاء الحجز',
                          value: _bookingController.formatDate(createdAt),
                        ),

                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          'رقم الحجز: ${widget.bookingId}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    Center(
                      child: Text(
                        isExpanded
                            ? 'اضغطي لإخفاء التفاصيل'
                            : 'اضغطي لعرض التفاصيل',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: color != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookingsView extends StatelessWidget {
  const _EmptyBookingsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 70,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد حجوزات',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
