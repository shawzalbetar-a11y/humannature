import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:human_nature_admin/services/notification_service.dart';
import 'package:human_nature_admin/theme/app_theme.dart';
import 'package:human_nature_admin/views/dashboard_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('tr_TR', null);
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB70yDf4WMVB5opibIAcSErWAhOlVU8EWM",
      authDomain: "humannature-291de.firebaseapp.com",
      projectId: "humannature-291de",
      storageBucket: "humannature-291de.firebasestorage.app",
      messagingSenderId: "282805018834",
      appId: "1:282805018834:web:06dc77e7c1cc9074d1cd0b",
    ),
  );

  // Initialize FCM & subscribe to admin topic for order notifications
  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUMAN NATURE Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DashboardView(),
    );
  }
}
