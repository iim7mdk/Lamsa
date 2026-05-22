import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lamsa/core/app.dart';
import 'package:lamsa/core/services/local_notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await LocalNotificationService.init();

    runApp(const MyApp());
  } catch (e){
    debugPrint("Firebase init error: $e");
    runApp(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('حدث خطأ أثناء تشغيل Firebase'),
          ),
        ),
      ),
    );
  }
}



//✔ قائمة الصالونات
// ✔ صفحة تفاصيل الصالون
// ✔ عرض الخدمات
// ✔ اختيار الخدمات
// ✔ اختيار التاريخ
// ✔ اختيار الوقت
// ✔ حساب السعر
// ✔ تأكيد الحجز