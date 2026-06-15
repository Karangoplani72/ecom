import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';
import 'package:ecom/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseFirestore.instance
      .collection('test')
      .doc('startup')
      .set({
    'message': 'Firebase Connected',
    'createdAt': DateTime.now().toIso8601String(),
  });

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EnterpriseMarketplaceApp(),
    ),
  );
}