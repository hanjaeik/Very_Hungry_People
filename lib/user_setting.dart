import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSettings with ChangeNotifier {
  bool _isPrivate = false;
  String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  bool get isPrivate => _isPrivate;

  UserSettings() {
    _loadPrivacySetting();
  }

  Future<void> _loadPrivacySetting() async {
    if (currentUserEmail == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('userSettings').doc(currentUserEmail).get();
    if (userDoc.exists) {
      _isPrivate = userDoc['isPrivate'] ?? false;
    }
    notifyListeners();
  }

  Future<void> togglePrivacy(bool isPrivate) async {
    _isPrivate = isPrivate;
    if (currentUserEmail == null) return;

    await FirebaseFirestore.instance.collection('userSettings').doc(currentUserEmail).set({
      'isPrivate': isPrivate,
    });

    notifyListeners();
  }
}
