// lib/main.dart
import 'package:flutter/material.dart';
import 'package:mobile2025/Screens/content_screen.dart';
import 'package:mobile2025/Services/audio_player_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AudioPlayerService();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile 2025',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const ContentScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}