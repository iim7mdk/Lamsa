import 'package:lamsa/features/customer_dashboard/model/booking_model.dart';
import 'package:lamsa/features/customer_dashboard/service/booking_service.dart';

class BookingController {
  final BookingService _service;

  BookingController(this._service);

  Future<String> confirmBooking({
    required String customerId,
    required String customerName,
    required int customerPhone,
    required String salonId,
    required List<String> selectedServices,
    required double totalPrice,
    required DateTime? selectedDate,
    required String? selectedTime,
  }) async {
    if (selectedServices.isEmpty) {
      throw Exception('اختاري خدمة واحدة على الأقل');
    }

    if (selectedDate == null) {
      throw Exception('اختاري تاريخ الحجز');
    }

    if (selectedTime == null) {
      throw Exception('اختاري وقت الحجز');
    }

    final appointmentAt = _combineDateAndTime(selectedDate, selectedTime);

    final booking = BookingModel(
      id: '',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      salonId: salonId,
      selectedServices: selectedServices,
      totalPrice: totalPrice,
      bankReceiptNumber: null,
      appointmentAt: appointmentAt,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    final bookingId = await _service.createBooking(booking);

    return bookingId;
  }

  DateTime _combineDateAndTime(DateTime date, String time) {
    final parts = time.split(' ');
    final clock = parts[0];
    final period = parts[1];

    final hourMinute = clock.split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);

    if (period == 'م' && hour != 12) {
      hour += 12;
    } else if (period == 'ص' && hour == 12) {
      hour = 0;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
  }
}