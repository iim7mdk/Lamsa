import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OwnerBookingsReportPage extends StatefulWidget {
  const OwnerBookingsReportPage({
    super.key,
    required this.salonId,
  });

  final String salonId;

  @override
  State<OwnerBookingsReportPage> createState() =>
      _OwnerBookingsReportPageState();
}

class _OwnerBookingsReportPageState extends State<OwnerBookingsReportPage> {
  String _selectedStatus = 'all';
  DateTime? _selectedDate;
  int? _selectedWeekday;

  Stream<QuerySnapshot<Map<String, dynamic>>> get _bookingsStream {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('salonId', isEqualTo: widget.salonId)
        .snapshots();
  }

  DateTime? _toDate(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final period = date.hour >= 12 ? 'م' : 'ص';
    int hour = date.hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return 'غير محدد';
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending':
        return 'قيد المراجعة';
      case 'accepted':
        return 'مقبول';
      case 'rejected':
        return 'مرفوض';
      case 'unpaid':
        return 'غير مدفوع';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'unpaid':
        return Colors.grey;
      case 'cancelled':
        return Colors.blueGrey;
      default:
        return Colors.black54;
    }
  }

  String _priceText(dynamic value) {
    if (value == null) return '0 ريال';

    final price = double.tryParse(value.toString()) ?? 0;
    final hasDecimal = price % 1 != 0;

    return '${price.toStringAsFixed(hasDecimal ? 2 : 0)} ريال';
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _applyFilters(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    final filtered = docs.where((doc) {
      final data = doc.data();

      final status = data['status']?.toString() ?? '';
      final appointmentAt = _toDate(data['appointmentAt']);

      final matchesStatus =
          _selectedStatus == 'all' || status == _selectedStatus;

      final matchesDate = _selectedDate == null ||
          (appointmentAt != null && _sameDate(appointmentAt, _selectedDate!));

      final matchesDay = _selectedWeekday == null ||
          (appointmentAt != null && appointmentAt.weekday == _selectedWeekday);

      return matchesStatus && matchesDate && matchesDay;
    }).toList();

    filtered.sort((a, b) {
      final aDate = _toDate(a.data()['appointmentAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = _toDate(b.data()['appointmentAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      return bDate.compareTo(aDate);
    });

    return filtered;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      helpText: 'اختاري التاريخ',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _selectedDate = null;
      _selectedWeekday = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عرض الحجوزات'),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh),
              tooltip: 'مسح الفلاتر',
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _bookingsStream,
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
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final allDocs = snapshot.data?.docs ?? [];
            final filteredDocs = _applyFilters(allDocs);

            return Column(
              children: [
                _FiltersSection(
                  selectedStatus: _selectedStatus,
                  selectedDate: _selectedDate,
                  selectedWeekday: _selectedWeekday,
                  formatDate: _formatDate,
                  weekdayName: _weekdayName,
                  onStatusChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                  onDateTap: _pickDate,
                  onClearDate: () {
                    setState(() {
                      _selectedDate = null;
                    });
                  },
                  onWeekdayChanged: (value) {
                    setState(() {
                      _selectedWeekday = value;
                    });
                  },
                  onClearFilters: _clearFilters,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text(
                        'عدد النتائج:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Text('${filteredDocs.length}'),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: filteredDocs.isEmpty
                      ? const _EmptyBookingsView()
                      : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredDocs.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];

                      return _BookingReportCard(
                        bookingId: doc.id,
                        data: doc.data(),
                        toDate: _toDate,
                        formatDate: _formatDate,
                        formatTime: _formatTime,
                        weekdayName: _weekdayName,
                        statusText: _statusText,
                        statusColor: _statusColor,
                        priceText: _priceText,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FiltersSection extends StatelessWidget {
  const _FiltersSection({
    required this.selectedStatus,
    required this.selectedDate,
    required this.selectedWeekday,
    required this.formatDate,
    required this.weekdayName,
    required this.onStatusChanged,
    required this.onDateTap,
    required this.onClearDate,
    required this.onWeekdayChanged,
    required this.onClearFilters,
  });

  final String selectedStatus;
  final DateTime? selectedDate;
  final int? selectedWeekday;

  final String Function(DateTime date) formatDate;
  final String Function(int weekday) weekdayName;

  final ValueChanged<String> onStatusChanged;
  final VoidCallback onDateTap;
  final VoidCallback onClearDate;
  final ValueChanged<int?> onWeekdayChanged;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'فلترة الحجوزات',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(
                    label: 'الكل',
                    value: 'all',
                    selectedValue: selectedStatus,
                    onSelected: onStatusChanged,
                  ),
                  _StatusChip(
                    label: 'قيد المراجعة',
                    value: 'pending',
                    selectedValue: selectedStatus,
                    onSelected: onStatusChanged,
                  ),
                  _StatusChip(
                    label: 'المقبولة',
                    value: 'accepted',
                    selectedValue: selectedStatus,
                    onSelected: onStatusChanged,
                  ),
                  _StatusChip(
                    label: 'المرفوضة',
                    value: 'rejected',
                    selectedValue: selectedStatus,
                    onSelected: onStatusChanged,
                  ),
                  _StatusChip(
                    label: 'غير مدفوعة',
                    value: 'unpaid',
                    selectedValue: selectedStatus,
                    onSelected: onStatusChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDateTap,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      selectedDate == null
                          ? 'اختيار التاريخ'
                          : formatDate(selectedDate!),
                    ),
                  ),
                ),

                if (selectedDate != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onClearDate,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<int?>(
              value: selectedWeekday,
              decoration: InputDecoration(
                labelText: 'فلترة حسب اليوم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('كل الأيام'),
                ),
                ...[
                  DateTime.saturday,
                  DateTime.sunday,
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                ].map(
                      (day) => DropdownMenuItem<int?>(
                    value: day,
                    child: Text(weekdayName(day)),
                  ),
                ),
              ],
              onChanged: onWeekdayChanged,
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.restart_alt),
                label: const Text('مسح الفلاتر'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedValue == value,
        onSelected: (_) {
          onSelected(value);
        },
      ),
    );
  }
}

class _BookingReportCard extends StatelessWidget {
  const _BookingReportCard({
    required this.bookingId,
    required this.data,
    required this.toDate,
    required this.formatDate,
    required this.formatTime,
    required this.weekdayName,
    required this.statusText,
    required this.statusColor,
    required this.priceText,
  });

  final String bookingId;
  final Map<String, dynamic> data;

  final DateTime? Function(dynamic value) toDate;
  final String Function(DateTime date) formatDate;
  final String Function(DateTime date) formatTime;
  final String Function(int weekday) weekdayName;
  final String Function(String status) statusText;
  final Color Function(String status) statusColor;
  final String Function(dynamic value) priceText;

  @override
  Widget build(BuildContext context) {
    final customerName = data['customerName']?.toString() ?? 'غير معروف';
    final customerPhone = data['customerPhone']?.toString() ?? 'غير متوفر';

    final status = data['status']?.toString() ?? 'pending';
    final appointmentAt = toDate(data['appointmentAt']);

    final totalPrice = priceText(data['totalPrice']);
    final finalPrice = priceText(data['finalPrice']);

    final receiptNumber = data['bankReceiptNumber']?.toString() ?? '';

    final services = data['selectedServices'] is List
        ? (data['selectedServices'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink.shade50,
                  child: Icon(
                    Icons.person,
                    color: Colors.pink.shade300,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText(status),
                    style: TextStyle(
                      color: statusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _InfoRow(
              icon: Icons.phone,
              title: 'رقم العميلة',
              value: customerPhone,
            ),

            _InfoRow(
              icon: Icons.calendar_today,
              title: 'التاريخ',
              value: appointmentAt == null ? 'غير محدد' : formatDate(appointmentAt),
            ),

            _InfoRow(
              icon: Icons.today,
              title: 'اليوم',
              value: appointmentAt == null
                  ? 'غير محدد'
                  : weekdayName(appointmentAt.weekday),
            ),

            _InfoRow(
              icon: Icons.access_time,
              title: 'الوقت',
              value: appointmentAt == null ? 'غير محدد' : formatTime(appointmentAt),
            ),

            _InfoRow(
              icon: Icons.payments,
              title: 'السعر',
              value: totalPrice,
            ),

            _InfoRow(
              icon: Icons.discount,
              title: 'بعد الخصم',
              value: finalPrice,
            ),

            if (receiptNumber.isNotEmpty)
              _InfoRow(
                icon: Icons.receipt_long,
                title: 'رقم السند',
                value: receiptNumber,
              ),

            if (services.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'الخدمات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: services.map((service) {
                  return Chip(
                    label: Text(service),
                    backgroundColor: Colors.pink.shade50,
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 8),

            SelectableText(
              'رقم الحجز: $bookingId',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.pink.shade300,
          ),

          const SizedBox(width: 7),

          Text(
            '$title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          Expanded(
            child: Text(value),
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
            SizedBox(height: 12),
            Text(
              'لا توجد حجوزات مطابقة للفلاتر',
              style: TextStyle(
                fontSize: 17,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}