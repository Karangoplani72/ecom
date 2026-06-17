import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> exportCollection(String collection) async {
  final snapshot =
  await FirebaseFirestore.instance.collection(collection).get();

  final data = snapshot.docs.map((doc) {
    return {
      'id': doc.id,
      ...doc.data(),
    };
  }).toList();

  debugPrint(
    const JsonEncoder.withIndent('  ').convert(data),
  );
}