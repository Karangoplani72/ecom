import 'package:ecom/app.dart';
import 'package:ecom/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  // Ensure framework is initialized[cite: 5]
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with your generated options[cite: 5]
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EnterpriseMarketplaceApp(),
    ),
  );
}
