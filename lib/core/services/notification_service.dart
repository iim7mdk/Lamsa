import 'dart:convert';

import 'package:http/http.dart' as http;

class NotificationService {

  static Future<void> sendNotification({
    required String token,
    required String title,
    required String body,
  }) async {

    const serverKey = 'rNCEyBa9UGV435iqqGugicAI-KBMolc7JM2Ns4soeMI';

    await http.post(
      Uri.parse(
        'https://fcm.googleapis.com/fcm/send',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'priority': 'high',
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
      }),
    );
  }
}