import 'package:ecom/app.dart';
import 'package:ecom/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final container = ProviderContainer();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const EcomApp(),
    ),
  );
}
