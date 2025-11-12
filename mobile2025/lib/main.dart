// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Services/database_helper.dart';
import 'package:mobile2025/Screens/content_screen.dart';
import 'package:mobile2025/Services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser la base de données
  try {
    await DatabaseHelper().database; // Crée la DB
  } catch (e) {
    debugPrint('Erreur d\'initialisation de la base de données: $e');
    // Continuer quand même, la DB sera créée à la première utilisation
  }

  await NotificationService().init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const ContentScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}