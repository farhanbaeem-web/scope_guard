// lib/main.dart
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseBootstrap.initialize();
  await FirebaseBootstrap.ensureSignedIn();

  runApp(const ScopeGuardApp());
}
