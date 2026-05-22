import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> saveUserToken() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return;

  final token = await FirebaseMessaging.instance.getToken();

  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .update({
    'fcmToken': token,
  });
}