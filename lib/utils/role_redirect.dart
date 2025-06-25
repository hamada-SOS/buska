import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/admin/AdminHomeScreen.dart';
import '../screens/driver/DriverHomeScreen.dart';
import '../screens/student/StudentHomeScreen.dart';


Future<void> redirectBasedOnRole(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return;

  final doc = await FirebaseFirestore.instance.collection('user').doc(uid).get();

  if (!doc.exists) return;

  final role = doc.data()?['role'];

  if (role == 'admin') {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
  } else if (role == 'driver') {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const DriverHomeScreen()));
  } else {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
  }
}
